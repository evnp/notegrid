#!/usr/bin/env bash

# notegrid · v0.0.1

function ng() ( set -euo pipefail
	local panes=0 directory='' tmex_args=() editor='' dir_prefix='' name=''
	local width=0 extension='' tmex_cmds=() editor_args='' print=FALSE

	panes=9
	directory='notes'
	dir_prefix='.'
	extension='.card.md'
	editor="${EDITOR:-vim}"

	# Parse environment variablejs:
	[[ -n "${NOTEGRID_PANES:-}" ]] && panes="${NOTEGRID_PANES}"
	[[ -n "${NOTEGRID_DIRECTORY:-}" ]] && directory="${NOTEGRID_DIRECTORY}"
	[[ -n "${NOTEGRID_DIRECTORY_NOT_HIDDEN:-}" ]] && dir_prefix=''
	[[ -n "${NOTEGRID_EXTENSION:-}" ]] && extension="${NOTEGRID_EXTENSION}"
	[[ -n "${NOTEGRID_EDITOR:-}" ]] && editor="${NOTEGRID_EDITOR}"
	[[ -n "${NOTEGRID_EDITOR_ARGS:-}" ]] && editor_args="${NOTEGRID_EDITOR_ARGS}"

	# Parse arguments:
	while (( $# ))
	do
		if [[ "$1" == '--print-tmux-command' ]]
		then
			print=TRUE
			shift
		elif [[ "$1" == '--directory-not-hidden' ]]
		then
			dir_prefix=''
			shift
		elif [[ "$1" =~ ^([0-9]+)$ ]]
		then
			panes="${BASH_REMATCH[1]}"
			shift
		elif [[ "$1" =~ ^([a-zA-Z0-9_-]+)$ ]]
		then
			directory="${BASH_REMATCH[1]}"
			shift
		elif [[ "$1" =~ ^((\.[a-z]+)+)$ ]]
		then
			extension="${BASH_REMATCH[1]}"
			shift
		else
			break
		fi
	done

	# Set default arguments for specific editors:
	if [[ -z "${editor_args}" ]]
	then
		if [[ "${editor}" == 'vim' || "${editor}" == 'nvim' ]]
		then
			editor_args="-c 'set cmdheight=0 laststatus=0'"
		fi
		# FUTURE: Add default args for other editors here.
	fi

	# 1/3 current terminal width in columns (minus 4 columns for pane/editor margins):
	width="$(( $( tput cols ) / 3 - 4 ))"

	if [[ "$( basename "$PWD" )" != "${dir_prefix}${directory}" ]]
	then
		! [[ -d "./${dir_prefix}${directory}" ]] && mkdir "${dir_prefix}${directory}"
		cd "./${dir_prefix}${directory}"
	fi

	if [[ -n "$( find . -maxdepth 1 -name "*${extension}" -print -quit 2>/dev/null )" ]]
	then
		# If card files already exist, synchronise file names with card title lines:
		find . -maxdepth 1 -name "*${extension}" -exec sh -c "head -1 \"\$1\" \
		| tr -sc '[:alnum:]' '-' \
		| tr '[:upper:]' '[:lower:]' \
		| sed -E 's/(^-|-$)//g' \
		| awk NF \
		| sed -E 's/$/${extension}/' \
		| xargs mv \"\$1\"" shell {} \;
	else
		# Otherwise, if no card files yet exist, create set of new ones with letter names:
		for name in A B C D E F G H I
		do
			printf "${name}\n%${width}s\n\n" | tr ' ' '-' > "./${name}${extension}"
		done
	fi

	editor_args="$( echo "${editor_args}" | tr '"' "'" )"

	# Construct tmex commands (with editor invocation) from each card file:
	mapfile -t tmex_cmds < <(
		find . -maxdepth 1 -name "*${extension}" -exec sh -c "echo \"\$1\" \
		| sed \"s/^/${editor} ${editor_args} /\"" shell {} \; \
		| head "-${panes}"
	)

	# If there aren't enough cards, open empty editor panes for remainder of grid:
	while (( ${#tmex_cmds[@]} < panes ))
	do
		tmex_cmds+=( "${editor} ${editor_args}" )
	done

	# Prepare tmex arguments, starting with session name:
	tmex_args=(
		"$( dirs -p | head -1 | tr -sc '[:alnum:]' '-' | sed -E 's/(^-|-$)//g' )" \
		--focus 0 --set-status=off
	)
	[[ "${print}" == TRUE ]] && tmex_args+=( --print )

	# Open card files in grid of tmux panes:
	tmex "${tmex_args[@]}" -- "${tmex_cmds[@]}"
)

# Only execute main function if script isn't being sourced:
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
	ng "$@"
fi
