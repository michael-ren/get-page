#!/bin/sh -eu

# get-page: Download a snapshot of a URL for offline viewing, isolating each
#           snapshot's resources from other snapshots by placing each snapshot
#           in its own directory.
#
#           Downloading example.com creates:
#             - example.com
#               - index.html -> example.com/index.html
#               - example.com
#                 - index.html

ROBOTS="${ROBOTS:-on}"
ERR_LEVEL="${ERR_LEVEL:-7}"


usage(){
	>&2 printf '%s\n' "Usage: $0 URLS..."
	exit 0
}

case "${1:-}" in
	-h|--help|"")
		usage
		;;
esac


bad_url(){
	# $1: The bad URL
	>&2 printf '%s\n' "Bad url: $1"
	exit 1
}

get_page_directory(){
	# $1: The URL
	# Output: The page directory
	PAGE="$1"

	PAGE_DIRECTORY_TMP="$(printf '%s' "$PAGE" | cut -d ':' -f2)"
	[ "$PAGE" = "$PAGE_DIRECTORY_TMP" ] && bad_url "$PAGE"

	PAGE_DIRECTORY="${PAGE_DIRECTORY_TMP#//}"
	[ "$PAGE_DIRECTORY_TMP" = "$PAGE_DIRECTORY" ] && bad_url "$PAGE"

	PAGE_DIRECTORY="${PAGE_DIRECTORY%/}"
	[ -z "$PAGE_DIRECTORY" ] && bad_url "$PAGE"

	printf '%s' "$PAGE_DIRECTORY"
}


OLDPWD="$PWD"

printf 'Pages:\n'

for PAGE in "$@"; do
	get_page_directory "$PAGE"
	printf '\n'
done

printf '\n\n\n'

for PAGE in "$@"; do
	PAGE_DIRECTORY="$(get_page_directory "$PAGE")"

	[ -d "$PAGE_DIRECTORY" ] && continue

	mkdir -p -- "$PAGE_DIRECTORY"

	cd "$PAGE_DIRECTORY"

	wget \
		--no-verbose \
		--execute robots="$ROBOTS" \
		--page-requisites \
		--span-hosts \
		--adjust-extension \
		--convert-links \
		--backup-converted \
		"$PAGE" && WGET_ERR=0 || WGET_ERR=$?

	if [ "$WGET_ERR" -le "$ERR_LEVEL" -a "$WGET_ERR" -gt 0 ]; then
		exit "$WGET_ERR"
	fi

	if [ -f "$PAGE_DIRECTORY"/index.html ]; then
		ln -s "$PAGE_DIRECTORY"/index.html index.html
	elif [ -f "$PAGE_DIRECTORY".html ]; then
		ln -s "$PAGE_DIRECTORY.html" index.html
	else
		ln -s "$PAGE_DIRECTORY" index.html
	fi

	cd "$OLDPWD"
done
