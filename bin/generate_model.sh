#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

log() {
    >&2 echo "$@"
}

main() {
    pushd "${SCRIPT_DIR}" >/dev/null

    local python_version
    python_version=$(./current_python_major_minor.py)

    log "Current Python version: ${python_version}"

    if ! git diff --exit-code --quiet -- v2_spec.json; then
        log "Model patches have changes; exiting"
        exit 1
    fi

    pushd ../spec >/dev/null
    git apply ./v2_spec.patch
    popd >/dev/null

    log "Applied spec patch"

    log "Linting patched spec..."
    lint-spec

    log "Generating code..."
    datamodel-codegen \
        --input ../spec/v2_spec.json \
        --output ../affinity_model/v2.py \
        --output-model-type pydantic_v2.BaseModel \
        --use-annotated \
        --use-union-operator \
        --capitalise-enum-members \
        --use-field-description \
        --input-file-type openapi \
        --field-constraints \
        --use-double-quotes \
        --base-class ..MyBaseModel \
        --disable-timestamp \
        --target-python-version "${python_version}"

    log "Generated code"

    # TODO: this does not work if there was an error in between
    log "Resetting model"
    git checkout ../spec/v2_spec.json

    git apply \
        --allow-empty \
        ./v2_model_patches.diff

    log "Applied model patch"

    popd >/dev/null
}

main "$@"
