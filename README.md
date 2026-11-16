# Euro-Office release

Releases DocumentServer and DesktopEditors with one version and tags it across all submodules.

## Releasing

We follow [semantic versioning](https://semver.org). `main` builds the next minor or major version (9.4.0) with features. Each minor version gets one long-lived `stable-X.Y` branch (`stable-9.3`) that only gets backported fixes, so its patch releases (9.3.9, 9.3.10) stay fix-only. We maintain the newest line and the previous one: fixes go to the newest by default, security and important bug fixes also to the previous one.

A version (`9.4.0`) is released in rounds: one or more release candidates (`9.4.0-rc.1`, `9.4.0-rc.2`) and the final release, later maybe [patch builds](#patch-builds) (`9.4.0-1`). Each round:

1. Run **Release issue** with the version. The first round opens the `Release 9.4.0` issue that tracks blockers and the milestone ([template](.github/release/issue.md)); every round adds its [checklist](.github/release/round.md) as a comment. Follow that checklist.
2. Run **Prepare release** with the version. It pins every submodule to the latest commit of `stable-9.4`, or of the default branch while that branch does not exist yet (shared submodules get the same commit in both products), bumps `VERSION` / `VERSION.txt`, prepends `CHANGELOG.md` and opens a `release/v<version>` PR in each product. The PR builds are the ones to QA.
3. Review and merge the release PRs.
4. Run **Tag release** with the same version and approve the `release` environment. It checks the merged PRs and that shared submodules match, then tags every submodule and finally the products, which starts their builds. The first tag of a minor version (`9.4.0-rc.1`) also creates `stable-9.4` at the tagged commit in every repo.
5. The tag builds publish the GitHub releases, images and packages: rc tags as prereleases, final tags as stable. Only the highest stable version becomes latest. The Nextcloud Office desktop installers still have to be signed and uploaded by hand.

Everything after the first round only gets what is backported: merge a fix on `main` first (label it `backport-request` so it is not forgotten), then comment `/backport to stable-9.4` on the merged PR. The release PRs of these rounds target the branch, so **Tag release** opens a `forward-port/v<version>` PR on `main` with the round's `CHANGELOG.md` section. `main` keeps its own version. Locally: `./release.sh forward-port 9.4.0 --dry-run`.

The changelog covers the changes since the highest release below the version, so a 9.3.10 after 9.4.0 lists the changes since 9.3.9.

Turn off `bump_submodules` to keep the submodule commits the products already point at (`--no-bump` locally); `tag` still checks that shared submodules match.

`products` limits a release to `ds` or `de`. The skipped product does not get that version.

### Patch versions

A patch version (`9.3.9`) is released from `stable-9.3` like any round, usually without rc rounds: backport the fixes, then release it. Prepare refuses a patch version without its `stable-X.Y` branch. Letter suffixes like `9.3.9-hotfix.1` build as prereleases (`9.3.9-0~hotfix.1`), which apt and dnf sort before `9.3.9-0`.

### Patch builds

Dependency bumps and small fixes of the newest patch version of a line can ship as a patch build instead of a new patch version: `9.3.9-1` is build number 1 of 9.3.9 (`9.3.9` itself is build 0).

| | 9.3.9 | 9.3.9-1 |
|---|---|---|
| deb/rpm | `9.3.9-0` | `9.3.9-1` |
| Windows | `9.3.9.0` | `9.3.9.1` |
| download dir | `9.3.9/0` | `9.3.9/1` |

1. Backport the changes to `stable-9.3` (`/backport to stable-9.3`).
2. Release `9.3.9-1` as above, without rc rounds: QA the release PR builds. Prepare pins from `stable-9.3` and the changelog covers the changes since `v9.3.9`. The build is stable: APT/DNF and releases, `latest` only if it is the highest stable version.

`9.3.9-0` and prereleases of patch builds (`9.3.9-1-rc.1`) are rejected, both would sort wrong. Once 9.3.10 shipped, `9.3.9-2` is no longer possible. Use a new patch version (9.3.10) for fixes users should notice.

### Creating a stable branch by hand

`stable-9.3` predates this flow and was created by hand from `stable-9.3.8`, in both products and every submodule:

```sh
for repo in DocumentServer DesktopEditors $(for p in DocumentServer DesktopEditors; do
    gh api "repos/Euro-Office/$p/contents/.gitmodules" -H 'Accept: application/vnd.github.raw'
  done | sed -nE 's#.*github\.com/Euro-Office/([^/]+)\.git$#\1#p' | sort -u); do
  sha=$(gh api "repos/Euro-Office/$repo/git/ref/heads/stable-9.3.8" --jq .object.sha) &&
    gh api "repos/Euro-Office/$repo/git/refs" -f ref=refs/heads/stable-9.3 -f sha="$sha" >/dev/null &&
    echo "$repo: created stable-9.3 at $sha"
done
```

## Local use

Release through the workflows above, not from a local checkout: they run with the robot token and the tag workflow needs an approval. Locally, use `release.sh` for dry runs, the pending changelog and tests.

```sh
./release.sh prepare 9.3.6-rc.1 --dry-run
./release.sh tag 9.3.6-rc.1 --dry-run
./release.sh notes   # changelog of the next release, also posted nightly to issue #4
./release.sh check   # token has write access to every repo involved, changes nothing
./test.sh
```

Needs `git` and `gh` with write access to all involved repositories.

## Setup

- Secret `EO_ROBOT_GITHUB_TOKEN` (org secret available to this repository): a token with contents and pull requests write access to both products and all submodules
- Environment `release` with required reviewers for the tag workflow
