#!/usr/bin/env bash

# It requires env vars USER_NAME and USER_PASSWORD

echo "Setting up the the user $USER_NAME"

########
# Add a user called ds

bash /add_user.sh $USER_NAME $USER_PASSWORD

usermod -aG sudo $USER_NAME

echo "Done setting up the admin user $USER_NAME"

########
# Start RStudio Server

rstudio-server start

echo "Started rstudio-server"


########
# Start JupyterHub

chmod +x /etc/init.d/jupyterhub
# Create a default config to /etc/jupyterhub/jupyterhub_config.py
mkdir -p /etc/jupyterhub
jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py
# Start jupyterhub
service jupyterhub start
# Stop jupyterhub
# service jupyterhub stop
# Start jupyterhub on boot
# update-rc.d jupyterhub defaults
# Or use rcconf to manage services http://manpages.ubuntu.com/manpages/natty/man8/rcconf.8.html
# rcconf

echo "Started JupyterHub"


########
# Start Airflow

su airflow -c "/start_airflow.sh $1"

echo "Started Airflow $1"


########
# Start sshd

/usr/sbin/sshd -D

echo "Started sshd"
