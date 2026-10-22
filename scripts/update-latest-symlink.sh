#!/usr/bin/env bash
# To be ran on the download server
# Point <product dir>/latest at the newest <version>/<build> directory for each product.
# Desktop editors only move once all packages, including the signed ones, are in place, and also get
# version-less links for the downloads page, e.g.
# desktopeditors/Nextcloud-Office-DesktopEditors-latest-windows-x64.exe
set -euo pipefail

root="${OFFICE_ROOT:-/var/www/html/office}"
status=0

for product in desktopeditors docserver; do
	cd "$root/$product"
	target=$(find . -mindepth 2 -maxdepth 2 -type d \
		| sed 's#^\./##' \
		| grep -E '^[0-9]+(\.[0-9]+)*/[0-9]+$' | sort -V | tail -n1 || true)
	if [[ -z "$target" ]]; then
		echo "No <version>/<build> directory in $root/$product" >&2
		continue
	fi
	if [[ "$product" == desktopeditors ]]; then
		v=${target/\//-}
		# <fixed link suffix>:<file in the build directory>
		packages=(
			"windows-x64.exe:Nextcloud-Office-DesktopEditors-$v-windows-x64.exe"
			"windows-arm64.exe:Nextcloud-Office-DesktopEditors-$v-windows-arm64.exe"
			"macos-arm64.dmg:Nextcloud-Office-DesktopEditors-$v-macos-arm64.dmg"
			"linux-x64.deb:nextcloud-office-nextcloudoffice_${v}_amd64.deb"
			"linux-arm64.deb:nextcloud-office-nextcloudoffice_${v}_arm64.deb"
			"linux-x64.rpm:nextcloud-office-nextcloudoffice-$v.x86_64.rpm"
			"linux-arm64.rpm:nextcloud-office-nextcloudoffice-$v.aarch64.rpm"
			"linux-x64.tar.xz:nextcloud-office-nextcloudoffice-$v-x86_64.tar.xz"
			"linux-arm64.tar.xz:nextcloud-office-nextcloudoffice-$v-aarch64.tar.xz"
		)
		missing=0
		for package in "${packages[@]}"; do
			if [[ ! -f "$target/${package#*:}" ]]; then
				echo "Missing $root/$product/$target/${package#*:}" >&2
				missing=1
			fi
		done
		if ((missing)); then
			echo "Keeping $root/$product/latest -> $(readlink latest || echo none)" >&2
			status=1
			continue
		fi
		for package in "${packages[@]}"; do
			link="Nextcloud-Office-DesktopEditors-latest-${package%%:*}"
			ln -sfn "$target/${package#*:}" "$link"
			echo "$root/$product/$link -> $target/${package#*:}"
		done
	fi
	ln -sfn "$target" latest
	echo "$root/$product/latest -> $target"
done
exit "$status"
