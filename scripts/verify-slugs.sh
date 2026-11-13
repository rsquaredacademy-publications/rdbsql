#!/bin/sh
# verify-slugs.sh - assert every chapter declared in _quarto.yml was rendered.
#
# Derives the list from _quarto.yml instead of hardcoding it. A hardcoded list
# rots silently: add a chapter, forget the gate, and the page can vanish from
# the site with the build still green. That is how references.html went missing
# from viz-base during the Quarto migration.
#
# Usage: sh scripts/verify-slugs.sh <rendered-html-dir>
#   e.g. sh scripts/verify-slugs.sh /tmp/stage-html
#
# Uses yq where available, or Rscript with yaml (already used by Quarto).
#
# NO `set -e` HERE, deliberately. Under `set -e` a failing `[ ! -f ]` test
# aborts the script before the explicit `exit 1` runs, and the shell can report
# success — the gate prints FAIL and CI stays green. Exit status is set
# explicitly instead. Do not add `set -e` to this file.

DIR="${1:?usage: verify-slugs.sh <rendered-html-dir>}"
YAML="_quarto.yml"

if [ ! -f "$YAML" ]; then
  echo "FAIL: $YAML not found (run from the book root)"
  exit 1
fi

# Chapters (including nested parts) + appendices, .qmd entries only.
# `sed` strips the extension because yq's sub()/rtrimstr() do not behave
# as expected here; verified against yq 4.5x on the runner image.
if command -v yq >/dev/null 2>&1; then
  entries=$(yq eval -r '(.book.chapters[]?, .book.appendices[]?) | .. | select(tag == "!!str")' "$YAML") || exit 1
elif command -v Rscript >/dev/null 2>&1; then
  entries=$(Rscript -e 'b <- yaml::yaml.load(paste(readLines("_quarto.yml", encoding = "UTF-8"), collapse = "\n"))$book; cat(unlist(b[c("chapters", "appendices")], use.names = FALSE), sep = "\n")') || exit 1
else
  echo "FAIL: install yq or Rscript with the yaml package"
  exit 1
fi
slugs=$(printf '%s\n' "$entries" | tr -d '\r' | grep '\.qmd$' | sed 's/\.qmd$//')

if [ -z "$slugs" ]; then
  echo "FAIL: no chapters or appendices found in $YAML"
  exit 1
fi

missing=0
count=0
for s in $slugs; do
  count=$((count + 1))
  if [ ! -f "$DIR/$s.html" ]; then
    echo "MISSING SLUG: $DIR/$s.html"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "FAIL: $count chapter(s) declared in _quarto.yml, some did not render"
  exit 1
fi

echo "OK: all $count declared chapters rendered"
