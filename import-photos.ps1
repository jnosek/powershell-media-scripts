param 
(
    $SourceFolder = ".", 
    $DestinationFolder = $(throw "-DestinationFolder is required."),
    # "Move" will rename the file and move it to the destination
    # "Copy" will rename the file in the Source Folder and Copy it with the new name to the destination
    [ValidateSet("Move","Copy")]
    [System.String] $Operation = "Copy",
    [System.String] $SourceDateTimeSelector = "^IMG_([0-9]{8}_[0-9]{6})\.jpg$",
    [System.String] $SourceDateTimeFormat = "yyyyMMdd_HHmmss"
)


$destinationDateTimeFormat = "yyyyMMdd-HHmmss";
$destinationRegExFormat = "^[0-9]{8}-[0-9]{6}(-[0-9]*)?\.jpg$";

$failedFolder = $SourceFolder + "\Failed";

function fileFailure($failedFile)
{
     # write transaction output
     Write-Host("! {0}" -f $failedFile.Name);

     Move-Item -Path $failedFile.FullName -Destination $failedFolder;
}

# if failed folder does not exist, create it
if(-not (Test-Path -Path $failedFolder)) {
    New-Item -Path $failedFolder -ItemType Directory | Out-Null;
}

# if destination does not exist, create it
if(-not (Test-Path -Path $DestinationFolder)) {
    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null;
}

# get files in folder ordered by name ascending
$files = @(Get-ChildItem -Path $SourceFolder -File;

# for each file in the folder
foreach($file in $files) {

    # if the file name matches the selector
    if($file.Name -match $SourceDateTimeSelector) {

        # retrieve the date string selected by the expression
        $dateString = $Matches[1];

        [DateTime] $dateValue = New-Object DateTime;
        
        # if we can parse the datetime
        if([DateTime]::TryParseExact(
            $dateString, 
            $SourceDateTimeFormat, 
            [System.Globalization.CultureInfo]::InvariantCulture, 
            [System.Globalization.DateTimeStyles]::None,
            [ref] $dateValue))
        {
            # build newFilePath with year and month
            $newFilePath = $DestinationFolder + $dateValue.Year.ToString() + "\" + $dateValue.Month.ToString("00");

            # if directory does not exist create it
            if(-not (Test-Path -Path $newFilePath)) {
                New-Item -Path $newFilePath -ItemType Directory | Out-Null;
            }

            # create a new filename based off the datetime object
            $newFileBaseName = $dateValue.ToString([string] $destinationDateTimeFormat);
            $newFileName = $newFileBaseName + $file.Extension;
            $newFileFullName = $newFilePath + "\" + $newFileName;

            # if the file already exists
            if(Test-Path -Path $newFileFullName)
            {
                $matchFileRegex = "^" + $newFileBaseName + "(.*)\.jpg$";
                # find count of files that starts the same
                $matchFiles = @(Get-ChildItem -Path $newFilePath -File | Where-Object { $_.Name -match $matchFileRegex });
                
                # set fileName to - count + 1
                $newFileBaseName = $newFileBaseName + "-" + ($matchFiles.Length + 1);
                $newFileName = $newFileBaseName + $file.Extension;
                $newFileFullName = $newFilePath + "\" + $newFileName;
            }

            # copy file
            if($Operation -eq "Copy") {
                # write transaction output
                Write-Host("{0} <-> {1}" -f $file.Name, $newFileFullName);

                # rename current file
                $file = Rename-Item -Path $file.FullName -NewName $newFileName -PassThru;
                
                Copy-Item -Path $file.FullName -Destination $newFilePath;    
            }
            # move file
            elseif($Operation -eq "Move") {
                # write transaction output
                Write-Host("{0} -> {1}" -f $file.Name, $newFileFullName);

                Move-Item -Path $file.FullName -Destination $newFileFullName; 
            }
            # unknown operation value
            else {
                throw ("Unknown Operation Value: {0}" -f $Operation);
            }
        }      
    }
    # else, if the filename matches our destination format
    elseif($file.Name -match $destinationRegExFormat) {
        # skip
    }
    # else, move files that do not match to the failed folder
    else {
        fileFailure $file;
    }
}