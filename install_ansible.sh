#!/usr/bin/env bash
# This script installs Ansible on a variety of OSes.  Taken from Tower install.
#
# It can be called remotely:
#   wget -qO- https://raw.githubusercontent.com/dswhitley/miscellany/master/install_ansible.sh | /bin/bash

# -------------
# Initial Setup
# -------------

# Cause exit codes to trickle through piping.
set -o pipefail

# When using an interactive shell, force colorized output from Ansible.
if [ -t "0" ]; then
    ANSIBLE_FORCE_COLOR=True
fi

# Set variables.
TIMESTAMP=$(date +"%F-%T")
LOG_DIR="/var/log/ansible_install"
LOG_FILE="${LOG_DIR}/setup-${TIMESTAMP}.log"
TEMP_LOG_FILE='setup.log'

OPTIONS=""

# -------------
# Helper functions
# -------------

# Be able to get the real path to a file.
realpath() {
    echo $(cd $(dirname $1); pwd)/$(basename $1)
}

is_ansible_installed() {
    type -p ansible-playbook > /dev/null
}

distribution_id() {
    RETVAL=""
    if [ -z "${RETVAL}" -a -e "/etc/os-release" ]; then
        . /etc/os-release
        RETVAL="${ID}"
    fi

    if [ -z "${RETVAL}" -a -e "/etc/centos-release" ]; then
        RETVAL="centos"
    fi

    if [ -z "${RETVAL}" -a -e "/etc/fedora-release" ]; then
        RETVAL="fedora"
    fi

    if [ -z "${RETVAL}" -a -e "/etc/redhat-release" ]; then
        RELEASE_OUT=$(head -n1 /etc/redhat-release)
        case "${RELEASE_OUT}" in
            Red\ Hat\ Enterprise\ Linux*)
                RETVAL="rhel"
                ;;
            CentOS*)
                RETVAL="centos"
                ;;
            Fedora*)
                RETVAL="fedora"
                ;;
        esac
    fi

    if [ -z "${RETVAL}" ]; then
        RETVAL="unknown"
    fi

    echo ${RETVAL}
}

distribution_major_version() {
    for RELEASE_FILE in /etc/system-release \
                        /etc/centos-release \
                        /etc/fedora-release \
                        /etc/redhat-release
    do
        if [ -e "${RELEASE_FILE}" ]; then
            RELEASE_VERSION=$(head -n1 ${RELEASE_FILE})
            break
        fi
    done
    echo ${RELEASE_VERSION} | sed -e 's|\(.\+\) release \([0-9]\+\)\([0-9.]*\).*|\2|'
}

log_success() {
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}

log_warning() {
    echo -n "[warn] "
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}

log_error() {
    echo -n "[error] "
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}


# --------------
# Usage
# --------------

function usage() {
    cat << EOF
Usage: $0 [Options] [-- Ansible Options]

Options:
  -h                    Show this help message and exit

EOF
    exit 64
}


# --------------
# Option Parsing
# --------------

# First, search for -- (end of args)
# Anything after -- is placed into OPTIONS and passed to Ansible
# Anything before -- (or the whole string, if no --) is processed below
ARGS=$*
if [[ "$ARGS" == *"-- "* ]]; then
    SETUP_ARGS=${ARGS%%-- *}
    OPTIONS=${ARGS##*-- }
else
    SETUP_ARGS=$ARGS
    OPTIONS=""
fi

# Process options to setup.sh
while getopts 'c:e:i:psuhbr' OPTION $SETUP_ARGS; do
    case $OPTION in
        *) usage;;
    esac
done

# Sanity check: Test to ensure that Ansible exists.
is_ansible_installed
if [ $? -ne 0 ]; then
    SKIP_ANSIBLE_CHECK=0
    case $(distribution_id) in
        ubuntu)
            apt-get install -y software-properties-common;
            add-apt-repository -y ppa:ansible/ansible;
            apt-get update;
            apt-get install -y ansible;;
        rhel|centos|ol)
            DISTRIBUTION_MAJOR_VERSION=$(distribution_major_version)
            case ${DISTRIBUTION_MAJOR_VERSION} in
                6) yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm;;
                7) yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm;;
            esac
            yum install -y ansible;;
        fedora)
            yum install -y ansible;;
    esac

    # Check whether ansible was successfully installed
    if [ ${SKIP_ANSIBLE_CHECK} -ne 1 ]; then
        is_ansible_installed
        if [ $? -ne 0 ]; then
            log_error "Unable to install ansible."
            fatal_ansible_not_installed
        fi
    fi
fi


# Save the exit code and output accordingly.
RC=$?
if [ ${RC} -ne 0 ]; then
    log_error "Oops!  An error occured while running setup."
else
    log_success "The setup process completed successfully."
fi

# Save log file.
if [ -d "${LOG_DIR}" ]; then
    sudo cp ${TEMP_LOG_FILE} ${LOG_FILE}
    if [ $? -eq 0 ]; then
        sudo rm ${TEMP_LOG_FILE}
    fi
    log_success "Setup log saved to ${LOG_FILE}"
else
    log_warning <<-EOF
		${LOG_DIR} does not exist.
		Setup log saved to ${TEMP_LOG_FILE}.
		EOF
fi

exit ${RC}
