
class MediaOperationSettings {
    [string] $DuplicateFolder;

    MediaOperationSettings([string] $duplicateFolder = $null) {
        $this.DuplicateFolder = $duplicateFolder;
    }
}

class MediaFile {
    [string] $SourceFileFullName;
    [string] $DestinationFolderName;
    [string] $DestinationFileName;
    
    MediaFile([System.IO.FileSystemInfo] $sourceFile, [DateTime] $dateTime, $mediaExpression) {
        $dateTimeFileNameFormat = "yyyyMMdd-HHmmss";

        $this.SourceFileFullName = $sourceFile.FullName;
        
        # set destination datetime folder structure
        $this.DestinationFolderName = "\" + $dateTime.Year.ToString() + "\" + $dateTime.Month.ToString("00") + "\";

        # handle default (already processed files) without changing file name (incase of MP or other designations)
        if($mediaExpression.Name -eq "Default") {
            $this.DestinationFileName = $this.DestinationFolderName + $sourceFile.Name;
        }
        # special case, for Android Moving Photos, want to keep .MP.jpg extension
        elseif($mediaExpression.Name -eq "AndroidCurrentMovingPhoto" -or $mediaExpression.Name -eq "AndroidLegacyMovingPhoto") {
            $this.DestinationFileName =  $this.DestinationFolderName + $dateTime.ToString($dateTimeFileNameFormat) + ".MP" + $sourceFile.Extension;
        } 
        else {
            $this.DestinationFileName =  $this.DestinationFolderName + $dateTime.ToString($dateTimeFileNameFormat) + $sourceFile.Extension;
        }
    }

    [void] PerformOperation($operation, $basePath, [MediaOperationSettings] $settings) {
        switch($operation)
        {
            "Move" { $this.Move($basePath, $settings) }
            "Copy" { $this.Copy($basePath, $settings) }
        }
    }

    [void] CheckDestination($path) {
        # if directory does not exist create it
        if(-not (Test-Path -Path $path)) {
            New-Item -Path $path -ItemType Directory | Out-Null;
        }
    }

    [bool] IsDuplicateFound([string] $path, [MediaOperationSettings] $settings) {
        if(Test-Path -Path $path){
            if($null -ne $settings.DuplicateFolder) {
                CheckDestination($settings.DuplicateFolder);
                Move-Item -Path $this.SourceFileFullName -Destination $settings.DuplicateFolder;
            }

            return $true
        }

        return $false;
    }

    [void] Copy($basePath, [MediaOperationSettings] $settings) {
        $destinationFileFullName = $basePath + $this.DestinationFolderName;

        $this.CheckDestination($destinationFileFullName);

        $destinationFileFullName = $basePath + $this.DestinationFileName;

        if(-not $this.IsDuplicateFound($destinationFileFullName, $settings))
        {
            Write-Host "$($this.SourceFileFullName) <-> $destinationFileFullName";

            Copy-Item -Path $this.SourceFileFullName -Destination $destinationFileFullName;
        }
    }

    [void] Move($basePath, [MediaOperationSettings] $settings) {
        $destinationFileFullName = $basePath + "\" + $this.DestinationFolderName;

        $this.CheckDestination($destinationFileFullName);

        $destinationFileFullName = $destinationFileFullName + $this.DestinationFileName;

        if(-not $this.IsDuplicateFound($destinationFileFullName, $settings))
        {
            Write-Host "$($this.SourceFileFullName)  -> $destinationFileFullName";
            
            Move-Item -Path $this.SourceFileFullName -Destination $destinationFileFullName;
        }
    }
}

function New-MediaOperationSettings([string] $duplicateFolder)
{
    return [MediaOperationSettings]::new($duplicateFolder);
}

function New-MediaFile([System.IO.FileSystemInfo] $currentFile, [DateTime] $dateTime, $mediaExpression)
{
    return [MediaFile]::new($currentFile, $dateTime, $mediaExpression);
}