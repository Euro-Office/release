# Euro-Office release

Releases DocumentServer and DesktopEditors with one version and tags it across all submodules.

## Releasing

A version (`9.3.6`) is released in rounds: one or more release candidates (`9.3.6-rc.1`, `9.3.6-rc.2`) and the final release. Each round:

1. Run **Release issue** with the version. The first round opens the `Release 9.3.6` issue that tracks blockers and the milestone ([template](.github/release/issue.md)); every round adds its [checklist](.github/release/round.md) as a comment. Follow that checklist.
2. Run **Prepare release** with the version. It pins every submodule to its latest default-branch commit, or from the second round on to the latest commit of `stable-9.3.6` (shared submodules get the same commit in both products), bumps `VERSION` / `VERSION.txt`, prepends `CHANGELOG.md` and opens a `release/v<version>` PR in each product. The PR builds are the ones to QA.
3. Review and merge the release PRs.
4. Run **Tag release** with the same version and approve the `release` environment. It checks the merged PRs and that shared submodules match, then tags every submodule and finally the products, which starts their builds. The first tag of a version also creates `stable-9.3.6` at the tagged commit in every repo.
5. The tag builds publish the GitHub releases, images and packages: rc tags as prereleases, the final tag as latest. The Nextcloud Office desktop installers still have to be signed and uploaded by hand.

Later rounds only get what is backported: merge a fix on `main` first, then comment `/backport to stable-9.3.6` on the merged PR. `main` keeps its own `VERSION` and `CHANGELOG.md`; the tags and GitHub releases carry the notes of the rounds released from the branch.

Turn off `bump_submodules` to keep the submodule commits the products already point at (`--no-bump` locally); `tag` still checks that shared submodules match.

`products` limits a release to `ds` or `de`. The skipped product does not get that version.

### Hotfixes

A hotfix of a released version is the next patch version, released from a branch of the previous one and usually without rc rounds. For a hotfix of 9.3.6:

1. Create `stable-9.3.7` at the head of `stable-9.3.6` in both products and every submodule:
   ```sh
   for repo in DocumentServer DesktopEditors $(for p in DocumentServer DesktopEditors; do
       gh api "repos/Euro-Office/$p/contents/.gitmodules" -H 'Accept: application/vnd.github.raw'
     done | sed -nE 's#.*github\.com/Euro-Office/([^/]+)\.git$#\1#p' | sort -u); do
     sha=$(gh api "repos/Euro-Office/$repo/git/ref/heads/stable-9.3.6" --jq .object.sha) &&
       gh api "repos/Euro-Office/$repo/git/refs" -f ref=refs/heads/stable-9.3.7 -f sha="$sha" >/dev/null &&
       echo "$repo: created stable-9.3.7 at $sha"
   done
   ```
2. Merge the fix on `main` and comment `/backport to stable-9.3.7` on the merged PR.
3. Release `9.3.7` as above. Since `stable-9.3.7` exists, prepare pins from it, the release PRs target it and the changelog covers the changes since `v9.3.6`.

The next feature release from `main` then becomes 9.3.8 or 9.4.0. Suffixes do not work for hotfixes: `9.3.6-hotfix.1` and `9.3.6-1` build as prereleases with the package version `9.3.6-0~…`, which apt and dnf sort before `9.3.6-0`, and `9.3.6.1` is no valid tag for the builds.

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
