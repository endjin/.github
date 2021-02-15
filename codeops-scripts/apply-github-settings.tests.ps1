$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Applying standard GitHub settings" {

    $allReposJson = @'
[
    {
        "id": 1,
        "name": "dependency-playground",
        "full_name": "endjin/dependency-playground",
        "private": false,
        "owner": {
            "login": "endjin"
        },
        "html_url": "https://github.com/endjin/dependency-playground",
        "description": null,
        "default_branch": "master"
    },
    {
        "id": 2,
        "name": "another-repo",
        "full_name": "endjin/another-repo",
        "private": true,
        "owner": {
            "login": "endjin"
        },
        "html_url": "https://github.com/endjin/another-repo",
        "description": "A fake repo for testing",
        "default_branch": "main"
    },
    {
        "id": 3,
        "name": "some-other-repo",
        "full_name": "endjin/some-other-repo",
        "private": true,
        "owner": {
            "login": "endjin"
        },
        "html_url": "https://github.com/endjin/some-other-repo",
        "description": "Another fake repo for testing",
        "default_branch": "main"
    }
]
'@

    $defaultSettings = @{
        delete_branch_on_merge = $true
        default_branch_protection = $true
    }

    Mock Invoke-GitHubRestMethod { $allReposJson | ConvertFrom-Json -Depth 30 -AsHashtable }

    
    Context "Merging settings overrides - single project YAML entries" {

        $repoYamlSingleProject = @'
repos:
- org: endjin
  name: dependency-playground
  githubSettings:
    default_branch_protection: false
'@

        $configDir = Join-Path 'TestDrive:' 'repo'
        New-Item -ItemType Directory $configDir
        set-content -Path $configDir/test.yml -Value $repoYamlSingleProject
        $repos = [array](Get-AllRepoConfiguration -ConfigDirectory $configDir -LocalMode | Where-Object { $_ })
        
        $repoDefaults = _getAllOrgReposWithDefaults -Org 'endjin' -DefaultSettings $defaultSettings
        $result = _mergeSettingsOverrides -RepoOverrides $repos `
                                          -RepoDefaults $repoDefaults

        It "should return the correct number of repositories" {
            $result.Keys.Count | Should -Be 3
        }

        It "should return the default value for the non-overridden repo" {
            $result["another-repo"].default_branch_protection | Should -Be $true
            $result["some-other-repo"].default_branch_protection | Should -Be $true
        }

        It "should return the custom value for the overridden repo" {
            $result["dependency-playground"].default_branch_protection | Should -Be $false
        }
    }

    Context "Merging settings overrides - multi-project YAML entries" {
        $repoYamlMultiProject = @'
repos:
- org: endjin
  name:
    - dependency-playground
    - another-repo
  githubSettings:
    delete_branch_on_merge: false
- org: endjin
  name: some-other-repo
'@

        $configDir = Join-Path 'TestDrive:' 'repo'
        New-Item -ItemType Directory $configDir
        set-content -Path $configDir/test.yml -Value $repoYamlMultiProject
        $repos = [array](Get-AllRepoConfiguration -ConfigDirectory $configDir -LocalMode | Where-Object { $_ })

        $repoDefaults = _getAllOrgReposWithDefaults -Org 'endjin' -DefaultSettings $defaultSettings
        $result = _mergeSettingsOverrides -RepoOverrides $repos `
                                        -RepoDefaults $repoDefaults

        It "should return the correct number of repositories" {
            $result.Keys.Count | Should -Be 3
        }

        It "should return the default value for the non-overridden repo" {
            $result["some-other-repo"].delete_branch_on_merge | Should -Be $true
        }

        It "should return the custom value for the overridden repos" {
            $result["another-repo"].delete_branch_on_merge | Should -Be $false
            $result["dependency-playground"].delete_branch_on_merge | Should -Be $false
        }


    }
}