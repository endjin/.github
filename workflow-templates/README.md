# GitHub Actions Workflow Templates

The following workflow templates are available:

- auto_merge
- auto_release
- dependabot_approve_and_label
- manual_release
- publish_to_dockerhub
- publish_to_psgallery

## PR-AUTOFLOW Workflows

More details about `pr-autoflow` can be found [here](https://raw.githubusercontent.com/endjin/pr-autoflow/master/README.md).

The following related workflows interact with each to faciliate the automated approval, merging and releasing of certain pull requests.

These workflows require a JSON configuration file stored in `.github/config/pr-autoflow.json` of the form shown below:

```
{
  "AUTO_MERGE_PACKAGE_WILDCARD_EXPRESSIONS": "[\"Endjin.*\",\"Corvus.*\"]",
  "AUTO_RELEASE_PACKAGE_WILDCARD_EXPRESSIONS": "[]"
}
```

>NOTE: This file will be automatically setup if a repo is configured to use `pr-autoflow` in [repos configuration area](/repos/live).

### dependabot_approve_and_label
This workflow handles the automated approval of Dependabot pull requests (based on the above configuration) and uses a labelling system to help coordinate the other workflows in the system.

#### labels

* autosquash - marks a pull request to be automatically merged when it is ready
* release_pending - marks that a pull request should trigger an automated release once it is merged.  Such pull requests are either Dependabot PRs configured for auto release (see above config file) or regular PRs which should be released as part of the CD process.

### auto_merge
This workflow will merge any pull requests that have the '`autosquash` label and are otherwise ready to merge (e.g. approved, all checks passing etc.)

### auto_release
This workflow handles the automated tagging of the git repo when suitable pull requests are closed, which in turn can trigger separate release pipelines.

* Pull requests with a `no_release` label will not be processed by this workflow
* The workflow will wait for all in-flight Dependabot pull requests that are configured for `auto_release` to be completed before performing the tag operation - this is to avoid a new release for each dependency update.
* The workflow also understands the `release_pending` label applied to non-Dependabot pull requests in the `dependabot_approve_and_label` workflow, which allows it to tag the repo when normal pull requests are merged.

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