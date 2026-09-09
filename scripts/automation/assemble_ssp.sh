#!/usr/bin/env bash

set -euo pipefail

version_tag=${1:-}
component_definition=Ubuntu_Linux_24.04_LTS

for directory in system-security-plans/*/; do
    ssp=$(basename "${directory%/}")
    command=(
        author ssp-assemble
        --markdown "md_ssp/${ssp}"
        --output "${ssp}"
        --compdefs "${component_definition}"
    )
    if [[ -n "${version_tag}" ]]; then
        command+=(--version "${version_tag}")
    fi
    echo "Assembling ${ssp}"
    trestle "${command[@]}"
done
