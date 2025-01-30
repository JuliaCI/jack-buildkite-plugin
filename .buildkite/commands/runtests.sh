#!/bin/bash
OS=("windows" "linux" "macos")
TARGET_WORKFLOW="${1}"
JULIA_VERSIONS=(1.10 1.11 nightly)

for julia_version in ${JULIA_VERSIONS[@]}; do
    for os in ${OS[@]}; do
        ytt -f "${TARGET_WORKFLOW}" --data-value os="${os}" --data-value arch="x86_64" --data-value julia_version="${julia_version}" | buildkite-agent pipeline upload

        if [[ $os == "windows" ]]; then
            continue
        fi
        ytt -f "${TARGET_WORKFLOW}" --data-value os="${os}" --data-value arch="aarch64" --data-value julia_version="${julia_version}" | buildkite-agent pipeline upload
    done
done
