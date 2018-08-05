#!/usr/bin/env bash

# This script requires env vars USER_NAME and USER_PASSWORD

# TODO: Move this to Dockerfile
sudo mkdir -p /mnt/disk1/home
sudo mv /home /home_org
sudo ln -s /mnt/disk1/home /home
sudo mkdir -p /mnt/disk1/airflow/dags
sudo mv $AIRFLOW_HOME/dags $AIRFLOW_HOME/dags_org
sudo ln -s /mnt/disk1/airflow/dags $AIRFLOW_HOME/dags

echo "Setting up the the user $USER_NAME"

if [[ -z "$USER_NAME" && -z "$USER_PASSWORD" ]]
then
    echo "You need to set env variables USER_NAME and USER_PASSWORD"
    exit
fi

########
# Add a user called ds

bash /add_user.sh $USER_NAME $USER_PASSWORD

usermod -aG sudo $USER_NAME

echo "Done setting up the admin user $USER_NAME"

########
# Start RStudio Server

if [[ "${START_RSTUDIO:=no}" == "yes" ]]
then
  rstudio-server start
  echo "Started rstudio-server"
fi

########
# Start JupyterHub

chmod +x /etc/init.d/jupyterhub
# Create a default config to /etc/jupyterhub/jupyterhub_config.py
mkdir -p /etc/jupyterhub
jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py
# Start jupyterhub

if [[ "${START_JUPYTERHUB:=no}" == "yes" ]]
then
  service jupyterhub start
  echo "Started JupyterHub"
fi

# How to stop jupyterhub
# service jupyterhub stop
# Start jupyterhub on boot
# update-rc.d jupyterhub defaults
# Or use rcconf to manage services http://manpages.ubuntu.com/manpages/natty/man8/rcconf.8.html
# rcconf


########
# Start Airflow

if [[ "${START_AIRFLOW:=no}" == "yes" ]]
then
  su airflow -c "/start_airflow.sh $1"
  echo "Started Airflow $1"
fi


########
# Start sshd

/usr/sbin/sshd -D

echo "Started sshd"
