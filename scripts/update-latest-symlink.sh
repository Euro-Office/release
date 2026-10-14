#!/usr/bin/env bash
# To be ran on the download server
# Point <product dir>/latest at the newest <version>/<build> directory for each product.
set -euo pipefail

root="${OFFICE_ROOT:-/var/www/html/office}"

for product in desktopeditors docserver; do
	cd "$root/$product"
	target=$(find . -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
		| grep -E '^[0-9]+(\.[0-9]+)*/[0-9]+$' | sort -V | tail -n1 || true)
	if [[ -z "$target" ]]; then
		echo "No <version>/<build> directory in $root/$product" >&2
		continue
	fi
	ln -sfn "$target" latest
	echo "$root/$product/latest -> $target"
done
