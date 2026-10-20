#!/usr/bin/env bash
# Print the brander URLs of the Nextcloud Office artifacts to sign from the
# DesktopEditors tag build, e.g. scripts/signing-artifacts.sh 9.3.6-rc.1
set -euo pipefail

repo=Euro-Office/DesktopEditors
tag=v${1#v}
run=$(gh run list -R "$repo" --branch "$tag" --event push --workflow build.yml --status success -L 1 \
	--json databaseId --jq '.[0].databaseId // empty')
if [[ -z "$run" ]]; then
	echo "No successful build of $tag in $repo" >&2
	exit 1
fi
gh api "repos/$repo/actions/runs/$run/artifacts" --paginate --jq \
	".artifacts[] | select((.expired | not) and (.name | test(\"^(windows-signing-bundle|macos-packages)-nextcloud-office-\")))
	| \"\(.name)\thttps://github.com/$repo/actions/runs/$run/artifacts/\(.id)\""
