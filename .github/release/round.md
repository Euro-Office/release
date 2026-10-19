## v{{VERSION}}

When releasing a single product (`products: ds|de`), skip the other product's items.

### Prepare

- [ ] [Prepare release](https://github.com/Euro-Office/release/actions/workflows/prepare.yml) with `{{VERSION}}`
- [ ] CI is green on the release PRs of [DocumentServer](https://github.com/Euro-Office/DocumentServer/pulls?q=head%3Arelease%2Fv{{VERSION}}) and [DesktopEditors](https://github.com/Euro-Office/DesktopEditors/pulls?q=head%3Arelease%2Fv{{VERSION}})
- [ ] QA the PR builds (linked in the PR comments): packages on the supported distributions, Docker image, desktop installers
- [ ] Blockers are fixed or moved
- [ ] Approve and merge both release PRs

### Tag

- [ ] [Tag release](https://github.com/Euro-Office/release/actions/workflows/tag.yml) with `{{VERSION}}`, approve the `release` environment deployment
- [ ] Tag builds are green: [DocumentServer](https://github.com/Euro-Office/DocumentServer/actions/workflows/build.yml?query=branch%3Av{{VERSION}}), [DesktopEditors](https://github.com/Euro-Office/DesktopEditors/actions/workflows/build.yml?query=branch%3Av{{VERSION}})

A rebuild re-runs the build of the same tag. A content change needs a new version.

### Sign DesktopEditors

Take the artifacts from the DesktopEditors tag build, not from the PR build.

- [ ] Windows: paste the URLs of `windows-signing-bundle-nextcloud-office-amd64` and `-arm64` into brander (one at a time), queue signing and download the installers
- [ ] macOS: paste the URL of `macos-packages-nextcloud-office-arm64` into brander, queue signing and download the DMG
- [ ] Upload them over the unsigned ones, keeping the names brander gives them (`Nextcloud-Office-DesktopEditors-{{BASE}}-{{BUILD}}-windows-x64.exe`, `-windows-arm64.exe`, `-macos-arm64.dmg`): `scp *.exe *.dmg office_uploader@download.nextcloud.com:/var/www/html/office/desktopeditors/{{BASE}}/{{BUILD}}/`
- [ ] Replace the unsigned `.exe`/`.dmg` on [nextcloud-releases/Office-DesktopEditors](https://github.com/nextcloud-releases/Office-DesktopEditors/releases/tag/v{{VERSION}}): `gh release upload --clobber v{{VERSION}} -R nextcloud-releases/Office-DesktopEditors *.exe *.dmg`
- [ ] Add the changelog to both DesktopEditors releases (until the build adds it)
- [ ] Final release only: `ssh office_uploader@download.nextcloud.com bash /home/office_uploader/update-latest-symlink.sh` (rc builds never become `latest`). It refuses to move the desktop editors while a signed package is missing

### Verify

- [ ] GitHub releases exist with changelog, as prerelease for an rc and as latest for the final release: [Euro-Office/DocumentServer](https://github.com/Euro-Office/DocumentServer/releases/tag/v{{VERSION}}), [Euro-Office/DesktopEditors](https://github.com/Euro-Office/DesktopEditors/releases/tag/v{{VERSION}}), [nextcloud-releases/Office-DocumentServer](https://github.com/nextcloud-releases/Office-DocumentServer/releases/tag/v{{VERSION}}), [nextcloud-releases/Office-DesktopEditors](https://github.com/nextcloud-releases/Office-DesktopEditors/releases/tag/v{{VERSION}})
- [ ] Images are pushed: `ghcr.io/euro-office/documentserver:v{{VERSION}}`, `ghcr.io/nextcloud-releases/office-documentserver:v{{VERSION}}` (final release: `:latest` too)
- [ ] Files are on the download server: `ssh office_uploader@download.nextcloud.com ls /var/www/html/office/{docserver,desktopeditors}/{{BASE}}/{{BUILD}}`
- [ ] Final release only: the APT/DNF repositories serve {{VERSION}}
- [ ] rc only: post the release in the team chat and Matrix and ask for testing
