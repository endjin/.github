$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

. "$here\_CloneGitRepo.ps1"
. "$here\New-TemporaryDirectory.ps1"

Describe "Get-AllRepoConfiguration Tests" {

    Context "Local Mode" {

        # setup test data
        $testRepoPath = & "$here\..\scripts\_SetupRepoConfigurationTestDataForPester.ps1"

        It "should process the repository successfully" {

            Mock New-TemporaryDirectory { $testRepoPath }

            $repos = Get-AllRepoConfiguration -ConfigDirectory $testRepoPath `
                                              -LocalMode

            $repos.Count | Should -be 3
            $repos.name.Count | Should -be 4
        }
    }

    Context "Remote Repo Mode" {

      # setup test data
      $testRepoPath = & "$here\..\scripts\_SetupRepoConfigurationTestDataForPester.ps1"

      It "should process the repository successfully" {

          Mock _CloneGitRepo { $testRepoPath }
          Mock New-TemporaryDirectory { $testRepoPath }

          $repos = Get-AllRepoConfiguration -ConfigDirectory $testRepoPath

          Assert-MockCalled _cloneGitRepo -Times 1

          $repos.Count | Should -be 3
          $repos.name.Count | Should -be 4
      }
    }
}