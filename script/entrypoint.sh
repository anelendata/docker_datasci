#!/usr/bin/env bash

# It requires env vars USER_NAME and USER_PASSWORD

########
# Add a user called ds

USER_HOME=/home/$USER_NAME
mkdir -p $USER_HOME
useradd $USER_NAME -d $USER_HOME
echo "$USER_NAME:$USER_PASSWORD" | chpasswd
chown $USER_NAME:$USER_NAME $USER_HOME


/usr/sbin/sshd -D

rstudio-server start

chmod +x /etc/init.d/jupyterhub
# Create a default config to /etc/jupyterhub/jupyterhub_config.py
jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py
# Start jupyterhub
service jupyterhub start
# Stop jupyterhub
# service jupyterhub stop
# Start jupyterhub on boot
# update-rc.d jupyterhub defaults
# Or use rcconf to manage services http://manpages.ubuntu.com/manpages/natty/man8/rcconf.8.html
# rcconf
