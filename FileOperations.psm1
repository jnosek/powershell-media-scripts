
class MediaOperationSettings {
    [string] $DuplicateFolder;

    MediaOperationSettings([string] $duplicateFolder = $null) {
        $this.DuplicateFolder = $duplicateFolder;
    }
}

class MediaFile {
    [System.IO.FileSystemInfo] $CurrentFile;
    [string] $Name;
    [string] $NewPath;
    [string] $NewFullName;
    [DateTime] $DateTime;
    
    MediaFile([System.IO.FileSystemInfo] $currentFile, [DateTime] $dateTime, $mediaExpression) {
        $dateTimeFileNameFormat = "yyyyMMdd-HHmmss";

        $this.CurrentFile = $currentFile;

        # special case, for Android Moving Photos, want to keep .MP.jpg extension
        if($mediaExpression.Name -eq "AndroidCurrentMovingPhoto" -or $mediaExpression.Name -eq "AndroidLegacyMovingPhoto") {
            $this.Name = $dateTime.ToString($dateTimeFileNameFormat) + ".MP" + $currentFile.Extension;
        } else {
            $this.Name = $dateTime.ToString($dateTimeFileNameFormat) + $currentFile.Extension;
        }
        
        $this.NewPath = $dateTime.Year.ToString() + "\" + $dateTime.Month.ToString("00") + "\";
        $this.NewFullName = $this.NewPath + $this.Name;
        $this.DateTime = $dateTime;
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
                Move-Item -Path $this.CurrentFile.FullName -Destination $settings.DuplicateFolder;
            }

            return $true
        }

        return $false;
    }

    [void] Copy($basePath, [MediaOperationSettings] $settings) {
        $newFullPath = $basePath + "\" + $this.NewPath; 

        $this.CheckDestination($newFullPath);

        if(-not $this.IsDuplicateFound($newFullPath, $settings))
        {
            Write-Host("{0} <-> {1}" -f $this.CurrentFile.Name, $this.NewFullName);

            Copy-Item -Path $this.CurrentFile.FullName -Destination $this.NewFullName;
        }
    }

    [void] Move($basePath, [MediaOperationSettings] $settings) {
        $newFullPath = $basePath + "\" + $this.NewPath; 

        $this.CheckDestination($newFullPath);

        if(-not $this.IsDuplicateFound($newFullPath, $settings))
        {
            Write-Host("{0} -> {1}" -f $this.CurrentFile.Name, $this.NewFullName);
            
            Move-Item -Path $this.CurrentFile.FullName -Destination $this.NewFullName;
        }
    }
}

function New-MediaOperationSettings([string] $duplicateFolder)
{
    return [MediaOperationSettings]::new($duplicateFolder);
}

function New-MediaFile([System.IO.FileSystemInfo] $currentFile, [DateTime] $dateTime)
{
    return [MediaFile]::new($currentFile, $dateTime);
}

Export-ModuleMember -Function New-MediaFile
Export-ModuleMember -Function New-MediaOperationSettings