#!/bin/bash
REMOTE_SERVER=$1
REMOTE_PATH=$2
KERNEL=$3

function cleanup {
    sudo umount /data/pacman/repo
    [[ -f /.dockerenv ]] && rm -rf ~/.ssh
    [[ -f /.dockerenv ]] && rm -rf ~/.gnupg
}
trap cleanup EXIT

# change repo name
sed -i 's/repo_basename="archzfs"/repo_basename="archzfs-ci"/' conf.sh

# import gpg key
[[ -f /.dockerenv ]] && gpg --import ~/.gpg/gpg_key
key=$(gpg --list-keys --with-colons | awk -F: '/^pub:/ { print $5 }')
sed -i "s/gpg_sign_key='0EE7A126'/gpg_sign_key='${key}'/" conf.sh

# mount remote repo and add packages
sudo mkdir -p /data/pacman/repo
sudo chown buildbot:buildbot /data/pacman/repo
ssh "${REMOTE_SERVER}" echo 'can connect to repo server!'    && \
sshfs "${REMOTE_SERVER}:${REMOTE_PATH}" /data/pacman/repo -C && \
mkdir -p /data/pacman/repo/{archzfs-ci,archzfs-ci-archive}   && \
./repo.sh 'common' azfs                                      && \
./repo.sh 'common-git' azfs                                  && \
./repo.sh "${KERNEL}" azfs
