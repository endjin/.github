# GitHub Settings Defintions

This directory contains files that each implement the process of checking and applying a particular GitHub repository setting.  For example, enforcing branch protection on a repo's default branch.

They are referenced by the `apply-github-settings.ps1` script, based on the settings defined in [`getDefaultSettingsPolicy.ps1`](getDefaultSettingsPolicy.ps1).

The above defaults can be overridden in the repository configuration YAML files. For example, the YAML below would allow the `hello-world` repository to opt-out of having brach protection enforced on its default branch.

```yaml
repos:
  - org: myorg
    name: hello-world
    githubSettings:
      default_branch_protection: false
```

## Adding new defintions

When developing new defintions

1. create a new file in this folder containing a function
1. name the function the same name as how the policy will be referenced (both in `getDefaultSettingsPolicy.ps1` and repository configuration YAML files)
1. If the setting is to be applied as part of the default policy, add it to the hashtable of settings in `getDefaultSettingsPolicy.ps1`

A skeleton of such a function is provided below:

```powershell
function my_important_setting
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        $SettingValue,

        [Parameter(Mandatory = $true)]
        [string] $Org,

        [Parameter(Mandatory = $true)]
        [string] $RepoName
    )

    if ($SettingValue -eq "<WhetherThisSettingIsEnabled>") {
        # Implementation goes here
    }
}
```

### Notes

* `$SettingValue` will contain the value setting from the policy - typically this will be `$true` or `$false` to control whether the policy should be applied, but it could also be payload for the policy itself 
* The logic that applies the setting must be wrapped in a conditional block based on `$PSCmdlet.ShouldProcess()`, this is to ensure that `-WhatIf` processing behaves consistently
