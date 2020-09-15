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

Describe 'Remove-VsProjectPackageReference Tests' {

    It 'should successfully remove a package reference that exists' {
        [xml]$project = $testProject

        $project.Project.ItemGroup.PackageReference.Include.Count | Should -be 10

        $updatedProject = Remove-VsProjectPackageReference -Project $project `
                                                           -PackageId 'Corvus.Testing.SpecFlow' `

        $updatedProject | Should -BeOfType [xml]
        $updatedProject.Project.ItemGroup.PackageReference.Include.Count | Should -be 9
        $updatedProject.Project.ItemGroup.ProjectReference.Include.Count | Should -be 2
    }
}