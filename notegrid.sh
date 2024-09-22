#!/usr/bin/env bash

# notegrid · v0.0.1

function ng-sync() (
	local extension='' panes=0 title_line='' width='' name=''

	extension="$1" # required
	shift

	panes="${1:-}" # optional
	shift

	if (( panes > 0 ))
	then
		# Calculate optimal grid column width:
		if [[ -n "$TERM" ]]
		then
			width="$( tput cols )"
		else
			width=90
		fi
		width="$(( width / $(
			echo "${panes}" | awk '{print sqrt($1)%1 ? int(sqrt($1)+1) : sqrt($1)}'
		) - 4 ))"
		if (( width < 3 ))
		then
			width=3
		fi
		title_line="$( printf "%${width}s" | tr ' ' '-' )"
	else
		title_line="---"
	fi

	if [[ -n "$( find . -maxdepth 1 -name "*${extension}" -print -quit 2>/dev/null )" ]]
	then
		# If card files already exist, make two updates to card files:
		# - Update length of second line of each card to match current grid column width.
		# - Synchronise file names with card title lines.
		find . -maxdepth 1 -name "*${extension}" \
		-exec sh -c "\
		perl -pi -e 's/.*/${title_line}/ if $. == 2' \"\$1\"; \
		head -1 \"\$1\" \
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
			printf "${name}\n%${width}s\n\n" | tr ' ' '-' > \
				"./$( echo "${name}" | tr '[:upper:]' '[:lower:]' )${extension}"
		done
	fi

	if [[ -n "${NOTEGRID_COLOCATE:-}" && -n "${NOTEGRID_GIT_ORIGIN:-}" ]]
	then
		echo "Error: Don't use both 'colocate' mode and Git-based syncing options at once."
		exit 1
	fi

	if [[ -n "${NOTEGRID_GIT_ORIGIN:-}" ]]
	then
		# Navigate to $HOME/.notes directory:
		while [[ "$( dirname "$PWD" )" != "$HOME" ]]
		do
			cd ..
		done

		if [[ "$( git rev-parse --is-inside-work-tree 2>/dev/null )" ]]
		then
			git pull origin main
		else
			# Initialize new repository if needed
			git init
			git remote add origin "$NOTEGRID_GIT_ORIGIN"

			# Initialize new repository if needed
			if [[ -n "${NOTEGRID_GIT_CRYPT_KEY_FILE:-}" ]]
			then
				git-crypt init
				echo "*${extension} filter=git-crypt diff=git-crypt" > ./.gitattributes
				if [[ "$NOTEGRID_GIT_CRYPT_KEY_FILE" == '/'* ]] \
				|| [[ "$NOTEGRID_GIT_CRYPT_KEY_FILE" == '~'* ]] \
				|| [[ "$NOTEGRID_GIT_CRYPT_KEY_FILE" == "$HOME"* ]]
				then
					git-crypt export-key "$NOTEGRID_GIT_CRYPT_KEY_FILE"
				else
					git-crypt export-key "$HOME/$NOTEGRID_GIT_CRYPT_KEY_FILE"
				fi
			fi
		fi

		# Sync all changes via standard git operations:
		if [[ -n "$( git status -s )" ]]
		then
			git add --all
			git commit -m "$( date )"
			git push origin main
		fi
	fi
)

function ng() ( set -euo pipefail
	local tmex_args=() directory='' dir_prefix='' editor='' panes=0
	local tmex_cmds=() extension='' dir_path='' editor_args=''
	local sync=FALSE colocate=FALSE print=FALSE
	panes=9
	directory='notes'
	dir_prefix='.'
	extension='.card.md'
	editor="${EDITOR:-vi}"

	# Parse environment variablejs:
	[[ -n "${NOTEGRID_PANES:-}" ]] && panes="${NOTEGRID_PANES}"
	[[ -n "${NOTEGRID_COLOCATE:-}" ]] && colocate=TRUE
	[[ -n "${NOTEGRID_DIRECTORY:-}" ]] && directory="${NOTEGRID_DIRECTORY}"
	[[ -n "${NOTEGRID_DIRECTORY_NOT_HIDDEN:-}" ]] && dir_prefix=''
	[[ -n "${NOTEGRID_EXTENSION:-}" ]] && extension="${NOTEGRID_EXTENSION}"
	[[ -n "${NOTEGRID_EDITOR:-}" ]] && editor="${NOTEGRID_EDITOR}"
	[[ -n "${NOTEGRID_EDITOR_ARGS:-}" ]] && editor_args="${NOTEGRID_EDITOR_ARGS}"

	# Parse arguments:
	while (( $# ))
	do
		if [[ "$1" == '--sync' ]]
		then
			sync=TRUE
			shift
		elif [[ "$1" == '--colocate' ]]
		then
			colocate=TRUE
			shift
		elif [[ "$1" == '--directory-not-hidden' ]]
		then
			dir_prefix=''
			shift
		elif [[ "$1" == '--print-tmux-command' ]]
		then
			print=TRUE
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
		if [[ "${editor}" == 'nvim' ]]
		then
			editor_args="-c 'set cmdheight=0 laststatus=0'"
		elif [[ "${editor}" == 'vim' || "${editor}" == 'vi' ]]
		then
			editor_args="-c 'set cmdheight=1 laststatus=0'"
		fi
		# FUTURE: Add default args for other editors here.
	fi

	# If --colocate or NOTEGRID_COLOCATE set, create notes dir and files "in situ"
	# within the current directory, generally within a ".notes" hidden directory:
	# (depending on specified directory name and hidden option)
	if [[ "${colocate}" == TRUE ]]
	then
		dir_path="${dir_prefix}${directory}"
	# Otherwise, create notes dir and files within universal $HOME/.notes directory:
	# (depending on specified directory name and hidden option)
	else
		if [[ "$PWD/" == "$HOME/${dir_prefix}${directory}/"* ]]
		then
			# If already within $HOME/.notes (possibly in deeper dir), just use current dir:
			dir_path="$PWD"
		else
			# Otherwise, construct path to notes directory from current dir path ($PWD):
			dir_path="$HOME/${dir_prefix}${directory}${PWD/$HOME/}"
		fi
	fi
	# Create directory if it doesn't exist yet:
	# (using -p to create intermediate dirs if needed)
	! [[ -d "${dir_path}" ]] && mkdir -p "${dir_path}"
	# Navigate to directory:
	# (whole script runs in subshell so this won't affect calling shell)
	cd "${dir_path}"

	ng-sync "${extension}" "${panes}"

	# If --sync was set, then we're all done:
	if [[ "${sync}" == TRUE ]]
	then
		exit 0
	fi

	editor_args="$( echo "${editor_args}" | tr '"' "'" )"

	# Construct tmex commands (with editor invocation) from each card file:
	mapfile -t tmex_cmds < <(
		find . -maxdepth 1 -name "*${extension}" -exec sh -c "echo \"\$1\" \
		| sed \"s!.*!${editor} ${editor_args} '\$1'; ng --sync!\"" shell {} \; \
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
