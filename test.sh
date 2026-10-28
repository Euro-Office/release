#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/release.sh"

check() { [ "$2" = "$3" ] || { echo "FAIL $1: got '$2', want '$3'"; exit 1; }; }

tags=$'v9.3.5-rc.2\nv9.3.5-rc.1\nv9.3.4-hotfix.1\nv9.3.4\nv99.99.99.4652\nwin-v4.3.0.110\nv9.3.3'
check "rc after rc" "$(previous_tag v9.3.5-rc.3 <<<"$tags")" v9.3.5-rc.2
check "stable after rcs" "$(previous_tag v9.3.5 <<<"$tags")" v9.3.4
check "ignores itself" "$(previous_tag v9.3.5-rc.2 <<<"$tags")" v9.3.5-rc.1
check "numeric suffix" "$(previous_tag v0.0.0-next.1 <<<$'v9.3.5-2\nv9.3.5-1\nv9.3.1')" v9.3.5-2
check "stable after rebuild" "$(previous_tag v9.3.6 <<<$'v9.3.6-rc.1\nv9.3.5-2\nv9.3.5-1\nv9.3.1')" v9.3.5-2
check "patch build" "$(previous_tag v9.3.7-1 <<<$'v9.3.7\nv9.3.7-rc.1\nv9.3.6')" v9.3.7
check "second patch build" "$(previous_tag v9.3.7-2 <<<$'v9.3.7-1\nv9.3.7\nv9.3.7-rc.1')" v9.3.7-1
check "patch build branch" "$(release_branch 9.3.7-1)" stable-9.3.7
if ! { is_patch v9.3.7-1 && ! is_patch v9.3.7 && ! is_patch v9.3.7-rc.1; }; then echo "FAIL is_patch"; exit 1; fi
check "no previous" "$(previous_tag v1.0.0 <<<"")" ""
if (check_shared <(printf 'a/core 1\na/core 2\na/sdkjs 3\n')) 2>/dev/null; then echo "FAIL check_shared mismatch"; exit 1; fi
check_shared <(printf 'a/core 1\na/sdkjs 3\n')
check "release branch" "$(release_branch 9.3.6-rc.2)" stable-9.3.6
check "slug https" "$(slug https://github.com/Euro-Office/core.git)" Euro-Office/core
check "slug ssh" "$(slug git@github.com:Euro-Office/core)" Euro-Office/core
if ! { valid_version 9.3.6 && valid_version 9.3.6-rc.1 && valid_version 9.3.7-1 && valid_version 9.3.7-12 && valid_version 9.3.7-beta.1 &&
  ! valid_version v9.3.6 && ! valid_version 9.3 && ! valid_version 9.3.7-0 && ! valid_version 9.3.7-01 && ! valid_version 9.3.7-1-rc.1; }; then
  echo "FAIL valid_version"; exit 1
fi
prs=$'web-apps\tfeat(chat): add mentions by @a in https://github.com/Euro-Office/web-apps/pull/1
core\tfix: crash on open by @b in https://github.com/Euro-Office/core/pull/2
server\tfeat!: drop node 18 by @c in https://github.com/Euro-Office/server/pull/3
web-apps\ti18n(da): Danish review by @d in https://github.com/Euro-Office/web-apps/pull/4
web-apps\tRemove Google Analytics by @e in https://github.com/Euro-Office/web-apps/pull/5
core\tchore(deps): bump x by @f in https://github.com/Euro-Office/core/pull/6
web-apps\tfix(deps): update svgo by @g in https://github.com/Euro-Office/web-apps/pull/7'
want='### Breaking changes

* server: drop node 18 by @c in https://github.com/Euro-Office/server/pull/3

### Features

* web-apps: chat: add mentions by @a in https://github.com/Euro-Office/web-apps/pull/1

### Bug fixes

* core: crash on open by @b in https://github.com/Euro-Office/core/pull/2

### Other changes

