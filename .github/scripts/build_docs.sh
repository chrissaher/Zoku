#!/bin/bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Return the value of the last (rightmost) command to exit with a non-zero status
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo $DIR

# Create ~/.kaggle directory if it doesn't exist
mkdir -p ~/.kaggle

# Generate the JSON content
json_content="{\"username\":\"none\",\"key\":\"none\"}"

# Save the JSON content to ~/.kaggle/kaggle.json
echo "$json_content" > ~/.kaggle/kaggle.json

# Restrict permissions of the kaggle.json file to owner read/write only
chmod 600 ~/.kaggle/kaggle.json


# run these commands in a subshell so the environment doesn't affect the ability to detect if pyenv
# has been set up properly in the user's environment later
(
    # shellcheck source=/dev/null
    source "${DIR}"/install_python.sh
    # pyenv has been added to PATH by sourcing install.sh, so we can enable pyenv here
    eval "$(pyenv init --path)"
    # eval "$(pyenv init -)"

    # # Notice: workaround for poetry issue: https://github.com/python-poetry/poetry/issues/8623
    python3 -m poetry config keyring.enabled false
    # # this needs to be sourced so we can pick up the new PATH with pyenv in it
    python3 -m poetry install --sync
    # # pre-commit setup
    python3 -m poetry run pre-commit install
)
