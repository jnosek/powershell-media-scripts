param 
(
    $SourceFolder = ".", 
    $DestinationFolder = $(throw "-DestinationFolder is required."),
    # "Move" will rename the file and move it to the destination
    # "Copy" will rename the file in the Source Folder and Copy it with the new name to the destination
    [ValidateSet("Move","Copy")]
    [System.String] $Operation = "Copy"
)

class Source {
    [string] $Folder;
    [string] $FileTypeSelector;
    [string] $DateTimeRegex;
    [string] $DateTimeFormat;

    Source($folder, $fileType, $dateTimeRegex, $dateTimeFormat){
        $this.Folder = $folder;
        $this.FileTypeSelector = $fileType;
        $this.DateTimeRegex = $dateTimeRegex;
        $this.DateTimeFormat = $dateTimeFormat;
    }
}

class NewFile {
    [string] $BaseName;
    [string] $Name;
    [string] $Path;

    NewFile($baseName, $path) {
        $this.BaseName = $baseName;
        $this.Path = $path;
    }

    [string] FullPath() {
        return $this.Path + "\" + $this.Name;
    }

    [void] SetNameWithExtension([string] $ext) {
        $this.Name = $this.BaseName + $ext;
    }
}

$androidImageSource = [Source]::new(
    $SourceFolder,
    "*.jpg",
    # select files like:
    # IMG_########_######.jpg
    # IMG_########_######_#.jpg
    "^IMG_([0-9]{8}_[0-9]{6})(?:_[0-9]*)?\.jpg$",
    "yyyyMMdd_HHmmss");

$androidVideoSource = [Source]::new(
    $SourceFolder,
    "*.mp4",
    # select files like:
    # IMG_########_######.jpg
    # IMG_########_######_#.jpg
    "^VID_([0-9]{8}_[0-9]{6})(?:_[0-9]*)?\.mp4$",
    "yyyyMMdd_HHmmss");

$destination = [PSCustomObject]@{
    Folder = $DestinationFolder;
    DateTimeFormat = "yyyyMMdd-HHmmss";
    RegExFormat = "^[0-9]{8}-[0-9]{6}(-[0-9]*)?\.jpg$";
}

$failedFolder = $source.Folder + "\Failed";

function fileFailure($failedFile)
{
     # write transaction output
     Write-Host("! {0}" -f $failedFile.Name);

     Move-Item -Path $failedFile.FullName -Destination $failedFolder;
}

function processSource([Source] $source) {
    # get files in folder ordered by name ascending
    $files = @(Get-ChildItem -Path $source.Folder -File -Filter $source.FileTypeSelector);

    # for each file in the folder
    foreach($currentFile in $files) {

        # if the file name matches the selector
        if($currentFile.Name -match $source.DateTimeRegex) {

            # retrieve the date string selected by the expression
            $dateString = $Matches[1];

            [DateTime] $dateValue = New-Object DateTime;
            
            # if we can parse the datetime
            if([DateTime]::TryParseExact(
                $dateString, 
                $source.DateTimeFormat, 
                [System.Globalization.CultureInfo]::InvariantCulture, 
                [System.Globalization.DateTimeStyles]::None,
                [ref] $dateValue))
            {
                $newFile = [NewFile]::new(
                    # create a new basename off the datetime object
                    $dateValue.ToString([string] $destination.DateTimeFormat),
                    # build newFilePath with year and month
                    $destination.Folder + $dateValue.Year.ToString() + "\" + $dateValue.Month.ToString("00")
                );

                # set file extension
                $newFile.SetNameWithExtension($currentFile.Extension); 

                # if directory does not exist create it
                if(-not (Test-Path -Path $newFile.Path)) {
                    New-Item -Path $newFile.Path -ItemType Directory | Out-Null;
                }

                # if the file already exists
                if(Test-Path -Path $newFile.FullPath())
                {
                    $matchFileRegex = "^" + $newFile.BaseName + "(.*)\.jpg$";
                    # find count of files that starts the same
                    $matchFiles = @(Get-ChildItem -Path $newFile.Path -File | Where-Object { $_.Name -match $matchFileRegex });
                    
                    # set fileName to - count + 1
                    $newFile.BaseName = $newFile.BaseName + "-" + ($matchFiles.Length + 1);
                    $newFile.SetNameWithExtension($currentFile.Extension);
                }

                # copy file
                if($Operation -eq "Copy") {
                    # write transaction output
                    Write-Host("{0} <-> {1}" -f $currentFile.Name, $newFile.FullPath());

                    # rename current file
                    $currentFile = Rename-Item -Path $currentFile.FullName -NewName $newFile.Name -PassThru;
                    
                    Copy-Item -Path $currentFile.FullName -Destination $newFile.Path;    
                }
                # move file
                elseif($Operation -eq "Move") {
                    # write transaction output
                    Write-Host("{0} -> {1}" -f $currentFile.Name, $newFile.FullPath());

                    Move-Item -Path $currentFile.FullName -Destination $newFile.FullPath(); 
                }
                # unknown operation value
                else {
                    throw ("Unknown Operation Value: {0}" -f $Operation);
                }
            }      
        }
        # else, if the filename matches our destination format
        elseif($currentFile.Name -match $destination.RegExFormat) {
            # skip
        }
        # else, move files that do not match to the failed folder
        else {
            fileFailure $currentFile;
        }
    }
}

# if failed folder does not exist, create it
if(-not (Test-Path -Path $failedFolder)) {
    New-Item -Path $failedFolder -ItemType Directory | Out-Null;
}

# if destination does not exist, create it
if(-not (Test-Path -Path $destination.Folder)) {
    New-Item -Path $destination.Folder -ItemType Directory | Out-Null;
}

processSource($androidImageSource);

processSource($androidVideoSource);