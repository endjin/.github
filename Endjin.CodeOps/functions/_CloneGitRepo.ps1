function _CloneGitRepo
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string] $RepoUrl
    )

    $tempDir = New-TemporaryDirectory
    Push-Location $tempDir.FullName

    Write-Host "Created temporary directory: $($tempDir.FullName)"

    Write-Host "Cloning: $RepoUrl"
    git clone $RepoUrl .
    if ($LASTEXITCODE -ne 0) { throw "git cli returned non-zero exit code cloning the repo - check previous log messages" }

    return $tempDir
}