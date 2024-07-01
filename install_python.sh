#!/bin/bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Return the value of the last (rightmost) command to exit with a non-zero status
set -o pipefail

PYTHON_VERSION=${1:-"3.10.4"}
PYENV_MIN_VERSION="2.0.6"

if locale -a | grep --quiet "C.UTF-8"; then
    export LANG="C.UTF-8"
else
    export LANG="en_US.UTF-8"
fi

if [[ "${OSTYPE}" == "darwin"* ]]; then
    SYSTEM="Darwin"
elif [[ "${OSTYPE}" == "linux-gnu" ]]; then
    SYSTEM="Linux"
else
    echo "Could not determine OS. Only Linux and OSX are supported."
    exit 1
fi

function semantic_version_less_than() {
    v1=$1
    v1="$(cut -d'-' -f1 <<<"$v1")" # This removes final subversion parts, e.g. 1.2.20-19-g8ac91b4f -> 1.2.20
    v2=$2
    for part in 1 2 3 ; do  # check 1st, 2nd and 3rd part of semantic version
        v1_part="$(echo "${v1}" | cut -d'.' -f${part})"  # e.g., for part=3, this does "1.2.21" -> "21"
        v2_part="$(echo "${v2}" | cut -d'.' -f${part})"
        if [[ ${v1_part} -lt ${v2_part} ]]; then
            return 0
        elif [[ ${v1_part} -gt ${v2_part} ]]; then
            return 1
        fi
    done
    return 1  # equal
}

function sudo_or_exec {
    if [[ "$(id -u)" -eq 0 ]]; then
        "${@}"
    else
        sudo "${@}"
    fi
}

function add_to_env() {
    if grep -Fxq "${1}" "${2}" ; then
        echo "${1} is already in ${2}"
    else
        echo -e "${1}" >> "${2}"
    fi
}

INSTALLED_PACKAGES=()

function install_if_missing() {
    PACKAGES_TO_INSTALL=()
    for package in "$@"; do
        if ! dpkg --get-selections "${package}" | grep -qE "\sinstall$"; then
            echo "Installing missing package ${package}"
            PACKAGES_TO_INSTALL+=("${package}")
        fi
    done

    if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
        sudo_or_exec apt-get install -y "${PACKAGES_TO_INSTALL[@]}"
        INSTALLED_PACKAGES+=("${PACKAGES_TO_INSTALL[@]}")
    fi
}

function is_brew_available() {
    if ! command -v brew &> /dev/null; then
      echo "brew is required to install the python interpreter. Please install it from https://brew.sh and then rerun this script"
      exit 1
    fi
}

function remove_installed_packages() {
    echo "Removing installed packages"
    if [ ${#INSTALLED_PACKAGES[@]} -gt 0 ]; then
      sudo_or_exec apt-get purge -y "${INSTALLED_PACKAGES[@]}"
    fi
    sudo_or_exec apt autoremove -y
}

function update_profile() {
    add_to_env "export PYENV_ROOT=\${HOME}/.pyenv" "${1}"
    add_to_env "export PATH=\${PYENV_ROOT}/bin:\${PATH}" "${1}"
    add_to_env "if command -v pyenv 1>/dev/null 2>&1; then\n eval \"\$(pyenv init --path)\"\nfi" "${1}"
}

# install git
if ! command -v git > /dev/null; then
  if [ "${SYSTEM}" == "Linux" ]; then
    echo "--- git missing - installing now."
    sudo_or_exec apt-get update
    install_if_missing git
  elif [ "${SYSTEM}" == "Darwin" ]; then
    echo "Please make sure you have installed Git."
    exit 1
  fi
fi

PYENV_COMMAND="$(command -v pyenv || true)"

if [ -z "${PYENV_COMMAND}" ]; then
    echo "--- pyenv missing - installing now."
    if [ ! -d "${HOME}"/.pyenv ]; then
        git clone --depth 1 https://github.com/pyenv/pyenv.git "${HOME}"/.pyenv
    else
        git -C "${HOME}"/.pyenv pull
    fi

    if [ "${SYSTEM}" == "Linux" ]; then
        update_profile "${HOME}"/.bashrc
    elif [ "${SYSTEM}" == "Darwin" ]; then
        # Needed to build python interpreters with lzma
        is_brew_available
        # TODO(gdabisias) try to get rid of brew to avoid contamination from unexpected dependencies
        brew install xz
        # if ~/.bash_profile exists, then ~/.profile is ignored by Bash
        if [[ -f "${HOME}"/.bash_profile ]]; then
            update_profile "${HOME}"/.bash_profile
        else
            update_profile "${HOME}"/.profile
        fi
        update_profile "${HOME}"/.zprofile
    fi
    export PYENV_ROOT="${HOME}/.pyenv"
    export PATH="${PYENV_ROOT}/bin:${PATH}"
else
    # PYENV_VERSION is a variable used by pyenv itself, so use _PYENV_VERSION instead
    _PYENV_VERSION="$(pyenv --version | cut -d' ' -f2)"
    if semantic_version_less_than "${_PYENV_VERSION}" "${PYENV_MIN_VERSION}"; then
        echo "--- updating pyenv, found version ${_PYENV_VERSION}, required version is ${PYENV_MIN_VERSION}"
        if [ ! -d "$(pyenv root)/plugins/pyenv-update" ] ; then
            git clone --depth 1 https://github.com/pyenv/pyenv-update.git "$(pyenv root)/plugins/pyenv-update"
        fi
        pyenv update
    fi
fi

if pyenv versions | grep "${PYTHON_VERSION}" > /dev/null; then
    echo "--- Python ${PYTHON_VERSION} already installed."
else
    echo "--- Python ${PYTHON_VERSION} missing - installing now."
    if [ ${SYSTEM} == "Linux" ]; then
        sudo_or_exec apt-get update
        install_if_missing zlib1g-dev \
            libssl-dev \
            build-essential \
            wget \
            make \
            libffi-dev \
            libbz2-dev \
            liblzma-dev \
            libreadline-dev \
            libsqlite3-dev
    fi
    pyenv install --skip-existing "${PYTHON_VERSION}"
fi

echo "--- Setting ${PYTHON_VERSION} as local python version"
pyenv local "${PYTHON_VERSION}"

echo "--- Installing pip"
PIP_VERSION="$(pyenv exec python3 -m pip --version || true)"

if [ -z "${PIP_VERSION}" ]; then
    pyenv exec python3 -m ensurepip --default-pip
fi

pyenv exec python3 -m pip install --upgrade pip setuptools
pyenv exec python3 -m pip install wheel
pyenv exec python3 -m pip install poetry

# Final cleanup
if [ ${SYSTEM} == "Linux" ]; then
    remove_installed_packages
fi
