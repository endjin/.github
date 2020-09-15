function Update-Repo {
    param (
        [string] $RepoUrl,
        [string] $BranchName,
        [scriptblock]$RepoChanges,
        [switch] $WhatIf,
        [string] $CommitMessage,
        [string] $PrTitle,
        [string] $PrBody = " ",
        [string] $PrLabels
    )

    $tempDir = New-TemporaryDirectory
    Push-Location $tempDir.FullName
    try {
        Write-Host "Created temporary directory: $($tempDir.FullName)"

        Write-Host "Cloning: $RepoUrl"
        git clone $RepoUrl .
        if ($LASTEXITCODE -ne 0) { throw "git cli returned non-zero exit code cloning the repo - check previous log messages" }

        Write-Host "Creating new branch: $BranchName"
        git checkout -b $BranchName
        if ($LASTEXITCODE -ne 0) { throw "git cli returned non-zero exit code checking out new branch - check previous log messages" }

        $isUpdated = $RepoChanges.Invoke()

        if ($isUpdated) {
            if (!$WhatIf) {
                Write-Host "Committing changes"
                git add .
                if ($LASTEXITCODE -ne 0) { throw "git cli returned non-zero exit code staging files - check previous log messages" }
                git commit -m $CommitMessage
                if ($LASTEXITCODE -ne 0) { throw "git cli returned non-zero exit code committing changes - check previous log messages" }

                Write-Host "Opening new PR"
                $ghPrArgs = @("pr", "create", "--title", $PrTitle, "--body", $PrBody)
                if ($PrLabels) { $ghPrArgs += @("--label", $PrLabels) }
                gh @ghPrArgs
                if ($LASTEXITCODE -ne 0) { throw "github cli returned non-zero exit code - check previous log messages" }
            }
            else {
                Write-Host "What if: Would have committed changes and created new PR" -f cyan
            }
        }
        else {
            Write-Host "Repo is already up-to-date or contained no .Specs projects"
        }
    }
    finally {
        Pop-Location

        "Deleting temporary directory: $($tempDir.FullName)"
        Remove-Item $tempDir -Recurse -Force
    }
}