function Use-Assembly
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $Path
    )

    if ( !(Test-Path $Path) )
    {
        throw "Unable to find the assembly: $Path"
    }

    # Load the assembly without locking the file
    $fileStream = ([System.IO.FileInfo] (Get-Item $Path)).OpenRead()
    $assemblyBytes = new-object byte[] $fileStream.Length
    $fileStream.Read($assemblyBytes, 0, $fileStream.Length) | Out-Null
    $fileStream.Close()

    [System.Reflection.Assembly]::Load($assemblyBytes);
}