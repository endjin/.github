$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

$testProject = @'
<Project Sdk="Microsoft.NET.Sdk">
  <Import Project="$(EndjinProjectPropsPath)" Condition="$(EndjinProjectPropsPath) != ''" />

  <PropertyGroup>
    <TargetFramework>netcoreapp3.1</TargetFramework>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <RootNamespace>Menes.Specs</RootNamespace>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Corvus.Testing.SpecFlow" Version="0.7.0" />
    <PackageReference Include="Endjin.RecommendedPractices" Version="1.1.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="NUnit3TestAdapter" Version="3.16.1">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Moq" Version="4.14.4" />
    <PackageReference Include="Idg.AsyncTestTools" Version="1.0.0" />
    <PackageReference Include="SpecFlow.NUnit" Version="3.3.30" />
    <PackageReference Include="SpecFlow.Tools.MsBuild.Generation" Version="3.3.30" />
    <PackageReference Include="nunit" Version="3.12.0" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="16.6.1" />
    <PackageReference Include="coverlet.msbuild" Version="2.9.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\Menes.Abstractions\Menes.Abstractions.csproj" />
    <ProjectReference Include="..\Menes.Hosting.AspNetCore\Menes.Hosting.AspNetCore.csproj" />
  </ItemGroup>

</Project>
'@

$testProjectNoPackages = @'
<Project Sdk="Microsoft.NET.Sdk">
  <Import Project="$(EndjinProjectPropsPath)" Condition="$(EndjinProjectPropsPath) != ''" />

  <PropertyGroup>
    <TargetFramework>netcoreapp3.1</TargetFramework>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <RootNamespace>Menes.Specs</RootNamespace>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\Menes.Abstractions\Menes.Abstractions.csproj" />
    <ProjectReference Include="..\Menes.Hosting.AspNetCore\Menes.Hosting.AspNetCore.csproj" />
  </ItemGroup>

</Project>
'@

Describe 'Add-VsProjectPackageReference Tests' {

    It 'should successfully add a package reference' {
        [xml]$project = $testProject

        $project.Project.ItemGroup.PackageReference.Include.Count | Should -be 10
        $project.Project.ItemGroup.ProjectReference.Include.Count | Should -be 2

        $isUpdated,$updatedProject = Add-VsProjectPackageReference -Project $project `
                                                        -PackageId 'Corvus.Testing.SpecFlow.NUnit' `
                                                        -PackageVersion '1.1.0'

        $isUpdated | Should -BeOfType [bool]
        $isUpdated | Should -Be $True
        $updatedProject | Should -BeOfType [xml]
        $updatedProject.Project.ItemGroup.PackageReference.Include.Count | Should -be 11
        $updatedProject.Project.ItemGroup.ProjectReference.Include.Count | Should -be 2
    }

    It 'should not add a package reference that already exists' {
      Mock Write-Host {}

      [xml]$project = $testProject

      $project.Project.ItemGroup.PackageReference.Include.Count | Should -be 10
      $project.Project.ItemGroup.ProjectReference.Include.Count | Should -be 2

      $isUpdated,$updatedProject = Add-VsProjectPackageReference -Project $project `
                                                      -PackageId 'Corvus.Testing.SpecFlow' `
                                                      -PackageVersion '0.7.0'

      $updatedProject.Project.ItemGroup.PackageReference.Include.Count | Should -be 10
      $updatedProject.Project.ItemGroup.ProjectReference.Include.Count | Should -be 2

      $isUpdated | Should -BeOfType [bool]
      $isUpdated | Should -Be $False
      Assert-MockCalled -Times 0 Write-Host
  }

  It 'should update an existing package reference version' {
    [xml]$project = $testProject

    $project.Project.ItemGroup.PackageReference.Include.Count | Should -be 10
    $project.Project.ItemGroup.ProjectReference.Include.Count | Should -be 2

    $isUpdated,$updatedProject = Add-VsProjectPackageReference -Project $project `
                                                    -PackageId 'Corvus.Testing.SpecFlow' `
                                                    -PackageVersion '0.8.0'

    $isUpdated | Should -BeOfType [bool]
    $isUpdated | Should -Be $True
    $updatedProject.Project.ItemGroup.PackageReference.Include.Count | Should -be 10
    $updatedProject.Project.ItemGroup.ProjectReference.Include.Count | Should -be 2
    $updatedProject.Project.ItemGroup.PackageReference | `
      ? { $_.Include -eq 'Corvus.Testing.SpecFlow' } | `
      Select -ExpandProperty Version | `
        Should -be '0.8.0'
    
    Assert-MockCalled -Times 1 Write-Host
  }

  It 'should successfully add package references to a project with no package references' {
    [xml]$project = $testProjectNoPackages

    $isUpdated,$updatedProject = Add-VsProjectPackageReference -Project $project `
                                                      -PackageId 'Corvus.Testing.SpecFlow.NUnit' `
                                                      -PackageVersion '1.1.0'

    $isUpdated | Should -BeOfType [bool]
    $isUpdated | Should -Be $True
    $updatedProject | Should -BeOfType [xml]
    $updatedProject.Project.ItemGroup.PackageReference.Include.Count | Should -be 1
  }
}