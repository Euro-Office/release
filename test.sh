#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/release.sh"

check() { [ "$2" = "$3" ] || { echo "FAIL $1: got '$2', want '$3'"; exit 1; }; }

tags=$'v9.3.5-rc.2\nv9.3.5-rc.1\nv9.3.4-hotfix.1\nv9.3.4\nv99.99.99.4652\nwin-v4.3.0.110\nv9.3.3'
check "rc after rc" "$(previous_tag v9.3.5-rc.3 <<<"$tags")" v9.3.5-rc.2
check "stable after rcs" "$(previous_tag v9.3.5 <<<"$tags")" v9.3.4
check "ignores itself" "$(previous_tag v9.3.5-rc.2 <<<"$tags")" v9.3.5-rc.1
check "no previous" "$(previous_tag v1.0.0 <<<"")" ""
check "slug https" "$(slug https://github.com/Euro-Office/core.git)" Euro-Office/core
check "slug ssh" "$(slug git@github.com:Euro-Office/core)" Euro-Office/core
if ! { valid_version 9.3.6 && valid_version 9.3.6-rc.1 && ! valid_version v9.3.6 && ! valid_version 9.3; }; then
  echo "FAIL valid_version"; exit 1
fi
echo ok
