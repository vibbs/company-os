#!/usr/bin/env bash
# Markdown link checker for tests (sourced after lib/assert.sh, not run).
#
#   check_links <file>...
#       prints one "BROKEN <file>:<line> -> <target> (<reason>)" line per
#       relative link, image, reference definition or <img src> that does not
#       resolve, including #anchors into Markdown files. Web links, fenced
#       code blocks and inline code are ignored. Links starting with / resolve
#       against $LINKS_ROOT (default: $REPO_ROOT).
#   $LINKS_AWK_DIR/links.awk prints "<line>\t<target>" for one file.

LINKS_AWK_DIR="$(make_tmp)"

# Prints "<line>\t<target>" for each Markdown link, image, reference
# definition and <img src>, skipping fenced code blocks and inline code.
cat > "$LINKS_AWK_DIR/links.awk" <<'EOF'
/^[ \t]*(```|~~~)/ { fence = !fence; next }
fence { next }
{
  line = $0
  gsub(/`[^`]*`/, "", line)
  if (match(line, /^[ \t]*\[[^]]+\]:[ \t]+[^ \t]+/)) {
    t = line; sub(/^[ \t]*\[[^]]+\]:[ \t]+/, "", t); sub(/[ \t].*$/, "", t)
    print FNR "\t" t
  }
  while (match(line, /\]\([^)]+\)/)) {
    t = substr(line, RSTART + 2, RLENGTH - 3)
    print FNR "\t" t
    line = substr(line, RSTART + RLENGTH)
  }
  while (match(line, /<img[^>]*src="[^"]+"/)) {
    t = substr(line, RSTART, RLENGTH); sub(/.*src="/, "", t); sub(/"$/, "", t)
    print FNR "\t" t
    line = substr(line, RSTART + RLENGTH)
  }
}
EOF

# Prints the GitHub-style anchor of every heading, plus HTML name/id values.
cat > "$LINKS_AWK_DIR/anchors.awk" <<'EOF'
/^[ \t]*(```|~~~)/ { fence = !fence; next }
fence { next }
/^#+[ \t]/ {
  h = $0; sub(/^#+[ \t]+/, "", h); sub(/[ \t]+#*[ \t]*$/, "", h)
  h = tolower(h)
  gsub(/[^a-z0-9 _-]/, "", h)
  gsub(/ /, "-", h)
  if (h in seen) { seen[h]++; print h "-" seen[h] } else { seen[h] = 0; print h }
}
{
  line = $0
  while (match(line, /(name|id)="[^"]+"/)) {
    t = substr(line, RSTART, RLENGTH); sub(/^[a-z]+="/, "", t); sub(/"$/, "", t); print t
    line = substr(line, RSTART + RLENGTH)
  }
}
EOF

TAB="$(printf '\t')"
LINKS_CHECKED=0

# check_links <file>...: prints one "BROKEN ..." line per unresolved link.
check_links() {
  local f ln t path anchor full
  for f in "$@"; do
    while IFS="$TAB" read -r ln t; do
      t="${t#<}"; t="${t%>}"; t="${t%% *}"
      case "$t" in http://*|https://*|mailto:*|tel:*) continue ;; esac
      path="${t%%#*}"; path="${path%%\?*}"
      anchor=""
      case "$t" in *"#"*) anchor="${t#*#}" ;; esac
      if [ -z "$path" ]; then
        full="$f"
      else
        case "$path" in /*) full="${LINKS_ROOT:-$REPO_ROOT}$path" ;; *) full="$(dirname "$f")/$path" ;; esac
      fi
      if [ ! -e "$full" ]; then
        echo "BROKEN $f:$ln -> $t (no such file)"
        continue
      fi
      if [ -n "$anchor" ] && [ -f "$full" ]; then
        case "$full" in
          *.md)
            awk -f "$LINKS_AWK_DIR/anchors.awk" "$full" | grep -qxF -- "$anchor" \
              || echo "BROKEN $f:$ln -> $t (no heading for #$anchor)"
            ;;
        esac
      fi
    done < <(awk -f "$LINKS_AWK_DIR/links.awk" "$f")
  done
}
