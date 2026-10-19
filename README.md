# Euro-Office release

Releases DocumentServer and DesktopEditors with one version and tags it across all submodules.

## Releasing

A version (`9.3.6`) is released in rounds: one or more release candidates (`9.3.6-rc.1`, `9.3.6-rc.2`) and the final release. Each round:

1. Run **Release issue** with the version. The first round opens the `Release 9.3.6` issue that tracks blockers and the milestone ([template](.github/release/issue.md)); every round adds its [checklist](.github/release/round.md) as a comment. Follow that checklist.
2. Run **Prepare release** with the version. It pins every submodule to its latest default-branch commit (shared submodules get the same commit in both products), bumps `VERSION` / `VERSION.txt`, prepends `CHANGELOG.md` and opens a `release/v<version>` PR in each product. The PR builds are the ones to QA.
3. Review and merge the release PRs.
4. Run **Tag release** with the same version and approve the `release` environment. It checks the merged PRs and that shared submodules match, then tags every submodule and finally the products, which starts their builds.
5. The tag builds publish the GitHub releases, images and packages: rc tags as prereleases, the final tag as latest. The Nextcloud Office desktop installers still have to be signed and uploaded by hand.

`products` limits a release to `ds` or `de`. The skipped product does not get that version.

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
