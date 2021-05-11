#!/usr/bin/env bash

# fail on first error
set -euo pipefail

# make sure we have admin rights
if [[ $EUID > 0 ]]; then
    echo >&2 "Need admin rights"
    exit 1
fi

# installation configuration
INSTALL_DIRECTORY="/opt/bin/phpenv"
PHPENV="${INSTALL_DIRECTORY}/phpenv"
PHPENV_RELOAD="${INSTALL_DIRECTORY}/phpenv-reload"
SHIM_PHPENV_RELOAD="/usr/local/bin/phpenv-reload"
DEFAULT_PHP_VERSION_FILE="${INSTALL_DIRECTORY}/.default-php-version"

### Installation

# install (or replace) all files
mkdir -p "${INSTALL_DIRECTORY}"
find "${INSTALL_DIRECTORY}" -mindepth 1 ! -name ".default-php-version" -delete
cp ./phpenv* "${INSTALL_DIRECTORY}"
chown -R root:root "${INSTALL_DIRECTORY}"

# allow appwise user to execute phpenv-reload with sudo
cat >"${SHIM_PHPENV_RELOAD}" <<EOT
#!/usr/bin/env bash

sudo ${PHPENV_RELOAD} "\$@"
EOT
chmod +x "${SHIM_PHPENV_RELOAD}"

echo "%appwise ALL = (root) NOPASSWD: ${PHPENV_RELOAD}" > /etc/sudoers.d/phpenv-reload

# set default PHP version

# print current default PHP version, if any
if [ -r "${DEFAULT_PHP_VERSION_FILE}" ]; then
    CURRENT_DEFAULT_PHP_VERSION=$(<"${DEFAULT_PHP_VERSION_FILE}")

    if ! [ -z "${CURRENT_DEFAULT_PHP_VERSION}" ]; then
        echo "Default PHP version currently set to ${CURRENT_DEFAULT_PHP_VERSION}"
    fi
fi

# prompt for new default PHP version
DEFAULT_PHP_VERSION=
while [ -z "${DEFAULT_PHP_VERSION}" ]; do
    read -p "Choose default PHP version (eg 7.4): " DEFAULT_PHP_VERSION

    # make sure default PHP executable is installed and executable
    PHP="/usr/bin/php${DEFAULT_PHP_VERSION}"
    if ! [ -x "$(command -v ${PHP})" ]; then
        echo >&2 "Error: default PHP executable not found or not executable (${PHP})"
        DEFAULT_PHP_VERSION=
    fi
done
echo "${DEFAULT_PHP_VERSION}" > "${DEFAULT_PHP_VERSION_FILE}"

### Validation

# make sure the phpenv executable is installed and executable
if ! [ -x "${PHPENV}" ]; then
    echo >&2 "Error: ${PHPENV} is not executable or does not exist"
    exit 1;
fi

# make sure the phpenv-reload executable is installed and executable
if ! [ -x "${PHPENV_RELOAD}" ]; then
    echo >&2 "Error: ${PHPENV_RELOAD} is not executable or does not exist"
    exit 1;
fi

### Finish up

# make sure system uses phpenv instead of plain php from now on
update-alternatives --install /usr/bin/php php "${PHPENV}" 200
update-alternatives --auto php
