param 
(
    $SourceFolder = ".", 
    $DestinationFolder = $(throw "-DestinationFolder is required."),
    [ValidateSet("Move","Copy")]
    [System.String] $Operation = "Copy",
    [System.String] $SourceDateTimeSelector = "IMG_(.*)\.jpg",
    [System.String] $SourceDateTimeFormat = "yyyyMMdd_HHmmss",
    [System.String] $DestinationDateTimeFormat = "yyyyMMdd-HHmmss"
)

# if destination does not exist
if(-not (Test-Path -Path $DestinationFolder)) {
    New-Item -Path $DestinationFolder -ItemType Directory | Out-Null;
}

# declare last file for saving copy state
$lastFile = $null;

# get files in folder ordered by name ascending
$files = Get-ChildItem -Path $SourceFolder | Sort-Object -Property FullName;

# for each file in the folder
foreach($file in $files) {

    # if the file name matches the selector
    if($file.Name -match $SourceDateTimeSelector) {

        # retrieve the date string selected by the expression
        $dateString = $Matches[1];

        # parse into a datetime object
        $dateValue = [DateTime]::ParseExact($dateString, $SourceDateTimeFormat, $null);

        # build newFilePath with year
        $newFilePath = $DestinationFolder + $dateValue.Year.ToString();

        if(-not (Test-Path -Path $newFilePath))
        {
            New-Item -Path $newFilePath -ItemType Directory | Out-Null;
        }

        # build newFilePath with month
        $newFilePath = $newFilePath + "\" + $dateValue.Month.ToString("00");

        if(-not (Test-Path -Path $newFilePath)) {
            New-Item -Path $newFilePath -ItemType Directory | Out-Null;
        }

        # create a new filename based off the datetime object
        $newFilePath = $newFilePath + "\" + $dateValue.ToString([string] $DestinationDateTimeFormat) + $file.Extension;

        # TODO: what if the file already exists

        #copy file
        Write-Host $newFilePath;
        Copy-Item -Path $file.FullName -Destination $newFilePath;    
        
        $lastFile = $file;
    }
}

# if we are copying save last file
if($Operation -eq "Copy") {
    # TODO: save copy state
}