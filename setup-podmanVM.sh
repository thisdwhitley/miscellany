#!/bin/sh
### setup-podmanVM.sh ###>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>###
# This is a generic script that can be called whenever I need to use podman on a
# NON-Linux machine (I'm looking at you macOS).  I'm putting it in a public
# location where I can call it remotely because I will likely want to call it
# from a few different situations requiring a podmanVM and I don't want to keep
# up with updating it in mutliple locations.
#
## REQUIREMENTS ##------------------------------------------------------------##
# I have found that I need to have some specific mounts IN the VM so that the
# containers I run in the VM have access to local files.  This is sort of hard
# to wrap my head around, but I've learned that I need to mount these when I
# create the VM:
#  * PODMANVM_NEEDED - this is a variable containing the mounts that are needed
#                      (example): PODMANVM_NEEDED="${PWD} /tmp/local-vault";
#  * PODMANVM_INIT_VOLS - this is a hack that allows me to include mounts that
#                         don't align with a typical naming pattern.  Note that
#                         it is required, so must be set, even if empty ("")
#                         (example): PODMANVM_INIT_VOLS="-v /local:/different";
#       
## USE ##---------------------------------------------------------------------##	
# I imagine this being called remotely and passing variables using bash:
#
# curl https://raw.githubusercontent.com/thiswhitley/miscellany/master/setup.sh \
# | /bin/bash -s -- \
#             -r "https://privateuser@gitlab.com/privateuser/privaterepo.git" \
#             -b develop \
#             -p local
#==============================================================================#
# Process options to setup.sh
while getopts 'n:i:' OPTION $*; do
    case $OPTION in
        n) PODMANVM_NEEDED=${OPTARG};;
        i) PODMANVM_INIT_VOLS=${OPTARG};;
        *) usage;;
    esac
done

##> TODO: I should check for those variables HERE
# PODMANVM_NEEDED is a required variable, even if empty so let's check for it:
[ -z ${PODMANVM_NEEDED+x} ] && \
  echo "PODMANVM_NEEDED must be set before running, even if empty" && exit;

# This is specifically needed for mac, so I will set CTNR to `podman`:
CTNR=$(which podman);

# I've decided to always use this name:
PODMANVM="podman-machine-default";  

# Determine what is currently mounted in the podman machine (or empty if it is
#  not currently running...)
PODMANVM_MNTCMD="mount | awk '/virtio/ {print \$3}'";
PODMANVM_MOUNTS=$(${CTNR} machine ssh ${PODMANVM} ${PODMANVM_MNTCMD});

for VOLS in $PODMANVM_NEEDED; do
  PODMANVM_INIT_VOLS="$PODMANVM_INIT_VOLS -v ${VOLS}:${VOLS}";
done

for MNT in $PODMANVM_NEEDED; do
  if ! $(grep -q $MNT <<<"$PODMANVM_MOUNTS"); then
    echo "$MNT is not mounted in ${PODMANVM}, do some teardown/buildup";
    ${CTNR} machine rm --force ${PODMANVM};
    ${CTNR} machine init ${PODMANVM_INIT_VOLS} ${PODMANVM}
    sed -i '' 's/security_model=mapped-xattr/security_model=none/' $(${CNTR} machine inspect ${PODMANVM} | jq --raw-output .[0].ConfigPath.Path)
    ${CTNR} machine start ${PODMANVM}
  fi
  break
done
###<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<### END setup-podmanVM.sh ###