* web-apps: i18n(da): Danish review by @d in https://github.com/Euro-Office/web-apps/pull/4
* web-apps: Remove Google Analytics by @e in https://github.com/Euro-Office/web-apps/pull/5
* core: chore(deps): bump x by @f in https://github.com/Euro-Office/core/pull/6
* web-apps: fix(deps): update svgo by @g in https://github.com/Euro-Office/web-apps/pull/7'
check "group_notes" "$(group_notes <<<"$prs")" "$want"
check "pr_links" "$(pr_links <<<'* core: fix crash by @renovate[bot] in https://github.com/Euro-Office/DocumentServer/pull/420')" '* core: fix crash by renovate[bot] in [DocumentServer#420](https://github.com/Euro-Office/DocumentServer/pull/420)'
check "group_notes empty" "$(group_notes </dev/null)" ""
tmp=$(mktemp -d)
printf '# Change log\n\n## 9.3.5\n\n* old\n' >"$tmp/CHANGELOG.md"
printf '## v9.3.6\n\n* new\n' >"$tmp/section"
prepend_changelog "$tmp/CHANGELOG.md" "$tmp/section"
check "keeps existing header" "$(cat "$tmp/CHANGELOG.md")" $'# Change log\n\n## v9.3.6\n\n* new\n## 9.3.5\n\n* old'
rm "$tmp/CHANGELOG.md"
prepend_changelog "$tmp/CHANGELOG.md" "$tmp/section"
check "new changelog" "$(cat "$tmp/CHANGELOG.md")" $'# Changelog\n\n## v9.3.6\n\n* new'
rm -r "$tmp"
tmp=$(mktemp -d)
mkdir -p "$tmp"/desktopeditors/{9.3.5/2,9.3.6/0,9.3.7/0~rc.1} "$tmp"/docserver/9.3.6/0
(cd "$tmp/desktopeditors/9.3.6/0" && touch Nextcloud-Office-DesktopEditors-9.3.6-0-{windows-x64.exe,windows-arm64.exe,macos-arm64.dmg} \
	nextcloud-office-nextcloudoffice_9.3.6-0_{amd64,arm64}.deb nextcloud-office-nextcloudoffice-9.3.6-0.{x86_64,aarch64}.rpm \
	nextcloud-office-nextcloudoffice-9.3.6-0-{x86_64,aarch64}.tar.xz)
OFFICE_ROOT=$tmp scripts/update-latest-symlink.sh >/dev/null
check "desktop latest" "$(readlink "$tmp/desktopeditors/latest")" 9.3.6/0
check "desktop fixed link" "$(readlink "$tmp/desktopeditors/Nextcloud-Office-DesktopEditors-latest-macos-arm64.dmg")" 9.3.6/0/Nextcloud-Office-DesktopEditors-9.3.6-0-macos-arm64.dmg
check "linux fixed link" "$(readlink "$tmp/desktopeditors/Nextcloud-Office-DesktopEditors-latest-linux-arm64.deb")" 9.3.6/0/nextcloud-office-nextcloudoffice_9.3.6-0_arm64.deb
check "docserver latest" "$(readlink "$tmp/docserver/latest")" 9.3.6/0
mkdir -p "$tmp"/desktopeditors/9.3.7/0 "$tmp"/docserver/9.3.7/0
touch "$tmp/desktopeditors/9.3.7/0/Nextcloud-Office-DesktopEditors-9.3.7-0-windows-x64.exe"
if OFFICE_ROOT=$tmp scripts/update-latest-symlink.sh >/dev/null 2>&1; then echo "FAIL missing packages pass"; exit 1; fi
check "desktop keeps latest" "$(readlink "$tmp/desktopeditors/latest")" 9.3.6/0
check "docserver moves on" "$(readlink "$tmp/docserver/latest")" 9.3.7/0
mkdir -p "$tmp"/docserver/9.3.7/1
OFFICE_ROOT=$tmp scripts/update-latest-symlink.sh >/dev/null 2>&1 || true
check "docserver patch build" "$(readlink "$tmp/docserver/latest")" 9.3.7/1
rm -r "$tmp"
echo ok
