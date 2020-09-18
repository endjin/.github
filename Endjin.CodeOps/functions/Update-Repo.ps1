function Update-Repo {
    param (
        [string] $RepoUrl,
        [string] $BranchName,
        [scriptblock]$RepoChanges,
        [switch] $WhatIf,
        [string] $CommitMessage,
        [string] $PrTitle,
        [string] $PrBody = " ",
        [string[]] $PrLabels
    )

    # Handle GitHub authentication based on whether running in GitHub Actions workflow or not
    if ( [string]::IsNullOrEmpty($env:GITHUB_TOKEN) -and (Test-Path env:\GITHUB_WORKFLOW) ) {
        Write-Error "The environment variable GITHUB_TOKEN is not set"
        exit
    }
    elseif ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
        Write-Host "GITHUB_TOKEN environment variable not present - triggering interactive login..."
        gh auth login
        $ghConfig = Get-Content ~/.config/gh/hosts.yml -Raw | ConvertFrom-Yaml
        $env:GITHUB_TOKEN = $ghConfig."github.com".oauth_token
    }

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
                Write-Host "Committing changes" -f green
                git add .
                if ($LASTEXITCODE -ne 0) { throw "git cli returned non-zero exit code staging files ('$LASTEXITCODE') - check previous log messages" }
                
                $noChanges = $false
                $output = git commit -m $CommitMessage
                if ($LASTEXITCODE -ne 0) {
                    if ($output -match 'nothing to commit') {
                        $noChanges = $true
                        Write-Host "git detected no changes - skipping update"
                    }
                    else {
                        throw "git cli returned non-zero exit code committing changes ('$LASTEXITCODE'):`n$output"
                    }
                }
                
                if ( -not $noChanges ) {
                    Write-Host "Pushing branch"
                    git push -u origin $BranchName
                    if ($LASTEXITCODE -ne 0) { Write-Error "git cli returned non-zero exit code when pushing branch ('$LASTEXITCODE') - check logs" }

                    Write-Host "Opening new PR"
                    $ghPrArgs = @("pr", "create", "--title", $PrTitle, "--body", $PrBody)
                    if ($PrLabels) { $ghPrArgs += @("--label", $PrLabels) }
                    gh @ghPrArgs
                    if ($LASTEXITCODE -ne 0) { throw "github cli returned non-zero exit code - check previous log messages" }
                }
            }
            else {
                Write-Host "What if: Would have committed changes and created new PR" -f cyan
            }
        }
        else {
            Write-Host "Repo was unchanged" -f green
        }
    }
    finally {
        Pop-Location
        Write-Verbose "Deleting temporary directory: $($tempDir.FullName)"
        Remove-Item $tempDir -Recurse -Force
    }
}