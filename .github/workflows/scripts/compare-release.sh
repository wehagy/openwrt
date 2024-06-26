#!/usr/bin/env bash

set -ex

REPO="netbirdio/netbird"
REMOTE_TAG="$(git ls-remote --refs --sort='-version:refname' --tags https://github.com/"${REPO}".git | head --lines=1 | cut --delimiter='/' --fields=3)"
REMOTE_TAG_STRIP="$(t="${REMOTE_TAG}" && echo "${t:1}")"
LOCAL_TAG="$(grep 'PKG_VERSION:=' custom-feed/netbird/Makefile)"
LOCAL_TAG_STRIP="$(t="${LOCAL_TAG}" && echo "${t:13}")"

if [[ "$(printf '%s\n%s' "${REMOTE_TAG_STRIP}" "${LOCAL_TAG_STRIP}" | sort --version-sort --check=quiet; echo "${?}")" == 0 ]]; then
    echo "ok"
else
    echo "not ok"
    curl -sL https://github.com/"${REPO}"/archive/refs/tags/"${REMOTE_TAG}".tar.gz -o "${REPO##*/}"-"${REMOTE_TAG_STRIP}".tar.gz
    SHA256="$(sha256sum "${REPO##*/}"-"${REMOTE_TAG_STRIP}".tar.gz | head -c 64 && rm "${REPO##*/}"-"${REMOTE_TAG_STRIP}".tar.gz)"
    sed -i "s/\(PKG_HASH:=\).*/\1${SHA256}/" custom-feed/netbird/Makefile
    sed -i "s/\(PKG_VERSION:=\).*/\1${REMOTE_TAG_STRIP}/" custom-feed/netbird/Makefile
    if [[ "${GITHUB_ACTIONS}" = "true" ]]; then
        echo "sha256=${SHA256}" >> "${GITHUB_OUTPUT}"
    fi
fi
