$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
$pesterVer = '4.10.1'
try {
    # Ensure we use tour targetted version of Pester
    [array]$existingModule = Get-Module -ListAvailable Pester
    if (!$existingModule -or ($existingModule.Version -notcontains $pesterVer)) {
        Install-Module Pester -RequiredVersion $pesterVer -Force -Scope CurrentUser
    }
    Import-Module Pester

    # Handle any module pre-reqs
    $requiredModules = @(
        'powershell-yaml'
    )
    $requiredModules | ForEach-Object {
        if (!(Get-Module -ListAvailable $_) ) {
            Install-Module $_ -Force
        }
    }

    # Ensure we don't have an old version of the module already loaded
    Get-Module Endjin.CodeOps | Remove-Module -Force
    $results = Invoke-Pester $here -PassThru

    if ($results.FailedCount -gt 0) {
        Write-Host ("{0} out of {1} tests failed - check previous logging for more details" -f $results.FailedCount, $results.TotalCount)
    }

    $results
}
catch {
    Write-Output ("::error file={0},line={1},col={2}::{3}" -f `
                        $_.InvocationInfo.ScriptName,
                        $_.InvocationInfo.ScriptLineNumber,
                        $_.InvocationInfo.OffsetInLine,
                        $_.Exception.Message)

    exit 1
}
