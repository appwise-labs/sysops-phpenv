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

### Installation

# install (or replace) all files
mkdir -p "${INSTALL_DIRECTORY}"
find "${INSTALL_DIRECTORY}" -mindepth 1 -delete
cp ./phpenv* "${INSTALL_DIRECTORY}"
chown -R root:root "${INSTALL_DIRECTORY}"

# allow appwise user to execute phpenv-reload with sudo
cat >"${SHIM_PHPENV_RELOAD}" <<EOT
#!/usr/bin/env bash

sudo ${PHPENV_RELOAD} "\$@"
EOT
chmod +x "${SHIM_PHPENV_RELOAD}"

echo "%appwise ALL = (root) NOPASSWD: ${PHPENV_RELOAD}" > /etc/sudoers.d/phpenv-reload

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
update-alternatives --install /usr/bin/php php "${PHPENV}" 100
