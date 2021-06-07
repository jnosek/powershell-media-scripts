

class MediaFile {
    [System.IO.FileSystemInfo] $CurrentFile;
    [string] $Name;
    [string] $NewPath;
    [string] $NewFullName;
    [DateTime] $DateTime;
    
    MediaFile([System.IO.FileSystemInfo] $currentFile, [DateTime] $dateTime) {
        $dateTimeFileNameFormat = "yyyyMMdd-HHmmss";

        $this.CurrentFile = $currentFile;
        $this.Name = $dateTime.ToString($dateTimeFileNameFormat) + $currentFile.Extension;
        $this.NewPath = $dateTime.Year.ToString() + "\" + $dateTime.Month.ToString("00") + "\";
        $this.NewFullName = $this.NewPath + $this.Name;
        $this.DateTime = $dateTime;
    }

    [void] PerformOperation($operation, $basePath) {
        switch($operation)
        {
            "Move" { $this.Move($basePath) }
            "Copy" { $this.Copy($basePath) }
        }
    }

    [void] CheckDestination($path) {
        if($PSCmdlet.ShouldProcess($this.CurrentFile.Name)) {
            # if directory does not exist create it
            if(-not (Test-Path -Path $path)) {
                New-Item -Path $path -ItemType Directory | Out-Null;
            }
        }
    }

    [void] Copy($basePath) {
        $newFullPath = $basePath + "\" + $this.NewPath; 

        $this.CheckDestination($newFullPath);

        Write-Host("{0} <-> {1}" -f $this.CurrentFile.Name, $this.NewFullName);

        if($PSCmdlet.ShouldProcess($this.CurrentFile.Name)) {
            Copy-Item -Path $this.CurrentFile.FullName -Destination $this.NewFullName;
        }
    }

    [void] Move($basePath) {
        $newFullPath = $basePath + "\" + $this.NewPath; 

        $this.CheckDestination($newFullPath);

        Write-Host("{0} -> {1}" -f $this.CurrentFile.Name, $this.NewFullName);
        
        if($PSCmdlet.ShouldProcess($this.CurrentFile.Name)) {
            Move-Item -Path $this.CurrentFile.FullName -Destination $this.NewFullName; 
        }
    }
}

function New-MediaFile([System.IO.FileSystemInfo] $currentFile, [DateTime] $dateTime)
{
    return [MediaFile]::new($currentFile, $dateTime);
}


Export-ModuleMember -Function New-MediaFile