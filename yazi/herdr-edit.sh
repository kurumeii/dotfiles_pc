#!/usr/bin/env bash
# Open a file in nvim inside a new herdr tab (used by yazi opener "edit-tab").
pane=$(herdr tab create --cwd "$(dirname "$1")" --focus | jq -r '.result.root_pane.pane_id')
herdr pane run "$pane" "nvim $(printf '%q' "$1")"
