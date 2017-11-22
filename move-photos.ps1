param 
(
    $SourceFolder = $(throw "-SourceFolder is required."), 
    $DestinationFolder = $(throw "-DestinationFolder is required."),
    [ValidateSet("Move","UseDateModified","Skip")]
    [System.String]$NoDatePolicy = "Move"
)

# dependencies
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

# Constants
$fileExtensions = @("*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.png")
$ExifTagCode_DateTimeOriginal = 0x9003

# Helper Functions
function PSUsing
{
    param
    (
        [IDisposable] $disposable,
        [ScriptBlock] $scriptBlock
    )
 
    try
    {
        & $scriptBlock
    }
    finally
    {
        if ($disposable -ne $null)
        {
            $disposable.Dispose()
        }
    }
}

function Get-ExifProperty
{
    param
    (
        [string] $ImagePath,
        [int] $ExifTagCode
    )
 
    try 
    {
        PSUsing ($fs = [System.IO.File]::OpenRead($ImagePath)) `
        {
            PSUsing ($image = [System.Drawing.Image]::FromStream($fs, $false, $false)) `
            {
                if (-not $image.PropertyIdList.Contains($ExifTagCode))
                {
                    return $null
                }
 
                $propertyItem = $image.GetPropertyItem($ExifTagCode)
                $valueBytes = $propertyItem.Value
                $value = [System.Text.Encoding]::ASCII.GetString($valueBytes) -replace "`0$"
                return $value
            }
        }
    }
    catch
    {
        return $null
    }
}

function Get-DateTaken
{
    param
    (
        [string] $ImagePath
    )
 
    $str = Get-ExifProperty -ImagePath $ImagePath -ExifTagCode $ExifTagCode_DateTimeOriginal
 
    if ($str -eq $null)
    {
        return $null
    }
 
    $dateTime = [DateTime]::MinValue
    if ([DateTime]::TryParseExact($str, "yyyy:MM:dd HH:mm:ss", $null, [System.Globalization.DateTimeStyles]::None, [ref] $dateTime))
    {
        return $dateTime
    }
 
    return $null
}

# clean up parameters
if($DestinationFolder.EndsWith("\") -eq $false)
{
    $DestinationFolder += "\";
}

# setup folders
$DestinationFolder = Get-Item -Path $DestinationFolder
$SourceFolder = Get-Item -Path $SourceFolder

# setup no-date folder
$noDateFolder = $DestinationFolder.FullName + "no-date";

if((Test-Path $noDateFolder) -eq $false)
{
    New-Item -Path $noDateFolder -ItemType Directory | Out-Null
}

# get and process files
$files = Get-ChildItem -Path $SourceFolder -Include $fileExtensions -Recurse

if($files.Count -eq 0)
{
    Write-Host "No files to process"
    Exit 0
}

ForEach($file in $files)
{
    $dateTaken = Get-DateTaken $file

    # if null, check what user instructed to do
    if($dateTaken -eq $null)
    {
        if($NoDatePolicy -eq "Move")
        {
            # TODO: handle similarly named files
            Write-Host("! {0} -> no-date\{1}" -f $file.FullName.SubString($SourceFolder.FullName.Length), $file.Name)
            Move-Item -Path $file -Destination $noDateFolder

            Continue
        }
        elseif($NoDatePolicy -eq "UseDateModified")
        {
            $dateTaken = $file.LastWriteTime
        }
        #else it is Skip, or something invalid
        else
        {
            Write-Host("! {0} -> skipped" -f $file.FullName.SubString($SourceFolder.FullName.Length))
            Continue
        }
    }

    # determine new destination and file name
    
    $newYearMonthFolder = $dateTaken.ToString("yyyy-MM") + "\"
    $newFolder = $DestinationFolder.FullName + $newYearMonthFolder

    $newFilenameBase = $dateTaken.ToString("yyyyMMdd-HHmmss")
    $newFilename = $newFilenameBase + $file.Extension
    $newFilePath = $newFolder + $newFilename

    # TODO: check if the source and destination folders are the same and
    # check if the current file name starts like the new file name, if so skip


    # if folder does not exist, create it
    if((Test-Path $newFolder) -eq $false)
    {
        New-Item -Path $newFolder -ItemType Directory | Out-Null
    }
         
    # if a simlar file already exists
    if(Test-Path $newFilePath)
    {
        $fileCount = (Get-ChildItem -Path $newFolder -Filter ($newFilenameBase + "*")).Count

        $newFilenameBase = $dateTaken.ToString("yyyyMMdd-HHmmss") + "-" + $fileCount
        $newFilename = $newFilenameBase + $file.Extension
        $newFilePath = $newFolder + $newFilename
    }

    # move the file
    Write-Host("{0} -> {1}{2}" -f $file.FullName.SubString($SourceFolder.FullName.Length), $newYearMonthFolder, $newFilename)
    Move-Item -Path $file -Destination $newFilePath
}