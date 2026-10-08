# Euro-Office release

Releases DocumentServer and DesktopEditors with one version and tags it across all submodules.

1. Run **Prepare release** with a version (`9.3.6-rc.1`). It pins every submodule to its latest default-branch commit (shared submodules get the same commit in both products), bumps `VERSION` / `VERSION.txt`, prepends `CHANGELOG.md` and opens a `release/v<version>` PR in each product.
2. Review and merge the release PRs.
3. Run **Tag release** with the same version. It checks the merged PRs and that shared submodules match, then tags every submodule and finally the products, which starts their builds.

`products` limits a release to `ds` or `de`. The skipped product does not get that version.

## Local use

```sh
./release.sh prepare 9.3.6-rc.1 --dry-run
./release.sh tag 9.3.6-rc.1 --dry-run
./release.sh check   # token has write access to every repo involved, changes nothing
./test.sh
```

Needs `git` and `gh` with write access to all involved repositories.

## Setup

- Secret `EO_ROBOT_GITHUB_TOKEN` (org secret available to this repository): a token with contents and pull requests write access to both products and all submodules
- Environment `release` with required reviewers for the tag workflow
