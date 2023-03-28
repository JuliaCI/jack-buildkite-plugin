#!/bin/bash
OS=("windows" "linux" "macos")
TARGET_WORKFLOW="${1}"

for os in ${OS[@]}; do
    ytt -f "${TARGET_WORKFLOW}" --data-value os="${os}" --data-value arch="x86_64" | buildkite-agent pipeline upload

    if [[ $os == "windows" ]]; then
        continue
    fi
    ytt -f "${TARGET_WORKFLOW}" --data-value os="${os}" --data-value arch="aarch64" | buildkite-agent pipeline upload
done
