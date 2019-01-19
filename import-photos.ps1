param 
(
    $SourceFolder = ".", 
    $DestinationFolder = $(throw "-DestinationFolder is required."),
    # "Move" will rename the file and move it to the destination
    # "Copy" will rename the file in the Source Folder and Copy it with the new name to the destination
    [ValidateSet("Move","Copy")]
    [System.String] $Operation = "Copy",
    [System.String] $SourceDateTimeSelector = "IMG_(.*)\.jpg",
    [System.String] $SourceDateTimeFormat = "yyyyMMdd_HHmmss",
    [System.String] $DestinationDateTimeFormat = "yyyyMMdd-HHmmss"
)

$failedFolder = $SourceFolder + "\Failed";

# if failed folder does not exist, create it
if(-not (Test-Path -Path $failedFolder)) {
    New-Item -Path $failedFolder -ItemType Directory | Out-Null;
}

# if destination does not exist, create it
if(-not (Test-Path -Path $DestinationFolder)) {
    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null;
}

# get files in folder ordered by name ascending
$files = Get-ChildItem -Path $SourceFolder -File | Sort-Object -Property FullName;

# for each file in the folder
foreach($file in $files) {

    # if the file name matches the selector
    if($file.Name -match $SourceDateTimeSelector) {

        # retrieve the date string selected by the expression
        $dateString = $Matches[1];

        # parse into a datetime object
        $dateValue = [DateTime]::ParseExact($dateString, $SourceDateTimeFormat, $null);

        # build newFilePath with year and month
        $newFilePath = $DestinationFolder + $dateValue.Year.ToString() + "\" + $dateValue.Month.ToString("00");

        # if directory does not exist create it
        if(-not (Test-Path -Path $newFilePath)) {
            New-Item -Path $newFilePath -ItemType Directory | Out-Null;
        }

        # create a new filename based off the datetime object
        $newFileName =  $dateValue.ToString([string] $DestinationDateTimeFormat) + $file.Extension;
        $newFilePath = $newFilePath + "\" + $newFileName;

        # TODO: what if the file already exists

        # copy file
        if($Operation -eq "Copy") {
            # write transaction output
            Write-Host("{0} <-> {1}" -f $file.Name, $newFilePath);

            # rename current file
            $file =Rename-Item -Path $file.FullName -NewName $newFileName -PassThru;
            
            Copy-Item -Path $file.FullName -Destination $newFilePath;    
        }
        # move file
        elseif($Operation -eq "Move") {
            # write transaction output
            Write-Host("{0} -> {1}" -f $file.Name, $newFilePath);

            Move-Item -Path $file.FullName -Destination $newFilePath; 
        }
        # unknown operation value
        else {
            throw ("Unknown Operation Value: {0}" -f $Operation);
        }
    }
    # else, move files that do not match to the failed folder
    else {
        # write transaction output
        Write-Host("! {0}" -f $file.Name);

        Move-Item -Path $file.FullName -Destination $failedFolder;
    }
}