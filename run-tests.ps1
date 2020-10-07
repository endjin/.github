$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $PSCommandPath
$pesterVer = '4.10.1'
try {
    # Ensure we use tour targetted version of Pester
    [array]$existingModule = Get-Module -ListAvailable Pester
    if (!$existingModule -or ($existingModule.Version -notcontains $pesterVer)) {
        Install-Module Pester -RequiredVersion $pesterVer -Force -Scope CurrentUser -Repository PSGallery
    }
    Import-Module Pester -Version $pesterVer

    # Handle any module pre-reqs
    $requiredModules = @(
        'powershell-yaml'
        'Endjin.CodeOps'
    )
    $requiredModules | ForEach-Object {
        if (!(Get-Module -ListAvailable $_) ) {
            Install-Module $_ -Force -Scope CurrentUser -Repository PSGallery
        }
    }

    $results = Invoke-Pester $here -PassThru


    $total = $results.TotalCount
    $passed = $results.PassedCount
    $failed = $results.FailedCount
    $skipped = $results.SkippedCount

    Write-Host "`nTEST SUMMARY"
    Write-Host "Total Tests        : $total"
    Write-Host "Total Passed Tests : $passed"
    Write-Host "Total Failed Tests : $failed"
    Write-Host "Total Skipped Tests: $skipped"

    if ($failed -gt 0) {
        Write-Host "Some tests failed - check previous logs"
        exit 1
    }
}
catch {
    Write-Output ("::error file={0},line={1},col={2}::{3}" -f `
                        $_.InvocationInfo.ScriptName,
                        $_.InvocationInfo.ScriptLineNumber,
                        $_.InvocationInfo.OffsetInLine,
                        $_.Exception.Message)

    exit 1
}
