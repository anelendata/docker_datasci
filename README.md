# Anelen's Data Science environment docker image

[Docker Hub page](https://hub.docker.com/r/anelen/datasci/)

Loaded with:

- [Jupyter Hub](https://jupyterhub.readthedocs.io/)
- [Anaconda 3](https://anaconda.org)
- [RStudio Server](https://www.rstudio.com) with a lot of commonly used packages
- [dbt](https://dbt.readme.io)
- [Apache Airflow](https://airflow.apache.org/) worker
- [git](https://git-scm.com/)


## How to run

1. Clone this repo
2. Install [docker and docker-compose](https://docs.docker.com/compose/install/)
3. Copy env_example to .env and edit
4. Edit volume section of docker-compose.yml
  - The path before ":" is an existing directory that will be visible to Jupyter and RStudio.
  - If you change USER_NAME in .env file, change the path after ":" accordingly.
5. Run `docker-compose up -d`
6. If running locally, point your browser to
  - Jupyter Hub http://localhost:8000
  - RStudio Server http://localhost:8787

* Port 8793 is reserved for Airflow worker.

## git

Before using git, set up git configuration by running:

```
$HOME/bin/setup_git.sh "Your Name" "your email"
```

You should use https protocol to pull and push to remote repository.


## Multiple Jupyter Hub/RStudio users

1. Edit volume section of docker-composer.yml to mount host's directory to :/home (Instead of /home/ds for example)
2. Shell into the container as root by `docker exec -it <container_id> /bin/bash
3. Add user by
```
mkdir -p /home/<user_name>
useradd <user_name> -d /home/<user_name>
chown -r <user_name>: /home/<user_name>
echo <user_name>:<initial_password> | chpasswd
```
4. The user can change their password with `passwd` command on the terminal on
   [Jupyter Hub](http://localhost:8000/user/ds/terminals/1) or RStudio


## Running on Google Cloud Platform

As I write this, GCP Compute Engine's container support does not have
docker-compose. It does not support port forwarding or volume mapping.

### Create a Compute Engine VM instance

Example setting:

1. Choose 2 vCPUs 7.5GB memory
2. Do NOT check "Deploy a container image to this VM instance"
3. Choose Boot disk to one of Container Optimized OS images
4. Set boot disk size: 20GB
5. Allow HTTP & HTTPS traffic
6. Disk: Add 50GB. Make it persisting.
7. Network tags: datasci-box

### SSH into the box

You can do the following with [the browser-based terminal](https://cloud.google.com/compute/docs/ssh-in-browser)
GCP provides from the VM instances.

```
sudo docker run -d -v /home:/home \
    -p 8000:8000 -p 8787:8787 -p 8793:8793 \
    -e USER_NAME=<some_username> -e USER_PASSWORD=<strong_password> \
    --name datasci anelen/datasci
```

While you are here, note your user name:

(Do this outside the container)

```
echo $USER
```

### Set up ssh keys

You probably don't want to expose the services externally, so I will show how
to connect to the services using [ssh tunneling](https://www.ssh.com/ssh/tunneling/example).

If you have not, generate a project-wide ssh key:

```
ssh-keygen -t rsa -f ~/.ssh/[KEY_FILENAME] -C [USERNAME]
```

Note: USERNAME is not your email address. You have it if you followed the
last instruction of the previous section.

Add the content of the public key (~/.ssh/[KEY_FILENAME].pub) as
[project-wide meta key](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys#project-wide)

### Connect to the services via ssh tunnel

On your local computer, start the port fowarding by

```
ssh -L 8000:localhost:8000 -L 8787:localhost:8787 [USERNAME]@<instance_external_ip_address>
```

Then point your browser to
- Jupyter Hub http://localhost:8000
- RStudio Server http://localhost:8787

### Restarting the VM instance

If you persisted the boot disk or mounted a persisting disk, you can restart
the instance and recover the previous state. (If you didn't delete the VM
instance, of course.)

After restarting the VM instance, run the ssh command as in the previous section,
then

```
sudo docker start datasci
```

## TODOs

- Run Airflow in Docker swarm mode with
  [Airflow master node](https://github.com/puckel/docker-airflow)
- Connection to Spark
