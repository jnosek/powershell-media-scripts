[CmdletBinding(SupportsShouldProcess)]
param 
(
    $SourceFolder = ".", 
    $DestinationFolder = $null,
    [ValidateSet("All","Default","Android","iOS")]
    $MediaGroup = $(throw "-MediaGroup is required."),
    [ValidateSet("All","Photo","MovingPhoto", "Screenshot","Video")]
    $MediaType = $(throw "-MediaType is required."),
    # "Move" will rename the file and move it to the Destination Folder
    # "Copy" will rename the file in the Source Folder and Copy it with the new name to the Destination Folder
    # "Rename will rename the file in the Source Folder and not apply any changes to the Destination Folder"
    [ValidateSet("Move","Copy","Rename")]
    [string] $Operation = "Copy",
    [string] $DuplicateFolder = $null
 )

Import-Module .\PlatformExpressions.psm1 -Scope Local
Import-Module .\FileOperations.psm1 -Scope Local

# validate parameters

# Move or Copy requires Destination
if(($Operation -eq "Move" -or $Operation -eq "Copy") -and $null -eq $DestinationFolder) {
    throw "-DestinationFolder is required for $Operation"
}

$operationSettings = New-MediaOperationSettings

# set duplicate folder if value is set
if($null -ne $DuplicateFolder) {
    $operationSettings.DuplicateFolder = $DuplicateFolder;
}

# get expressions
$defaultExpressions = Get-DefaultExpressions;
$searchExpressions = switch($MediaGroup){
    "Android" { Get-AndroidExpressions }
    "iOS" { Get-iOSExpressions }
    default { @() }
};

function processFile([System.IO.FileSystemInfo] $file) 
{
    # if file matches default
    foreach($expression in $defaultExpressions)
    {
        if($file.Name -match $expression.Expression) {

            # check to see how to process already processed files

            break;
        }
    }

    # check to see if file matches a search expression
    foreach($expression in $searchExpressions) {
        if($file.Name -match $expression.Expression) {
            [DateTime] $dateValue = New-Object DateTime @(
                $Matches["year"],
                $Matches["month"],
                $Matches["date"],
                $Matches["hour"],
                $Matches["minute"],
                $Matches["second"]);

                $newFile = New-MediaFile $file $dateValue

                $newFile.PerformOperation($Operation, $DestinationFolder, $operationSettings);

            break;
        }
    }

    # else the file is not a match

}

# get files in folder ordered by name ascending
$files = @(Get-ChildItem -Path $SourceFolder -File);

# process each file in source
foreach($file in $files) {
    processFile $file;
}