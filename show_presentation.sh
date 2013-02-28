#!/bin/bash

# Reset terminal to current state when we exit.
trap "stty $(stty -g)" EXIT

# Disable echo and special characters, set input timeout to 0.2 seconds.
stty -echo -icanon time 2 || exit $?

# String containing all keypresses.
KEYS=""

# Set field separator to BEL (should not occur in keypresses)
IFS=$'\a'

SELECTION=""


# The logitech presenter device is a keyboard with 6 buttons:
#  Button		keycode
#  left arrow		page-up
#  right arrow		page-down
#  Monitor		'.'
#  F5/esc		Alternates between F5 and Esc
#  volume up		volume-up
#  volume down		volume-down
#
# we are going to use left and right arrows to make the selection of the file,
# and the monitor button as the "select me" option.  Everything else will be
# ignored.
# to be nice on testing on a keyboard, let's also use the right and left and up
# and down arrows to change the selection.
#
# This functions returns the key in the ${SELECTION} variable as:
#	'R' - move right
#	'L' - move left
#	'P' - make this selection
get_selection()
{
	# Input loop.
	while [ 1 ]; do

		SELECTION=""

		# Read more input from keyboard when necessary.
		while read -t 0 ; do
			read -s -r -d "" -N 1 -t 0.2 CHAR && KEYS="$KEYS$CHAR" || break
		done

		# If no keys to process, wait 0.05 seconds and retry.
		if [ -z "$KEYS" ]; then
			sleep 0.05
			continue
		fi

		# Check the first (next) keypress in the buffer.
		case "$KEYS" in

		$'\x1B\x5B\x41'*) # Up
			KEYS="${KEYS##???}"
			#echo "Up"
			SELECTION="L"
			;;
		$'\x1B\x5B\x42'*) # Down
			KEYS="${KEYS##???}"
			#echo "Down"
			SELECTION="R"
			;;
		$'\x1B\x5B\x44'*) # Left
			KEYS="${KEYS##???}"
			#echo "Left"
			SELECTION="L"
			;;
		$'\x1B\x5B\x43'*) # Right
			KEYS="${KEYS##???}"
			#echo "Right"
			SELECTION="R"
			;;
		$'\x1B\x5B\x35\x7e'*) # PageUp
			KEYS="${KEYS##????}"
			#echo "PageUp"
			SELECTION="L"
			;;
		$'\x1B\x5B\x36\x7e'*) # PageDown
			KEYS="${KEYS##????}"
			#echo "PageDown"
			SELECTION="R"
			;;
		$'.'*) # 'period'
			KEYS="${KEYS##?}"
			SELECTION="P"
			;;
		$'\x1B\x5B\x31\x35\x7e'*) # F5
			KEYS="${KEYS##?????}"
			#echo "F5"
			;;
		$'\n'*|$'\r'*) # Enter/Return
			KEYS="${KEYS##?}"
			#echo "Enter or Return"
			SELECTION="P"
			;;
		$'\x1B') # Esc (without anything following!)
			KEYS="${KEYS##?}"
			#echo "Esc"
			;;
		$'\x1B'*) # Unknown escape sequences
			#echo -n "Unknown escape sequence (${#KEYS} chars): \$'"
			#echo -n "$KEYS" | od --width=256 -t x1 | sed -e '2,99 d; s|^[0-9A-Fa-f]* ||; s| |\\x|g; s|$|'"'|"
			KEYS=""
			;;
		[$'\x01'-$'\x1F'$'\x7F']*) # Consume control characters
			KEYS="${KEYS##?}"
			;;
		*) # Printable characters.
			KEY="${KEYS:0:1}"
			KEYS="${KEYS#?}"
			#echo "'$KEY'"
			;;
		esac

		if [ "${SELECTION}" == "" ] ; then
			continue;
		else
			#echo "Selection = '${SELECTION}'"
			break;
		fi
	done
}

while [ 1 ] ; do

	for pdf in *.pdf ; do
		echo -n "Press 'monitor key' to run the ${pdf} presentation."
		get_selection
		echo ""
		if [ "${SELECTION}" == "P" ] ; then
			evince ${pdf} &
			#exit 0
		fi
	done
done
