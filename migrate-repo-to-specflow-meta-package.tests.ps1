$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut" -ConfigDirectory 'will-be-mocked'

# Get-Module Endjin.CodeOps | Remove-Module -Force
# Import-Module $here/Endjin.CodeOps -Force

Describe 'Migrate Repo to SpecFlow Meta Package Tests' {

    $upToDateProject = @'
<Project Sdk="Microsoft.NET.Sdk">
  <Import Project="$(EndjinProjectPropsPath)" Condition="$(EndjinProjectPropsPath) != ''" />

  <PropertyGroup>
    <TargetFramework>netcoreapp3.1</TargetFramework>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <RootNamespace>Menes.Specs</RootNamespace>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Corvus.Testing.SpecFlow.NUnit" Version="1.1.0" />
    <PackageReference Include="Endjin.RecommendedPractices" Version="1.1.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Idg.AsyncTestTools" Version="1.0.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\Menes.Abstractions\Menes.Abstractions.csproj" />
    <ProjectReference Include="..\Menes.Hosting.AspNetCore\Menes.Hosting.AspNetCore.csproj" />
  </ItemGroup>

</Project>
'@

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

    Context 'Up-to-date project' {
        $testProjectFile = Join-Path TestDrive: 'test-project.csproj'
        Set-Content -Path $testProjectFile -Value $upToDateProject

        Mock _getProjectFiles { $testProjectFile }
        Mock _saveProject {}

        It 'should run successfully with no save operation' {
            _repoChanges

            Assert-MockCalled _saveProject -Times 0
        }
    }

    Context 'Project requires migration' {
        $testProjectFile = Join-Path TestDrive: 'test-project.csproj'
        Set-Content -Path $testProjectFile -Value $testProject

        Mock _getProjectFiles { $testProjectFile }
        Mock _saveProject {}

        It 'should run successfully with no save operation' {
            _repoChanges

            Assert-MockCalled _saveProject -Times 1
        }
    }
}