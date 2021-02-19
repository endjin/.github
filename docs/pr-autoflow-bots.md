# pr-autoflow bots

There are several GitHub Apps (or bots) involved in the workflows associated with pr-autoflow. This document lists them all and explains their purpose.

# dependabot

<img src="images/dependabot.png" width=50px />

* Built-in GitHub app
* Manages dependency update PRs, when enabled
* Used in pr-autoflow for:
  * Opening initial dependency PR
  * Adding ‘dependencies’ label
  * Closing PR if no longer valid
  * Updating PR when target branch has moved on

# github-actions

<img src="images/github-actions.png" width=50px />

* Built-in GitHub app
* Default identity associated with GitHub Action workflow runs
  * Token accessed using `${{secrets.GITHUB_TOKEN}}`
* Used in pr-autoflow for:
  * Querying GitHub API (e.g. get list of open PRs)

# endjin-bot

<img src="images/endjin-bot.png" width=50px />

* Custom GitHub app
* Used in pr-autoflow for:
  * Approving dependency PRs
  * Labelling dependency PRs
  * Merging dependency PRs
  * Tagging commits (for release)
* Why not use github-actions?
  * Branch policies require a different user to approve PR to one that opened it
  * Does not trigger further workflows

# dependjinbot

<img src="images/dependjinbot.png" width=50px />

* Custom GitHub app
* Used in pr-autoflow for:
  * Creating CodeOps PRs
* Why not use endjin-bot?
  * Branch policies require a different user to approve PR to one that opened it

