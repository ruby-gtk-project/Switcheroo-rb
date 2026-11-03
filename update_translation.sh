#!/usr/bin/env bash
#
# Ported from upstream's update_translation.sh.
#
# Upstream sets up a throwaway meson build directory, runs the generated
# `switcheroo-pot` target in it (and, commented out, `switcheroo-update-po`),
# and deletes the directory again. This port has no meson, so there is no
# build directory to create or remove: the same two steps are Rake tasks that
# work in place, `app:pot` and `app:update_po`.
#
# Unlike upstream, the merge step is *not* commented out. Upstream's comment
# is there because its CI regenerates POTFILES.in and the catalogues itself;
# this port has no such pipeline, so a translator running this script is the
# only thing that refreshes po/*.po.
#
# Both steps need xgettext, rxgettext, msgcat and msgmerge, which the flake's
# dev shell provides — run this inside `nix develop`, or let it re-enter the
# shell itself when it is not already in one.

set -euo pipefail

cd "$(dirname "$0")"

if command -v rxgettext >/dev/null 2>&1 && command -v xgettext >/dev/null 2>&1; then
	exec rake app:update_po
fi

if command -v nix >/dev/null 2>&1; then
	echo "rxgettext/xgettext not on PATH; re-entering the flake dev shell" >&2
	exec nix develop --command rake app:update_po
fi

echo "update_translation.sh needs rxgettext, xgettext, msgcat and msgmerge." >&2
echo "Enter the dev shell with \`nix develop\` and run it again." >&2
exit 1
