[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string[]]
    $Organisations
)
$ErrorActionPreference = 'Stop'

try {
    Write-Host ("Organisations to sync:`n - {0}" -f ($Organisations -join "`n - "))
    Write-Host ("Commit to sync:`n{0}" -f $(& git --no-pager branch -v))

    foreach ($org in $Organisations) {
        $repoUrl = "git@github.com:{0}/.github.git" -f $org

        Write-Host "`nProcessing: $repoUrl"
        git remote add target $repoUrl
        if ($LASTEXITCODE -ne 0) { throw "Error configuring remote for '$org' - check logs" }

        try {
            Write-Host " --> Syncing"
            git push -f target master
            if ($LASTEXITCODE -ne 0) { throw "Error pushing to remote for '$org' - check logs" }
        }
        finally {
            git remote remove target
        }
    }
}
catch {
    Write-Error $_.Exception.Message
    Write-Output ("::error file={0},line={1},col={2}::{3}" -f `
                        $_.InvocationInfo.ScriptName,
                        $_.InvocationInfo.ScriptLineNumber,
                        $_.InvocationInfo.OffsetInLine,
                        $_.Exception.Message)
    exit 1
}