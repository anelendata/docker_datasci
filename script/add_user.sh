#!/bin/bash

USER_HOME=/home/$1
mkdir -p $USER_HOME
useradd $1 -d $USER_HOME
echo "$1:$2" | chpasswd

mkdir -p /home/$1/bin
cp /setup_git.sh /home/$1/bin
cp /add_user.sh /home/$1/bin
chown -R $1:$1 $USER_HOME
