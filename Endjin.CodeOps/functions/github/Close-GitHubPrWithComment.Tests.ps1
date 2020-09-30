$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

. "$here\Invoke-GitHubRestRequest.ps1"

Describe 'Close-GitHubPrWithComment Tests' {

    $testPr = @'
{
    "url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls/161",
    "id": 490079244,
    "node_id": "MDExOlB1bGxSZXF1ZXN0NDkwMDc5MjQ0",
    "html_url": "https://github.com/corvus-dotnet/Corvus.Leasing/pull/161",
    "diff_url": "https://github.com/corvus-dotnet/Corvus.Leasing/pull/161.diff",
    "patch_url": "https://github.com/corvus-dotnet/Corvus.Leasing/pull/161.patch",
    "issue_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues/161",
    "number": 161,
    "state": "open",
    "locked": false,
    "title": "Bump Microsoft.NET.Test.Sdk from 16.6.0-preview-20200226-03 to 16.7.1 in /Solutions",
    "user": {
        "login": "dependabot[bot]",
        "id": 49699333,
        "node_id": "MDM6Qm90NDk2OTkzMzM=",
        "avatar_url": "https://avatars0.githubusercontent.com/in/29110?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/dependabot%5Bbot%5D",
        "html_url": "https://github.com/apps/dependabot",
        "followers_url": "https://api.github.com/users/dependabot%5Bbot%5D/followers",
        "following_url": "https://api.github.com/users/dependabot%5Bbot%5D/following{/other_user}",
        "gists_url": "https://api.github.com/users/dependabot%5Bbot%5D/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/dependabot%5Bbot%5D/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/dependabot%5Bbot%5D/subscriptions",
        "organizations_url": "https://api.github.com/users/dependabot%5Bbot%5D/orgs",
        "repos_url": "https://api.github.com/users/dependabot%5Bbot%5D/repos",
        "events_url": "https://api.github.com/users/dependabot%5Bbot%5D/events{/privacy}",
        "received_events_url": "https://api.github.com/users/dependabot%5Bbot%5D/received_events",
        "type": "Bot",
        "site_admin": false
    },
    "body": "Bumps [Microsoft.NET.Test.Sdk](https://github.com/microsoft/vstest) from 16.6.0-preview-20200226-03 to 16.7.1.\n<details>\n<summary>Release notes</summary>\n<p><em>Sourced from <a href=\"https://github.com/microsoft/vstest/releases\">Microsoft.NET.Test.Sdk's releases</a>.</em></p>\n<blockquote>\n<h2>v16.7.1</h2>\n<p>See the release notes <a href=\"https://github.com/microsoft/vstest-docs/blob/master/docs/releases.md#1671\">here</a></p>\n<h2>v16.7.0</h2>\n<p>See the release notes <a href=\"https://github.com/microsoft/vstest-docs/blob/master/docs/releases.md#1670\">here</a>.</p>\n<h2>v16.7.0-preview-20200519-01</h2>\n<p>See the release notes <a href=\"https://github.com/microsoft/vstest-docs/blob/master/docs/releases.md#1670-preview-20200519-01\">here</a>.</p>\n<h2>v16.7.0-preview-20200428-01</h2>\n<p>See the release notes <a href=\"https://github.com/microsoft/vstest-docs/blob/master/docs/releases.md#1670-preview-20200428-01\">here</a>.</p>\n<h2>v16.6.1</h2>\n<p>See the release notes <a href=\"https://github.com/microsoft/vstest-docs/blob/master/docs/releases.md#1661\">here</a>.</p>\n<h2>v16.6.0</h2>\n<blockquote>\n<p>✔ 16.6.1 was released, use that instead.</p>\n</blockquote>\n<blockquote>\n<p>🔥 VSTest release 16.6.0 has a major bug in Fakes in vstest.console. The 16.6.0 packages are unlisted from nuget.org, with the exception of Microsoft.NET.Test.SDK and it's dependencies <strong>which are not impacted</strong> by this problem.\nPlease see: <a href=\"https://github-redirect.dependabot.com/microsoft/vstest/issues/2408\">microsoft/vstest#2408</a></p>\n</blockquote>\n<p>See the release notes <a href=\"https://github.com/microsoft/vstest-docs/blob/master/docs/releases.md#1660\">here</a>.</p>\n<h2>v16.6.0-preview-20200318-01</h2>\n<p>See the release notes <a href=\"https://github.com/microsoft/vstest-docs/blob/master/docs/releases.md#1660-preview-20200318-01\">here</a>.</p>\n<h2>v16.6.0-preview-20200310-03</h2>\n<p>See the release notes <a href=\"https://github.com/microsoft/vstest-docs/blob/master/docs/releases.md#1660-preview-20200310-03\">here</a>.</p>\n<h2>v16.6.0-preview-20200309-01</h2>\n<p>See the release notes <a href=\"https://github.com/microsoft/vstest-docs/blob/master/docs/releases.md#1660-preview-20200309-01\">here</a>.</p>\n</blockquote>\n</details>\n<details>\n<summary>Commits</summary>\n<ul>\n<li><a href=\"https://github.com/microsoft/vstest/commit/1d3039474ca085b64800e5b85556e4a903213308\"><code>1d30394</code></a> Fixed code coverage compatibility issue (<a href=\"https://github-redirect.dependabot.com/microsoft/vstest/issues/2527\">#2527</a>)</li>\n<li><a href=\"https://github.com/microsoft/vstest/commit/c1b6b2c1ab4c8f181f3cb1a436afb6428009c7ab\"><code>c1b6b2c</code></a> Adding test run attachments processing (<a href=\"https://github-redirect.dependabot.com/microsoft/vstest/issues/2463\">#2463</a>)</li>\n<li><a href=\"https://github.com/microsoft/vstest/commit/df62aca07cacc5c018dc8e828f03a0cd79ee52da\"><code>df62aca</code></a> Added new exception handling (<a href=\"https://github-redirect.dependabot.com/microsoft/vstest/issues/2461\">#2461</a>)</li>\n<li><a href=\"https://github.com/microsoft/vstest/commit/2474ad2f7ae7dbda0dd1850b3065d04bdadf5434\"><code>2474ad2</code></a> Revert to previous dotnet version</li>\n<li><a href=\"https://github.com/microsoft/vstest/commit/f777f36e8673d2b58de2c992df48ec36eea10826\"><code>f777f36</code></a> Merge master</li>\n<li><a href=\"https://github.com/microsoft/vstest/commit/c449a1e6103ab251f2624dea664952da811e9c48\"><code>c449a1e</code></a> Update feeds</li>\n<li><a href=\"https://github.com/microsoft/vstest/commit/fceebbc13011a5b77e9232b89796ead2853894a0\"><code>fceebbc</code></a> Update dependencies from <a href=\"https://github.com/dotnet/arcade\">https://github.com/dotnet/arcade</a> build 20200602.3 (#...</li>\n<li><a href=\"https://github.com/microsoft/vstest/commit/a2080d15d3bfec54646492eac8b38d0298db174a\"><code>a2080d1</code></a> Update dependencies from <a href=\"https://github.com/dotnet/arcade\">https://github.com/dotnet/arcade</a> build 20200602.3 (#...</li>\n<li><a href=\"https://github.com/microsoft/vstest/commit/501939e9fa61f0c65fb466d6367f6d5000b86fec\"><code>501939e</code></a> Trim version</li>\n<li><a href=\"https://github.com/microsoft/vstest/commit/1fbf4a3b661610d513063c7a241424a0cb72e2ea\"><code>1fbf4a3</code></a> Change assertion</li>\n<li>Additional commits viewable in <a href=\"https://github.com/microsoft/vstest/compare/v16.6.0-preview-20200226-03...v16.7.1\">compare view</a></li>\n</ul>\n</details>\n<br />\n\n\n[![Dependabot compatibility score](https://dependabot-badges.githubapp.com/badges/compatibility_score?dependency-name=Microsoft.NET.Test.Sdk&package-manager=nuget&previous-version=16.6.0-preview-20200226-03&new-version=16.7.1)](https://docs.github.com/en/github/managing-security-vulnerabilities/configuring-github-dependabot-security-updates)\n\nDependabot will resolve any conflicts with this PR as long as you don't alter it yourself. You can also trigger a rebase manually by commenting `@dependabot rebase`.\n\n[//]: # (dependabot-automerge-start)\n[//]: # (dependabot-automerge-end)\n\n---\n\n<details>\n<summary>Dependabot commands and options</summary>\n<br />\n\nYou can trigger Dependabot actions by commenting on this PR:\n- `@dependabot rebase` will rebase this PR\n- `@dependabot recreate` will recreate this PR, overwriting any edits that have been made to it\n- `@dependabot merge` will merge this PR after your CI passes on it\n- `@dependabot squash and merge` will squash and merge this PR after your CI passes on it\n- `@dependabot cancel merge` will cancel a previously requested merge and block automerging\n- `@dependabot reopen` will reopen this PR if it is closed\n- `@dependabot close` will close this PR and stop Dependabot recreating it. You can achieve the same result by closing it manually\n- `@dependabot ignore this major version` will close this PR and stop Dependabot creating any more for this major version (unless you reopen the PR or upgrade to it yourself)\n- `@dependabot ignore this minor version` will close this PR and stop Dependabot creating any more for this minor version (unless you reopen the PR or upgrade to it yourself)\n- `@dependabot ignore this dependency` will close this PR and stop Dependabot creating any more for this dependency (unless you reopen the PR or upgrade to it yourself)\n\n\n</details>",
    "created_at": "2020-09-21T06:41:19Z",
    "updated_at": "2020-09-21T06:41:20Z",
    "closed_at": null,
    "merged_at": null,
    "merge_commit_sha": "ef9ca6ba4ecab09b2f4f45f24a1dc36df80bdddf",
    "assignee": null,
    "assignees": [

    ],
    "requested_reviewers": [

    ],
    "requested_teams": [

    ],
    "labels": [
        {
        "id": 1513162334,
        "node_id": "MDU6TGFiZWwxNTEzMTYyMzM0",
        "url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/labels/dependencies",
        "name": "dependencies",
        "color": "0366d6",
        "default": false,
        "description": "Pull requests that update a dependency file"
        }
    ],
    "milestone": null,
    "draft": false,
    "commits_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls/161/commits",
    "review_comments_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls/161/comments",
    "review_comment_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls/comments{/number}",
    "comments_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues/161/comments",
    "statuses_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/statuses/d97948ea645f9ca9b5463aef1931f15b29f7d484",
    "head": {
        "label": "corvus-dotnet:dependabot/nuget/Solutions/Microsoft.NET.Test.Sdk-16.7.1",
        "ref": "dependabot/nuget/Solutions/Microsoft.NET.Test.Sdk-16.7.1",
        "sha": "d97948ea645f9ca9b5463aef1931f15b29f7d484",
        "user": {
        "login": "corvus-dotnet",
        "id": 53255440,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMjU1NDQw",
        "avatar_url": "https://avatars2.githubusercontent.com/u/53255440?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/corvus-dotnet",
        "html_url": "https://github.com/corvus-dotnet",
        "followers_url": "https://api.github.com/users/corvus-dotnet/followers",
        "following_url": "https://api.github.com/users/corvus-dotnet/following{/other_user}",
        "gists_url": "https://api.github.com/users/corvus-dotnet/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/corvus-dotnet/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/corvus-dotnet/subscriptions",
        "organizations_url": "https://api.github.com/users/corvus-dotnet/orgs",
        "repos_url": "https://api.github.com/users/corvus-dotnet/repos",
        "events_url": "https://api.github.com/users/corvus-dotnet/events{/privacy}",
        "received_events_url": "https://api.github.com/users/corvus-dotnet/received_events",
        "type": "Organization",
        "site_admin": false
        },
        "repo": {
        "id": 203047699,
        "node_id": "MDEwOlJlcG9zaXRvcnkyMDMwNDc2OTk=",
        "name": "Corvus.Leasing",
        "full_name": "corvus-dotnet/Corvus.Leasing",
        "private": false,
        "owner": {
            "login": "corvus-dotnet",
            "id": 53255440,
            "node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMjU1NDQw",
            "avatar_url": "https://avatars2.githubusercontent.com/u/53255440?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/corvus-dotnet",
            "html_url": "https://github.com/corvus-dotnet",
            "followers_url": "https://api.github.com/users/corvus-dotnet/followers",
            "following_url": "https://api.github.com/users/corvus-dotnet/following{/other_user}",
            "gists_url": "https://api.github.com/users/corvus-dotnet/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/corvus-dotnet/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/corvus-dotnet/subscriptions",
            "organizations_url": "https://api.github.com/users/corvus-dotnet/orgs",
            "repos_url": "https://api.github.com/users/corvus-dotnet/repos",
            "events_url": "https://api.github.com/users/corvus-dotnet/events{/privacy}",
            "received_events_url": "https://api.github.com/users/corvus-dotnet/received_events",
            "type": "Organization",
            "site_admin": false
        },
        "html_url": "https://github.com/corvus-dotnet/Corvus.Leasing",
        "description": "Leasing patterns for mediating access to exclusive resources in distributed processes. A generic abstraction, with an Azure blob-based implementation.",
        "fork": false,
        "url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing",
        "forks_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/forks",
        "keys_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/teams",
        "hooks_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/hooks",
        "issue_events_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues/events{/number}",
        "events_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/events",
        "assignees_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/assignees{/user}",
        "branches_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/branches{/branch}",
        "tags_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/tags",
        "blobs_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/languages",
        "stargazers_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/stargazers",
        "contributors_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/contributors",
        "subscribers_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/subscribers",
        "subscription_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/subscription",
        "commits_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/contents/{+path}",
        "compare_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/merges",
        "archive_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/downloads",
        "issues_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues{/number}",
        "pulls_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/labels{/name}",
        "releases_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/releases{/id}",
        "deployments_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/deployments",
        "created_at": "2019-08-18T19:29:59Z",
        "updated_at": "2020-09-21T06:49:48Z",
        "pushed_at": "2020-09-21T06:56:21Z",
        "git_url": "git://github.com/corvus-dotnet/Corvus.Leasing.git",
        "ssh_url": "git@github.com:corvus-dotnet/Corvus.Leasing.git",
        "clone_url": "https://github.com/corvus-dotnet/Corvus.Leasing.git",
        "svn_url": "https://github.com/corvus-dotnet/Corvus.Leasing",
        "homepage": "",
        "size": 147,
        "stargazers_count": 0,
        "watchers_count": 0,
        "language": "C#",
        "has_issues": true,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 0,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 24,
        "license": {
            "key": "apache-2.0",
            "name": "Apache License 2.0",
            "spdx_id": "Apache-2.0",
            "url": "https://api.github.com/licenses/apache-2.0",
            "node_id": "MDc6TGljZW5zZTI="
        },
        "forks": 0,
        "open_issues": 24,
        "watchers": 0,
        "default_branch": "master"
        }
    },
    "base": {
        "label": "corvus-dotnet:master",
        "ref": "master",
        "sha": "e3954d6bb044dba5e183b54dfdebf0b8516fff94",
        "user": {
        "login": "corvus-dotnet",
        "id": 53255440,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMjU1NDQw",
        "avatar_url": "https://avatars2.githubusercontent.com/u/53255440?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/corvus-dotnet",
        "html_url": "https://github.com/corvus-dotnet",
        "followers_url": "https://api.github.com/users/corvus-dotnet/followers",
        "following_url": "https://api.github.com/users/corvus-dotnet/following{/other_user}",
        "gists_url": "https://api.github.com/users/corvus-dotnet/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/corvus-dotnet/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/corvus-dotnet/subscriptions",
        "organizations_url": "https://api.github.com/users/corvus-dotnet/orgs",
        "repos_url": "https://api.github.com/users/corvus-dotnet/repos",
        "events_url": "https://api.github.com/users/corvus-dotnet/events{/privacy}",
        "received_events_url": "https://api.github.com/users/corvus-dotnet/received_events",
        "type": "Organization",
        "site_admin": false
        },
        "repo": {
        "id": 203047699,
        "node_id": "MDEwOlJlcG9zaXRvcnkyMDMwNDc2OTk=",
        "name": "Corvus.Leasing",
        "full_name": "corvus-dotnet/Corvus.Leasing",
        "private": false,
        "owner": {
            "login": "corvus-dotnet",
            "id": 53255440,
            "node_id": "MDEyOk9yZ2FuaXphdGlvbjUzMjU1NDQw",
            "avatar_url": "https://avatars2.githubusercontent.com/u/53255440?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/corvus-dotnet",
            "html_url": "https://github.com/corvus-dotnet",
            "followers_url": "https://api.github.com/users/corvus-dotnet/followers",
            "following_url": "https://api.github.com/users/corvus-dotnet/following{/other_user}",
            "gists_url": "https://api.github.com/users/corvus-dotnet/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/corvus-dotnet/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/corvus-dotnet/subscriptions",
            "organizations_url": "https://api.github.com/users/corvus-dotnet/orgs",
            "repos_url": "https://api.github.com/users/corvus-dotnet/repos",
            "events_url": "https://api.github.com/users/corvus-dotnet/events{/privacy}",
            "received_events_url": "https://api.github.com/users/corvus-dotnet/received_events",
            "type": "Organization",
            "site_admin": false
        },
        "html_url": "https://github.com/corvus-dotnet/Corvus.Leasing",
        "description": "Leasing patterns for mediating access to exclusive resources in distributed processes. A generic abstraction, with an Azure blob-based implementation.",
        "fork": false,
        "url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing",
        "forks_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/forks",
        "keys_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/teams",
        "hooks_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/hooks",
        "issue_events_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues/events{/number}",
        "events_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/events",
        "assignees_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/assignees{/user}",
        "branches_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/branches{/branch}",
        "tags_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/tags",
        "blobs_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/languages",
        "stargazers_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/stargazers",
        "contributors_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/contributors",
        "subscribers_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/subscribers",
        "subscription_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/subscription",
        "commits_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/contents/{+path}",
        "compare_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/merges",
        "archive_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/downloads",
        "issues_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues{/number}",
        "pulls_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/labels{/name}",
        "releases_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/releases{/id}",
        "deployments_url": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/deployments",
        "created_at": "2019-08-18T19:29:59Z",
        "updated_at": "2020-09-21T06:49:48Z",
        "pushed_at": "2020-09-21T06:56:21Z",
        "git_url": "git://github.com/corvus-dotnet/Corvus.Leasing.git",
        "ssh_url": "git@github.com:corvus-dotnet/Corvus.Leasing.git",
        "clone_url": "https://github.com/corvus-dotnet/Corvus.Leasing.git",
        "svn_url": "https://github.com/corvus-dotnet/Corvus.Leasing",
        "homepage": "",
        "size": 147,
        "stargazers_count": 0,
        "watchers_count": 0,
        "language": "C#",
        "has_issues": true,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 0,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 24,
        "license": {
            "key": "apache-2.0",
            "name": "Apache License 2.0",
            "spdx_id": "Apache-2.0",
            "url": "https://api.github.com/licenses/apache-2.0",
            "node_id": "MDc6TGljZW5zZTI="
        },
        "forks": 0,
        "open_issues": 24,
        "watchers": 0,
        "default_branch": "master"
        }
    },
    "_links": {
        "self": {
        "href": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls/161"
        },
        "html": {
        "href": "https://github.com/corvus-dotnet/Corvus.Leasing/pull/161"
        },
        "issue": {
        "href": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues/161"
        },
        "comments": {
        "href": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues/161/comments"
        },
        "review_comments": {
        "href": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls/161/comments"
        },
        "review_comment": {
        "href": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls/comments{/number}"
        },
        "commits": {
        "href": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/pulls/161/commits"
        },
        "statuses": {
        "href": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/statuses/d97948ea645f9ca9b5463aef1931f15b29f7d484"
        }
    },
    "author_association": "CONTRIBUTOR",
    "active_lock_reason": null,
    "merged": false,
    "mergeable": true,
    "rebaseable": true,
    "mergeable_state": "clean",
    "merged_by": null,
    "comments": 0,
    "review_comments": 0,
    "maintainer_can_modify": false,
    "commits": 1,
    "additions": 1,
    "deletions": 1,
    "changed_files": 1
}
'@
    $fakeIssue = @'
{
    "_links": {
        "self": {
            "href": "https://api.github.com/repos/corvus-dotnet/Corvus.Leasing/issues/111"
        },
    }
}
'@

    Context 'PrObject ParameterSet - ValueByPipeline' {

        It 'should throw an exception when passing JSON that does not represent a GitHub pull request' {
            $badPr = ConvertFrom-Json $fakeIssue

            { $badPr | Close-GitHubPrWithComment | Should -Throw }
        }

        It 'should run successfully then passing a valid pull request JSON object without a comment' {
            Mock Invoke-GitHubRestRequest {}
            
            $pr = ConvertFrom-Json $testPr
            $pr | Close-GitHubPrWithComment

            Assert-MockCalled Invoke-GitHubRestRequest -Times 1
        }

        It 'should run successfully then passing a valid pull request JSON object with a closing comment' {
            Mock Invoke-GitHubRestRequest {}
            
            $pr = ConvertFrom-Json $testPr
            $pr | Close-GitHubPrWithComment -Comment 'foo'

            Assert-MockCalled Invoke-GitHubRestRequest -Times 2
        }
    }

    Context 'PrObject ParameterSet - ValueByParameter' {
        
        It 'should run successfully then passing a valid pull request JSON object without a comment' {
            Mock Invoke-GitHubRestRequest {}
            
            $pr = ConvertFrom-Json $testPr
            Close-GitHubPrWithComment -InputObject $pr

            Assert-MockCalled Invoke-GitHubRestRequest -Times 1
        }

        It 'should run successfully then passing a valid pull request JSON object with a closing comment' {
            Mock Invoke-GitHubRestRequest {}
            
            $pr = ConvertFrom-Json $testPr
            Close-GitHubPrWithComment -InputObject $pr -Comment 'foo'

            Assert-MockCalled Invoke-GitHubRestRequest -Times 2
        }
    }

    Context 'PrNumber ParameterSet' {
        
        It 'should run successfully then passing a PR number without a comment' {
            Mock Invoke-GitHubRestRequest {}
            
            Close-GitHubPrWithComment -PrNumber 1 -OrgName corvus-dotnet -RepoName Corvus.Retry

            Assert-MockCalled Invoke-GitHubRestRequest -Times 1
        }

        It 'should run successfully then passing a PR number with a comment' {
            Mock Invoke-GitHubRestRequest {}
            
            Close-GitHubPrWithComment -PrNumber 1 -OrgName corvus-dotnet -RepoName Corvus.Retry -Comment 'closed!'

            Assert-MockCalled Invoke-GitHubRestRequest -Times 1
        }
    }
}