function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Update-Repo {
    param (
        [string] $RepoUrl,
        [scriptblock]$RepoChanges,
        [switch] $WhatIf,
        [string] $CommitMessage,
        [string] $PrTitle,
        [string] $PrBody = " "
    )

    $tempDir = New-TemporaryDirectory

    Push-Location $tempDir.FullName

    Write-Host "Created temporary directory: $($tempDir.FullName)"

    Write-Host "Cloning: $RepoUrl"
    git clone $RepoUrl .

    Write-Host "Creating new branch: $BranchName"
    git checkout -b $BranchName

    $RepoChanges.Invoke()

    if (!$WhatIf) {
        Write-Host "Committing changes"
        git add .
        git commit -m $CommitMessage

        Write-Host "Opening new PR"
        gh pr create --title $PrTitle --body $PrBody
    }

    Pop-Location

    "Deleting temporary directory: $($tempDir.FullName)"
    Remove-Item $tempDir -Recurse -Force
}