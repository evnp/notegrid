#!/usr/bin/env bash

load './node_modules/bats-support/load'
load './node_modules/bats-assert/load'

function run_test_command() {
	local cmd
	cmd="${BATS_TEST_DESCRIPTION}"
	cmd="${cmd/${BATS_TEST_NUMBER} /}"
	cmd="${cmd/cards/${BATS_TEST_DIRNAME}/notegrid.sh}"
	if [[ "${cmd}" =~ ^([A-Z_]+=[^ ]*) ]]; then
		# handle env var declarations placed before test command
		export "${BASH_REMATCH[1]}"
		run "${cmd/${BASH_REMATCH[1]} /}" --print-tmux-command
	else
		run "${cmd}" --print-tmux-command
	fi
}

@test "${BATS_TEST_NUMBER} cards" {
	run_test_command
	assert_success
}

