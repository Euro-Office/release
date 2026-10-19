#!/usr/bin/env bash
# To be ran on the download server
# Point <product dir>/latest at the newest <version>/<build> directory for each product.
# Desktop editors only move once the signed packages are in place, and also get
# version-less links for the downloads page, e.g.
# desktopeditors/Nextcloud-Office-DesktopEditors-latest-windows-x64.exe
set -euo pipefail

root="${OFFICE_ROOT:-/var/www/html/office}"
desktop_packages=(windows-x64.exe windows-arm64.exe macos-arm64.dmg)
status=0

for product in desktopeditors docserver; do
	cd "$root/$product"
	target=$(find . -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
		| grep -E '^[0-9]+(\.[0-9]+)*/[0-9]+$' | sort -V | tail -n1 || true)
	if [[ -z "$target" ]]; then
		echo "No <version>/<build> directory in $root/$product" >&2
		continue
	fi
	if [[ "$product" == desktopeditors ]]; then
		prefix="Nextcloud-Office-DesktopEditors-${target/\//-}"
		missing=0
		for package in "${desktop_packages[@]}"; do
			if [[ ! -f "$target/$prefix-$package" ]]; then
				echo "Missing $root/$product/$target/$prefix-$package" >&2
				missing=1
			fi
		done
		if ((missing)); then
			echo "Keeping $root/$product/latest -> $(readlink latest || echo none)" >&2
			status=1
			continue
		fi
		for package in "${desktop_packages[@]}"; do
			ln -sfn "$target/$prefix-$package" "Nextcloud-Office-DesktopEditors-latest-$package"
			echo "$root/$product/Nextcloud-Office-DesktopEditors-latest-$package -> $target/$prefix-$package"
		done
	fi
	ln -sfn "$target" latest
	echo "$root/$product/latest -> $target"
done
exit "$status"
