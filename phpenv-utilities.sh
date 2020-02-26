#!/usr/bin/env bash

# the default PHP version
DEFAULT_PHP_VERSION="7.3"

# Returns the current PHP version for a given domain
function current-php-version {
    DOMAIN=$1

    # detect path to current configuration file
    IFS=$'\n'
    FPM_CONF=($(ls /etc/php/*/fpm/pool.d/www-${DOMAIN}.conf))
    unset IFS

    # make sure we detected exactly one FPM configuration file
    if ! [ ${#FPM_CONF[@]} -eq 1 ]; then
        echo "Error: Failed to detect current PHP version"
        exit 1;
    fi

    # extract PHP version from path
    PHP_VERSION=$(echo "${FPM_CONF[0]}" | cut -d'/' -f 4)

    echo "${PHP_VERSION}"
}

# Returns the required PHP version
function required-php-version {
    # PHP version
    PHP_VERSION=

    # PHP version file
    PHP_VERSION_FILE="$HOME/www/htdocs/.php-version"

    # if PHP version file is readable, read required PHP version
    if [ -r "${PHP_VERSION_FILE}" ]; then
        PHP_VERSION=$(<"${PHP_VERSION_FILE}")
    fi

    # if PHP version is empty, use default PHP version
    if [ -z "${PHP_VERSION}" ]; then
        PHP_VERSION=${DEFAULT_PHP_VERSION}
    fi

    echo "${PHP_VERSION}"
}
