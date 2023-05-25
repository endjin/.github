# GitHub Actions Workflow Templates

The following workflow templates are available:

- manual_release
- publish_to_dockerhub
- publish_to_psgallery

## Workflows

### manual_release
This workflow forces the git tag to be applied to the repo and is useful for either handling changes made outside the PR process or situations where there has been an issue with the `pr-autoflow` process and the release didn't happen for some reason.

## publish_to_dockerhub
This workflow is designed to be triggered by the `auto_release` workflow to publish and tags docker images to DockerHub using GitHub secrets to authenticate.

The workflow requires a JSON configuration file stored in `.github/config/docker.json` to set the name of the DockerHub repository name.

```
{
    "docker_repository": "endjin/endjin.githubactions.powershell"
}
```
The following secrets are required:
* ENDJIN_DOCKERHUB_USERNAME
* ENDJIN_DOCKERHUB_ACCESSTOKEN

## publish_to_psgallery
This workflow is designed to be triggered by the `auto_release` workflow to package and publish a PowerShell module to the [PowerShell Gallery](https://powershellgallery.com).  It also patches the module manifest to include the correct versioning information, prior to publishing.

The workflow requires a JSON configuration file stored in `.github/config/ps-module.json` to set the name of the module manifest file to be published.

```
{
    "module_manifest_path": "./MyModule/MyModule.psd1"
}
```
The following secrets are required:
* ENDJIN_PSGALLERY_APIKEY