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
        [string] $PrBody = " ",
        [string[]] $PrLabels,
        [string] $GitHubToken
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
        $ghPrArgs = @("pr", "create", "--title", $PrTitle, "--body", $PrBody)
        if ($PrLabels) { $ghPrArgs += @("--label", ($PrLabels -join ",")) }

        Write-Output $GitHubToken | gh auth login --with-token

        gh @ghPrArgs
    }

    Pop-Location

    "Deleting temporary directory: $($tempDir.FullName)"
    Remove-Item $tempDir -Recurse -Force
}

function Get-Repos {
    param (
        [string] $ConfigDirectory
    )

    $repos = @()
    Get-ChildItem $ConfigDirectory -Recurse -Filter *.yml | ForEach-Object {
        $config = Get-Content -Raw -Path $_.FullName | ConvertFrom-Yaml
        $repos += $config.repos
    }

    return $repos
}