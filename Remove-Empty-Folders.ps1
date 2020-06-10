param 
(
    $SourceFolder = "."
)

# stack to hold directories
$stack = New-Object 'System.Collections.Stack';

# prime stack
$stack.Push($SourceFolder);

# while we still have directories on the stack
while($stack.Count -ne 0)
{
    # check a directory
    $dir = $stack.Pop();

    # if the directory is empty, delete it
    if(@(Get-ChildItem $dir).Count -eq 0)
    {
        Write-Host $dir
        Remove-Item $dir -Recurse -Force
    }
    # else add its child directories to the stack
    else 
    {
        foreach($d in (Get-ChildItem $dir -Directory))
        {
            $stack.Push($d);
        }
    }
}