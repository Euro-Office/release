#!/usr/bin/env bash
# Release DocumentServer and DesktopEditors with one version, tagged across all submodules.
#
#   release.sh prepare <version> [--products both|ds|de] [--since <tag>] [--dry-run]
#   release.sh tag     <version> [--products both|ds|de] [--dry-run]
#
# Needs git and an authenticated gh (GH_TOKEN) with write access to every repo involved.
set -euo pipefail

OWNER=Euro-Office

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*" >&2; }

usage() {
  sed -n '4,5p' "$0" | sed 's/^# *//' >&2
  exit 2
}

product() {
  case $1 in
    ds) echo "DocumentServer VERSION" ;;
    de) echo "DesktopEditors VERSION.txt" ;;
    *) die "unknown product: $1" ;;
  esac
}

valid_version() { [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+\.[0-9]+)?$ ]]; }
is_stable() { [[ $1 =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; }

# stdin: tags, newest first. A stable release compares against the previous stable one.
previous_tag() {
  local re='v[0-9]+\.[0-9]+\.[0-9]+'
  is_stable "$1" || re="$re(-[a-z]+\.[0-9]+)?"
  grep -Ex "$re" | grep -vxF "$1" | head -n 1 || true
}

slug() { sed -E 's#^(https://github\.com/|git@github\.com:)##; s#\.git$##; s#/$##' <<<"$1"; }

# The resolved SHA is cached per repo so shared submodules get the same commit in every product.
pin() {
  local slug=$1 sha
  sha=$(awk -v s="$slug" '$1 == s { print $2 }' "$WORK/pins")
  if [ -z "$sha" ]; then
    sha=$(git ls-remote "https://github.com/$slug.git" HEAD | awk '$2 == "HEAD" { print $1 }')
    [ -n "$sha" ] || die "cannot resolve HEAD of $slug"
    echo "$slug $sha" >>"$WORK/pins"
  fi
  echo "$sha"
}

notes() {
  local slug=$1 old=$2 new=$3 prev=$4
  if [ "$old" = "$new" ]; then
    echo "No changes."
  elif [ -n "$prev" ] && gh api "repos/$slug/git/ref/tags/$prev" >/dev/null 2>&1; then
    gh api -X POST "repos/$slug/releases/generate-notes" \
      -f tag_name="$TAG" -f target_commitish="$new" -f previous_tag_name="$prev" \
      --jq .body | sed -E 's/^## /#### /'
  else
    echo "No tag $prev in $slug, see https://github.com/$slug/compare/$old...$new"
  fi
}

prepend_changelog() {
  local file=$1 section=$2 rest=""
  [ -f "$file" ] && rest=$(sed '1{/^# Changelog$/d;}' "$file" | sed '/./,$!d')
  { echo "# Changelog"; echo; cat "$section"; [ -z "$rest" ] || echo "$rest"; } >"$file.new"
  mv "$file.new" "$file"
}

prepare_product() {
  local repo=$1 vfile=$2 dir="$WORK/$1" prev path url sub old new section="$WORK/$1.section.md"
  log "$repo: cloning"
  gh repo clone "$OWNER/$repo" "$dir" -- -q --depth 1 --no-tags
  git -C "$dir" fetch -q --depth 1 origin 'refs/tags/v*:refs/tags/v*'
  git -C "$dir" checkout -q -b "release/$TAG"

  prev=${SINCE:-$(git -C "$dir" for-each-ref --sort=-creatordate --format='%(refname:short)' refs/tags | previous_tag "$TAG")}
  log "$repo: changes since ${prev:-<none>}"
  [ -n "$prev" ] || die "$repo: no previous release tag, pass --since"

  {
    echo "## $TAG"
    echo
    echo "### $repo"
    echo
    notes "$OWNER/$repo" "$(git -C "$dir" rev-parse "$prev^{commit}")" "$(git -C "$dir" rev-parse HEAD)" "$prev"
  } >"$section"

  while read -r _ path; do
    url=$(git -C "$dir" config -f .gitmodules "submodule.$path.url")
    sub=$(slug "$url")
    old=$(git -C "$dir" ls-tree "$prev" -- "$path" | awk '{ print $3 }')
    new=$(pin "$sub")
    log "$repo: $path -> $new"
    git -C "$dir" update-index --cacheinfo "160000,$new,$path"
    {
      echo
      echo "### $path"
      echo
      if [ -n "$old" ]; then notes "$sub" "$old" "$new" "$prev"; else echo "New submodule."; fi
    } >>"$section"
  done < <(git -C "$dir" config -f .gitmodules --get-regexp '^submodule\..*\.path$')

  echo >>"$section"
  # Keep the existing trailing-newline style of the version file.
  if [ -n "$(tail -c 1 "$dir/$vfile")" ]; then printf '%s' "$VERSION" >"$dir/$vfile"; else echo "$VERSION" >"$dir/$vfile"; fi
  prepend_changelog "$dir/CHANGELOG.md" "$section"
  git -C "$dir" add "$vfile" CHANGELOG.md
  git -C "$dir" commit -q -s -m "chore(release): $TAG"
}

cmd_prepare() {
  local p repo vfile url urls=()
  for p in $PRODUCTS; do
    read -r repo vfile < <(product "$p")
    git ls-remote --exit-code --tags "https://github.com/$OWNER/$repo.git" "refs/tags/$TAG" >/dev/null &&
      die "$repo already has tag $TAG"
  done

  for p in $PRODUCTS; do
    read -r repo vfile < <(product "$p")
    prepare_product "$repo" "$vfile"
  done

  if $DRY_RUN; then
    for p in $PRODUCTS; do
      read -r repo _ < <(product "$p")
      git -C "$WORK/$repo" show --stat --format='%h %s' HEAD
      cat "$WORK/$repo.section.md"
    done
    log "dry run, nothing pushed. Work tree kept in $WORK"
    return
  fi

  for p in $PRODUCTS; do
    read -r repo _ < <(product "$p")
    git -C "$WORK/$repo" push -q --force origin "release/$TAG"
    url=$(gh pr view "release/$TAG" -R "$OWNER/$repo" --json url --jq .url 2>/dev/null ||
      gh pr create -R "$OWNER/$repo" --base main --head "release/$TAG" \
        --title "chore(release): $TAG" --body-file "$WORK/$repo.section.md")
    log "$repo: $url"
    urls+=("$url")
  done

  if [ ${#urls[@]} -eq 2 ]; then
    gh pr comment "${urls[0]}" --body "Released together with ${urls[1]}" >/dev/null
    gh pr comment "${urls[1]}" --body "Released together with ${urls[0]}" >/dev/null
  fi
}

# Prints the commit a tag points to, or nothing if the tag does not exist.
tag_commit() {
  local ref
  ref=$(gh api "repos/$1/git/ref/tags/$TAG" --jq '.object.type + " " + .object.sha' 2>/dev/null) || return 0
  case $ref in
    tag\ *) gh api "repos/$1/git/tags/${ref#tag }" --jq .object.sha ;;
    *) echo "${ref#* }" ;;
  esac
}

cmd_tag() {
  local p repo vfile merge got path sha slug existing gitmodules="$WORK/gitmodules"
  : >"$WORK/subs"
  : >"$WORK/products"
  for p in $PRODUCTS; do
    read -r repo vfile < <(product "$p")
    merge=$(gh pr list -R "$OWNER/$repo" --head "release/$TAG" --state merged --json mergeCommit --jq '.[0].mergeCommit.oid')
    [ -n "$merge" ] || die "$repo: no merged PR from release/$TAG"
    got=$(gh api "repos/$OWNER/$repo/contents/$vfile?ref=$merge" -H 'Accept: application/vnd.github.raw' | tr -d '[:space:]')
    [ "$got" = "$VERSION" ] || die "$repo: $vfile is $got at $merge, expected $VERSION"
    echo "$OWNER/$repo $merge" >>"$WORK/products"

    gh api "repos/$OWNER/$repo/contents/.gitmodules?ref=$merge" -H 'Accept: application/vnd.github.raw' >"$gitmodules"
    while read -r path sha; do
      echo "$(slug "$(git config -f "$gitmodules" "submodule.$path.url")") $sha" >>"$WORK/subs"
    done < <(gh api "repos/$OWNER/$repo/git/trees/$merge" --jq '.tree[] | select(.type == "commit") | "\(.path) \(.sha)"')
  done

  sort -u "$WORK/subs" -o "$WORK/subs"
  if awk '{ print $1 }' "$WORK/subs" | uniq -d | grep -q .; then
    awk 'NR == FNR { n[$1]++; next } n[$1] > 1' "$WORK/subs" "$WORK/subs" >&2
    die "shared submodules point at different commits"
  fi

  # Check every tag before creating any, so a mismatch never leaves a partial release.
  cat "$WORK/subs" "$WORK/products" >"$WORK/plan"
  : >"$WORK/todo"
  while read -r slug sha; do
    existing=$(tag_commit "$slug")
    if [ -z "$existing" ]; then
      echo "$slug $sha" >>"$WORK/todo"
    elif [ "$existing" = "$sha" ]; then
      log "$slug: $TAG already at $sha"
    else
      die "$slug: $TAG exists at $existing, expected $sha"
    fi
  done <"$WORK/plan"

  # Products last: their tags start the builds.
  while read -r slug sha; do
    if $DRY_RUN; then
      log "would tag $slug $TAG -> $sha"
      continue
    fi
    sha=$(gh api "repos/$slug/git/tags" -f tag="$TAG" -f message="Release $TAG" -f object="$sha" -f type=commit --jq .sha)
    gh api "repos/$slug/git/refs" -f ref="refs/tags/$TAG" -f sha="$sha" >/dev/null
    log "$slug: tagged $TAG"
  done <"$WORK/todo"
}

main() {
  [ $# -ge 2 ] || usage
  local cmd=$1 p
  VERSION=$2
  shift 2
  PRODUCTS="ds de"
  SINCE=""
  DRY_RUN=false
  while [ $# -gt 0 ]; do
    case $1 in
      --products) [ "$2" = both ] || PRODUCTS=$2; shift 2 ;;
      --since) SINCE=$2; shift 2 ;;
      --dry-run) DRY_RUN=true; shift ;;
      *) usage ;;
    esac
  done
  for p in $PRODUCTS; do product "$p" >/dev/null; done
  valid_version "$VERSION" || die "invalid version: $VERSION (expected e.g. 9.3.6 or 9.3.6-rc.1)"
  TAG="v$VERSION"
  WORK=$(mktemp -d)
  : >"$WORK/pins"

  case $cmd in
    prepare) cmd_prepare ;;
    tag) cmd_tag ;;
    *) usage ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
