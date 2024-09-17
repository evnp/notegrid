#!/usr/bin/env bash

# vimdexcards · v0.0.1

function cards() ( set -euo pipefail
	local args='' panes=0 directory='' tmex_args=() editor=''
	local name='' width=0 extension='' tmex_cmds=() editor_args='' print=FALSE

	args=" $* "
	panes=9
	directory='notes'
	extension='.card.md'
	editor="${EDITOR:-vim}"

	# Parse environment variablejs:
	[[ -n "${VIMDEXCARDS_DIRECTORY:-}" ]] && directory="${VIMDEXCARDS_DIRECTORY}"
	[[ -n "${VIMDEXCARDS_EXTENSION:-}" ]] && extension="${VIMDEXCARDS_EXTENSION}"
	[[ -n "${VIMDEXCARDS_EDITOR:-}" ]] && editor="${VIMDEXCARDS_EDITOR}"
	[[ -n "${VIMDEXCARDS_EDITOR_ARGS:-}" ]] && editor_args="${VIMDEXCARDS_EDITOR_ARGS}"

	# Parse arguments:
	if [[ "${args}" == *' --print-tmux-command '* ]]
	then
		print=TRUE
		args="${args/--print-tmux-command /}"
	fi
	if [[ "${args}" =~ [[:space:]]([a-zA-Z0-9_-]+)[[:space:]] ]]
	then
		directory="${BASH_REMATCH[1]}"
		args="${args/ ${directory}/}"
	fi
	if [[ "${args}" =~ [[:space:]]((\.[a-z]+)+)[[:space:]] ]]
	then
		extension="${BASH_REMATCH[1]}"
		args="${args/ ${extension}/}"
	fi
	args="${args## }" # trim leading space
	args="${args%% }" # trim trailing space
	# Pass on all remaining arguments as editor arguments:
	if [[ -n "${args}" ]]
	then
		editor_args="${args}"
	fi

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

	if [[ "$( basename "$PWD" )" != ".${directory}" ]]
	then
		! [[ -d "./.${directory}" ]] && mkdir ".${directory}"
		cd ".${directory}"
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
	cards "$@"
fi
