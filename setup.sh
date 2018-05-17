#!/bin/bash
# This script will be generic enough to be public.  It will require some 
# arguments be passed:
# 1) A repository containing a "master" playbook relying on the anisble-role
#    roles.  This is so the master playbook can contain variables that might not
#    be appropriate in the public domain.  This will be a URL.
# 2) The branch of said repository (can be ommitted and master will be used)
# 3) The name of the master playbook to call.
#
# This script will:
# 01) ensure git is installed 
# 02) ensure ansible is installed
# 03) clone the ansible-roles repo
# 06) run the specified playbook 
#
# EXAMPLE:  wget https://raw.githubusercontent.com/dswhitley/miscellany/master/setup.sh
#           /bin/bash setup.sh -r "https://privateuser@gitlab.com/privateuser/privaterepo.git" -b develop -p local.yml
## these global variables can be used throughout ##++++++++++++++++++++++++++++#
REPO=""
BRANCH=""
PLAYBOOK=""
ROLES_BASE="https://github.com/dswhitley/ansible-roles/archive"
ROLES_REPO="https://github.com/dswhitley/ansible-roles.git"
ROLES_BRANCH="develop"
ANSIBLE_INSTALL_URL="https://raw.githubusercontent.com/dswhitley/miscellany/master/install_ansible.sh"

# Process options to setup.sh
while getopts 'r:b:p:' OPTION $*; do
    case $OPTION in
        r) REPO=${OPTARG};;
        b) BRANCH=${OPTARG};;
        p) PLAYBOOK=${OPTARG};;
        *) usage;;
    esac
done


## GETTING STARTED with main() ##++++++++++++++++++++++++++++++++++++++++++++++#
main() {

  # 01: ensure git is installed and clone the aftermath repo
  is_git_installed
  if [ $? -ne 0 ]; then
    echo "Please install 'git' on your OS and try again..."
    exit 66
  else
    mkdir -vp ~/GIT && cd $_
    # if the directory already exists, git checkout instead of clone
    git clone -b $BRANCH $REPO
    DIR=$(basename $REPO);
    DIR=${DIR%%.git}
    cd $DIR
  fi

  # 02: ensure that Ansible is installed
  is_ansible_installed
  if [ $? -ne 0 ]; then
    wget -qO- $ANSIBLE_INSTALL_URL | /bin/bash
    RC=$?
    if [ ${RC} -ne 0 ]; then
        echo "Oops!  An error occured while running installing Ansible."
    else
        echo "The Ansible installation completed successfully."
        sleep 3;
    fi
  fi

  # 03: clone the ansible-roles repo
  git clone ${ROLES_REPO} -b ${ROLES_BRANCH} roles

  # 04: run the playbook
  ansible-playbook ~/GIT/${DIR}/${PLAYBOOK}

}  ##> end of main() -----------------------------------------------------------

is_ansible_installed() {
    type -p ansible-playbook > /dev/null
}

is_git_installed() {
    type -p git > /dev/null
}

usage() {
    cat << EOF
Usage: $0 [Options] [-- Ansible Options]

Options:
  -r REPO               URL of a private repository
  -b BRANCH             Use a specific branch of the private repository
  -p PLAYBOOK           The playbook within the private repository to invoke
  -h                    Show this help message and exit

EOF
    exit 64
}


main
exit $RC