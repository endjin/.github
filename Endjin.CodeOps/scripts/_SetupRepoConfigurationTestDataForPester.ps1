$file1 = @'
repos:
  - org: endjin
    name: dependency-playground
    prAutoflowSettings:
      AUTO_MERGE_PACKAGE_WILDCARD_EXPRESSIONS:
      - Endjin.*
      - Corvus.*
      AUTO_RELEASE_PACKAGE_WILDCARD_EXPRESSIONS:
      - Corvus.*
    specflowMetaPackageSettings:
      enabled: true
    syncWorkflowTemplates: false
'@
$file2 = @'
repos:
  - org: corvus-dotnet
    name:
    - Corvus.Retry
    - Corvus.Leasing
    prAutoflowSettings:
      AUTO_MERGE_PACKAGE_WILDCARD_EXPRESSIONS: 
      - Endjin.*
      - Corvus.*
    specflowMetaPackageSettings:
      enabled: true
'@
$file3 = @'
repos:
  - org: vellum-dotnet
    name:
    - vellum-cli
    prAutoflowSettings:
      AUTO_MERGE_PACKAGE_WILDCARD_EXPRESSIONS: 
      - Endjin.*
      - Corvus.*
    specflowMetaPackageSettings:
      enabled: true
    syncWorkflowTemplates: true
'@

$testRepoPath = Join-Path "TestDrive:" "repo"
New-Item -ItemType Directory $testRepoPath | Out-Null

Set-Content -Path (Join-Path $testRepoPath "file1.yml") -Value $file1
Set-Content -Path (Join-Path $testRepoPath "file2.yml") -Value $file2
Set-Content -Path (Join-Path $testRepoPath "file3.yml") -Value $file3

$testRepoPath