#!/usr/bin/env bash

set -euo pipefail

required_variables=(
    VERSION_TAG
    GH_TOKEN
    GITHUB_REPOSITORY
    SSP_SIGNING_PRIVATE_KEY
    SSP_SIGNING_KEY_PASSWORD
    SSP_SIGNING_PUBLIC_KEY
)

for variable in "${required_variables[@]}"; do
    if [[ -z "${!variable:-}" ]]; then
        echo "Required environment variable is not set: ${variable}" >&2
        exit 1
    fi
done

if [[ ! "${VERSION_TAG}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    echo 'Release tag contains unsupported characters.' >&2
    exit 1
fi

release_tag="v${VERSION_TAG#v}"
work_dir=$(mktemp -d "${RUNNER_TEMP:-/tmp}/ssp-signing.XXXXXX")
package_root="${work_dir}/package"
manifest="${package_root}/ssp-signing-manifest.json"
envelope="${package_root}/ssp-signing-manifest.dsse"
archive="${work_dir}/ssp-package-${release_tag}.tar.gz"

cleanup() {
    rm -rf "${work_dir}"
}
trap cleanup EXIT

umask 077
mkdir -p "${package_root}"
printf '%s\n' "${SSP_SIGNING_PRIVATE_KEY}" > "${work_dir}/ssp-private.pem"
printf '%s\n' "${SSP_SIGNING_PUBLIC_KEY}" > "${work_dir}/ssp-public.pem"

cp -R .trestle catalogs component-definitions profiles system-security-plans "${package_root}/"

(
    cd "${package_root}"
    trestle generate-manifest \
        --beta \
        -f system-security-plans/Ubuntu_Linux_24_04_LTS/system-security-plan.json \
        --include component-definitions/Ubuntu_Linux_24.04_LTS/component-definition.json \
        -o "$(basename "${manifest}")"
    trestle sign-manifest \
        --beta \
        --manifest "$(basename "${manifest}")" \
        --private-key "${work_dir}/ssp-private.pem" \
        --key-password-env SSP_SIGNING_KEY_PASSWORD \
        -o "$(basename "${envelope}")"
    trestle verify-manifest \
        --beta \
        --manifest "$(basename "${manifest}")" \
        --signature "$(basename "${envelope}")" \
        --public-key "${work_dir}/ssp-public.pem"

    jq -r '.artifacts[].uri' "$(basename "${manifest}")" > "${work_dir}/ssp-package-files.txt"
    printf '%s\n' "$(basename "${manifest}")" "$(basename "${envelope}")" >> "${work_dir}/ssp-package-files.txt"
    tar -czf "${archive}" -T "${work_dir}/ssp-package-files.txt"
)

gh release upload "${release_tag}" "${archive}" --repo "${GITHUB_REPOSITORY}"
