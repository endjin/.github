$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

ipmo Endjin.CodeOps

Describe "Applying standard GitHub settings" {

    Context "Merging settings overrides" {

        $repoYaml = @'
repos:
- org: endjin
  name: dependency-playground
  githubSettings:
    delete_branch_on_merge: true
    master_branch_protection: false
'@

        $configDir = Join-Path TestDrive:/ 'repo'
        mkdir $configDir
        set-content -Path $configDir/test.yml -Value $repoYaml
        $repos = [array](Get-AllRepoConfiguration -ConfigDirectory $configDir -LocalMode | Where-Object { $_ })
        $allReposJson = @'
[
    {
        "id": 279609519,
        "node_id": "MDEwOlJlcG9zaXRvcnkyNzk2MDk1MTk=",
        "name": "dependency-playground",
        "full_name": "endjin/dependency-playground",
        "private": false,
        "owner": {
            "login": "endjin",
            "id": 402568,
            "node_id": "MDEyOk9yZ2FuaXphdGlvbjQwMjU2OA==",
            "avatar_url": "https://avatars.githubusercontent.com/u/402568?v=4",
            "gravatar_id": "",
            "url": "https://api.github.com/users/endjin",
            "html_url": "https://github.com/endjin",
            "followers_url": "https://api.github.com/users/endjin/followers",
            "following_url": "https://api.github.com/users/endjin/following{/other_user}",
            "gists_url": "https://api.github.com/users/endjin/gists{/gist_id}",
            "starred_url": "https://api.github.com/users/endjin/starred{/owner}{/repo}",
            "subscriptions_url": "https://api.github.com/users/endjin/subscriptions",
            "organizations_url": "https://api.github.com/users/endjin/orgs",
            "repos_url": "https://api.github.com/users/endjin/repos",
            "events_url": "https://api.github.com/users/endjin/events{/privacy}",
            "received_events_url": "https://api.github.com/users/endjin/received_events",
            "type": "Organization",
            "site_admin": false
        },
        "html_url": "https://github.com/endjin/dependency-playground",
        "description": null,
        "fork": false,
        "url": "https://api.github.com/repos/endjin/dependency-playground",
        "forks_url": "https://api.github.com/repos/endjin/dependency-playground/forks",
        "keys_url": "https://api.github.com/repos/endjin/dependency-playground/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/endjin/dependency-playground/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/endjin/dependency-playground/teams",
        "hooks_url": "https://api.github.com/repos/endjin/dependency-playground/hooks",
        "issue_events_url": "https://api.github.com/repos/endjin/dependency-playground/issues/events{/number}",
        "events_url": "https://api.github.com/repos/endjin/dependency-playground/events",
        "assignees_url": "https://api.github.com/repos/endjin/dependency-playground/assignees{/user}",
        "branches_url": "https://api.github.com/repos/endjin/dependency-playground/branches{/branch}",
        "tags_url": "https://api.github.com/repos/endjin/dependency-playground/tags",
        "blobs_url": "https://api.github.com/repos/endjin/dependency-playground/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/endjin/dependency-playground/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/endjin/dependency-playground/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/endjin/dependency-playground/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/endjin/dependency-playground/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/endjin/dependency-playground/languages",
        "stargazers_url": "https://api.github.com/repos/endjin/dependency-playground/stargazers",
        "contributors_url": "https://api.github.com/repos/endjin/dependency-playground/contributors",
        "subscribers_url": "https://api.github.com/repos/endjin/dependency-playground/subscribers",
        "subscription_url": "https://api.github.com/repos/endjin/dependency-playground/subscription",
        "commits_url": "https://api.github.com/repos/endjin/dependency-playground/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/endjin/dependency-playground/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/endjin/dependency-playground/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/endjin/dependency-playground/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/endjin/dependency-playground/contents/{+path}",
        "compare_url": "https://api.github.com/repos/endjin/dependency-playground/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/endjin/dependency-playground/merges",
        "archive_url": "https://api.github.com/repos/endjin/dependency-playground/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/endjin/dependency-playground/downloads",
        "issues_url": "https://api.github.com/repos/endjin/dependency-playground/issues{/number}",
        "pulls_url": "https://api.github.com/repos/endjin/dependency-playground/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/endjin/dependency-playground/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/endjin/dependency-playground/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/endjin/dependency-playground/labels{/name}",
        "releases_url": "https://api.github.com/repos/endjin/dependency-playground/releases{/id}",
        "deployments_url": "https://api.github.com/repos/endjin/dependency-playground/deployments",
        "created_at": "2020-07-14T14:33:57Z",
        "updated_at": "2020-12-03T14:12:51Z",
        "pushed_at": "2020-12-03T14:12:48Z",
        "git_url": "git://github.com/endjin/dependency-playground.git",
        "ssh_url": "git@github.com:endjin/dependency-playground.git",
        "clone_url": "https://github.com/endjin/dependency-playground.git",
        "svn_url": "https://github.com/endjin/dependency-playground",
        "homepage": null,
        "size": 8881,
        "stargazers_count": 0,
        "watchers_count": 0,
        "language": "C#",
        "has_issues": true,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 2,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 2,
        "license": null,
        "forks": 2,
        "open_issues": 2,
        "watchers": 0,
        "default_branch": "master",
        "permissions": {
            "admin": false,
            "push": false,
            "pull": false
        }
    },
    {
        "id": 280094183,
        "node_id": "MDEwOlJlcG9zaXRvcnkyODAwOTQxODM=",
        "name": "modern-data-platform",
        "full_name": "endjin/modern-data-platform",
        "private": true,
        "owner": {
        "login": "endjin",
        "id": 402568,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjQwMjU2OA==",
        "avatar_url": "https://avatars.githubusercontent.com/u/402568?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/endjin",
        "html_url": "https://github.com/endjin",
        "followers_url": "https://api.github.com/users/endjin/followers",
        "following_url": "https://api.github.com/users/endjin/following{/other_user}",
        "gists_url": "https://api.github.com/users/endjin/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/endjin/starred{/owner}{/repo}",  
        "subscriptions_url": "https://api.github.com/users/endjin/subscriptions",     
        "organizations_url": "https://api.github.com/users/endjin/orgs",
        "repos_url": "https://api.github.com/users/endjin/repos",
        "events_url": "https://api.github.com/users/endjin/events{/privacy}",
        "received_events_url": "https://api.github.com/users/endjin/received_events",
        "type": "Organization",
        "site_admin": false
        },
        "html_url": "https://github.com/endjin/modern-data-platform",
        "description": "Assets for the MDP blueprints",
        "fork": false,
        "url": "https://api.github.com/repos/endjin/modern-data-platform",
        "forks_url": "https://api.github.com/repos/endjin/modern-data-platform/forks",
        "keys_url": "https://api.github.com/repos/endjin/modern-data-platform/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/endjin/modern-data-platform/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/endjin/modern-data-platform/teams",
        "hooks_url": "https://api.github.com/repos/endjin/modern-data-platform/hooks",
        "issue_events_url": "https://api.github.com/repos/endjin/modern-data-platform/issues/events{/number}",
        "events_url": "https://api.github.com/repos/endjin/modern-data-platform/events",
        "assignees_url": "https://api.github.com/repos/endjin/modern-data-platform/assignees{/user}",
        "branches_url": "https://api.github.com/repos/endjin/modern-data-platform/branches{/branch}",
        "tags_url": "https://api.github.com/repos/endjin/modern-data-platform/tags",
        "blobs_url": "https://api.github.com/repos/endjin/modern-data-platform/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/endjin/modern-data-platform/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/endjin/modern-data-platform/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/endjin/modern-data-platform/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/endjin/modern-data-platform/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/endjin/modern-data-platform/languages",
        "stargazers_url": "https://api.github.com/repos/endjin/modern-data-platform/stargazers",
        "contributors_url": "https://api.github.com/repos/endjin/modern-data-platform/contributors",
        "subscribers_url": "https://api.github.com/repos/endjin/modern-data-platform/subscribers",
        "subscription_url": "https://api.github.com/repos/endjin/modern-data-platform/subscription",
        "commits_url": "https://api.github.com/repos/endjin/modern-data-platform/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/endjin/modern-data-platform/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/endjin/modern-data-platform/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/endjin/modern-data-platform/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/endjin/modern-data-platform/contents/{+path}",
        "compare_url": "https://api.github.com/repos/endjin/modern-data-platform/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/endjin/modern-data-platform/merges",
        "archive_url": "https://api.github.com/repos/endjin/modern-data-platform/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/endjin/modern-data-platform/downloads",
        "issues_url": "https://api.github.com/repos/endjin/modern-data-platform/issues{/number}",
        "pulls_url": "https://api.github.com/repos/endjin/modern-data-platform/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/endjin/modern-data-platform/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/endjin/modern-data-platform/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/endjin/modern-data-platform/labels{/name}",
        "releases_url": "https://api.github.com/repos/endjin/modern-data-platform/releases{/id}",
        "deployments_url": "https://api.github.com/repos/endjin/modern-data-platform/deployments",
        "created_at": "2020-07-16T08:12:02Z",
        "updated_at": "2021-02-05T01:22:16Z",
        "pushed_at": "2021-02-10T17:50:50Z",
        "git_url": "git://github.com/endjin/modern-data-platform.git",
        "ssh_url": "git@github.com:endjin/modern-data-platform.git",
        "clone_url": "https://github.com/endjin/modern-data-platform.git",
        "svn_url": "https://github.com/endjin/modern-data-platform",
        "homepage": null,
        "size": 3670,
        "stargazers_count": 1,
        "watchers_count": 1,
        "language": "PowerShell",
        "has_issues": true,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 0,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 21,
        "license": null,
        "forks": 0,
        "open_issues": 21,
        "watchers": 1,
        "default_branch": "master",
        "permissions": {
        "admin": false,
        "push": false,
        "pull": false
        }
    }
]
'@

        Mock _getAllOrgs { @("endjin") }
        Mock _getAllOrgRepos { $allReposJson | ConvertFrom-Json -Depth 30 -AsHashtable }

        # $defaultSettings = @{
        #     delete_branch_on_merge = $true
        #     master_branch_protection = $true
        # }

        # $allRepos = $allReposJson | ConvertFrom-Json -Depth 30 -AsHashtable
        # $reposToProcess = @{}
        # $allRepos | % { $reposToProcess += @{ "$($_.name)" = $defaultSettings } }

        # # update $reposToProcess with any overridden 'githubSettings' defined in the yaml files
        # $repos | `
        #     ? { $_.org -eq 'endjin' } | `
        #     ? { $_.ContainsKey("githubSettings") } | `
        #     % {
        #         $settings = $_.githubSettings
        #         $repoName = $_.name
        #         $settings.Keys | % { $reposToProcess[$repoName].$_ = $settings[$_] }
        #     }
        # $reposToProcess | convertto-json -Depth 30
    }
}