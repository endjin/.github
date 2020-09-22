$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

. "$here\Get-AllRepoConfiguration.ps1"

Describe "Get-RepoConfiguration Tests" {

    Context "Local Mode" {

        # setup test data
        $testRepoPath = & "$here\..\scripts\_SetupRepoConfigurationTestDataForPester.ps1"

        It "should return a single repo configuration entry from an org with one configured repo" {

            $repo = Get-RepoConfiguration -ConfigDirectory $testRepoPath `
                                           -LocalMode `
                                           -OrgName 'endjin' `
                                           -RepoName 'dependency-playground'

            $repo | Should -BeOfType [hashtable]
            $repo.Keys.Count | Should -Be 5
            $repo.name.Count | Should -Be 1
            $repo.org | Should -Be 'endjin'
            $repo.name | Should -Be 'dependency-playground'
        }

        It "should return a single repo configuration entry from an org with multiple configured repos" {

            $repo = Get-RepoConfiguration -ConfigDirectory $testRepoPath `
                                           -LocalMode `
                                           -OrgName 'corvus-dotnet' `
                                           -RepoName 'Corvus.Retry'

            $repo | Should -BeOfType [hashtable]
            $repo.Keys.Count | Should -Be 4
            $repo.name | Should -BeOfType [string]
            $repo.org | Should -Be 'corvus-dotnet'
            $repo.name | Should -Be 'Corvus.Retry'
        }
    }
}
