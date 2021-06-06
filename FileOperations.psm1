
$dateTimeFileNameFormat = "yyyyMMdd-HHmmss";

class NewFile {
    [string] $NewPath;
    [string] $NewFullName;
    [DateTime] $DateTime;
    [string] $Name;
    [string] $CurrentFullName;

    NewFile([System.IO.FileSystemInfo] $currentFile, [DateTime] $dateTime, $basePath) {
        $this.CurrentFullName = $currentFile.FullName;
        $this.Name = $dateTime.ToString($dateTimeFileNameFormat) + "." + $currentFile.Extension;
        $this.NewPath = $basePath + "\" + $dateTime.Year.ToString() + "\" + $dateTime.Month.ToString("00") 
        $this.NewFullName = $this.NewPath + $this.Name;
        $this.DateTime = $dateTime;
    }

    [void] Copy() {
        # if directory does not exist create it
        if(-not (Test-Path -Path $this.NewPath)) {
            New-Item -Path $this.NewPath -ItemType Directory | Out-Null;
        }
    }

    [void] Move() {
        # if directory does not exist create it
        if(-not (Test-Path -Path $this.NewPath)) {
            New-Item -Path $this.NewPath -ItemType Directory | Out-Null;
        }

        $this.Name = $this.BaseName + $ext;
    }
}

function Create-NewMediaFile([System.IO.FileSystemInfo] $currentFile,  [DateTime] $dateTime, $basePath)
{
    return [NewFile]::new( );
}


Export-ModuleMember -Function Create-NewMediaFile