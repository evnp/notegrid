#!/usr/bin/env bash

# notegrid · v0.0.1

function git-crypt-key-file-path() {
	if [[ -z "$NOTEGRID_GIT_CRYPT_KEY_FILE" ]]
	then
		echo ''
	elif [[ "$NOTEGRID_GIT_CRYPT_KEY_FILE" == '/'* ]] \
		|| [[ "$NOTEGRID_GIT_CRYPT_KEY_FILE" == '~'* ]] \
		|| [[ "$NOTEGRID_GIT_CRYPT_KEY_FILE" == "$HOME"* ]]
	then
		echo "$NOTEGRID_GIT_CRYPT_KEY_FILE"
	else
		echo "$HOME/$NOTEGRID_GIT_CRYPT_KEY_FILE"
	fi
}

function ng-sync() (
	local op='' extension='' panes=0 title_line='' width='' name=''

	op="$1" # required
	! [[ "${op}" == 'pull' || "${op}" == 'push' || "${op}" == 'sync' ]] \
		&& echo "ng-sync: first argument must be 'pull' 'push' or 'sync'" && exit 1
	shift

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

		if [[ "${op}" == 'pull' || "${op}" == 'sync' ]]
		then
			git pull origin main
		fi

		if [[ "${op}" == 'push' || "${op}" == 'sync' ]] && [[ -n "$( git status -s )" ]]
		then
			git add --all
			git commit -m "$( date )"
			git push origin main
		fi
	fi
)

function ng() ( set -euo pipefail
	local tmex_args=() directory='' dir_prefix='' editor='' panes=0
	local tmex_cmds=() extension='' dir_path='' editor_args='' file=''
	local pull=FALSE push=FALSE sync=FALSE colocate=FALSE print=FALSE
	local false_re=''
	panes=9
	directory='notes'
	dir_prefix='.'
	extension='.card.md'
	editor="${EDITOR:-vi}"

	# Parse environment variables:
	shopt -s nocasematch
	false_re='^(0|false|no|null|nil|none)?$'
	[[ "${NOTEGRID_PANES:-}" =~ ^[0-9]+$ ]] && panes="${NOTEGRID_PANES}"
	[[ -n "${NOTEGRID_EXTENSION:-}" ]] && extension="${NOTEGRID_EXTENSION}"
	[[ -n "${NOTEGRID_EDITOR:-}" ]] && editor="${NOTEGRID_EDITOR}"
	[[ -n "${NOTEGRID_EDITOR_ARGS:-}" ]] && editor_args="${NOTEGRID_EDITOR_ARGS}"
	[[ -n "${NOTEGRID_DIRECTORY:-}" ]] && directory="${NOTEGRID_DIRECTORY}"
	! [[ "${NOTEGRID_DIRECTORY_NOT_HIDDEN:-}" =~ ${false_re} ]] && dir_prefix=''
	! [[ "${NOTEGRID_COLOCATE:-}" =~ ${false_re} ]] && colocate=TRUE
	shopt -u nocasematch

	# Parse arguments:
	while (( $# ))
	do
		if [[ "$1" == '--pull' ]]
		then
			pull=TRUE
			shift
		elif [[ "$1" == '--push' ]]
		then
			push=TRUE
			shift
		elif [[ "$1" == '--sync' ]]
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
	if ! [[ -d "${dir_path}" ]]
	then
		if [[ "${colocate}" == FALSE && -n "${NOTEGRID_GIT_ORIGIN:-}" ]]
		then
			# If specified, clone notes repository:
			cd "$( dirname "${dir_path}" )"
			if git clone "$NOTEGRID_GIT_ORIGIN" "${dir_prefix}${directory}" 2>/dev/null
			then
				# If specified, decrypt notes repository:
				if [[ -n "${NOTEGRID_GIT_CRYPT_KEY_FILE:-}" ]]
				then
					cd "${dir_path}"
					git-crypt unlock "$( git-crypt-key-file-path )"
				fi
			fi
		fi

		# If directory still doesn't exist (repo wasn't cloned above), create it:
		if ! [[ -d "${dir_path}" ]]
			mkdir -p "${dir_path}"

			# Initialize new repository if needed:
			if [[ "${colocate}" == FALSE && -n "${NOTEGRID_GIT_ORIGIN:-}" ]]
				cd "${dir_path}"

				git init
				git remote add origin "$NOTEGRID_GIT_ORIGIN"

				if [[ -n "${NOTEGRID_GIT_CRYPT_KEY_FILE:-}" ]]
				then
					git-crypt init
					echo "*${extension} filter=git-crypt diff=git-crypt" > ./.gitattributes
					git-crypt export-key "$( git-crypt-key-file-path )"
				fi
			fi
		fi
	fi

	# Navigate to directory:
	# (whole script runs in subshell so this won't affect calling shell)
	cd "${dir_path}"

	if [[ "${pull}" == TRUE ]]
	then
		ng-sync pull "${extension}" "${panes}"
		exit 0
	elif [[ "${push}" == TRUE ]]
	then
		ng-sync push "${extension}" "${panes}"
		exit 0
	elif [[ "${sync}" == TRUE ]]
	then
		ng-sync sync "${extension}" "${panes}"
		exit 0
	else
		ng-sync pull "${extension}" "${panes}"
	fi

	editor_args="$( echo "${editor_args}" | tr '"' "'" )"

	# Construct tmex commands (with editor invocation) from each card file:
	for file in *${extension}
	do
		tmex_cmds+=( "${editor} ${editor_args} ${file}; ng --push" )
		(( ${#tmex_cmds[@]} >= panes )) && break  # one command for each pane and no more
	done

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
