# Deploying with Kubernetes

In the stand-alone mode, we managed to serve Jupyter Hub and RStudio.
After working with the data in those interactive environment, you may want to
automaticcally execute data workflow using Apache Airflow.

Here is an example to achieve a master-worker Airflow set up with
Google Kubernetes Engine.

We are using
@puckel's [docker-airflow](https://github.com/puckel/docker-airflow) image.
for the master node.

## Start a cluster

Create a cluster from
[Kubernetes clusters](https://console.cloud.google.com/kubernetes/list?).
As a test, 2 vCPUs with 7.5GB memory and node size = 1. Everything else can be
the default value.

## Fetch this repo

Go to [Cluster list](https://console.cloud.google.com/kubernetes/list), and
click on "Connect" button at the cluster. Follow the instruction to connect
to the cluster.

Then

```
cluster_host$ git clone https://github.com/anelendata/docker_datasci.git
```

```
cluster_host$ cd docker_datasci/kube
```

```
cluster_host$ kubectl create -f deploy/core
cluster_host$ kubectl create -f deploy/sshtunnel
cluster_host$ kubectl create -f deploy/suite
cluster_host$ kubectl create -f deploy/airflow
```

Go to [Workload](https://console.cloud.google.com/kubernetes/workload) page
and keep on clicking REFRESH button until you see stats=OK for all.

Alternatively, you can run

```
cluster_host$ kubectl get pods
```

to check. It may take a few minutes before worker deploy finishes because
the docker image has a few gigabytes.

Unfortunately, Kubernetes service overwrites the environment variables to locate
the postgres redis services within the cluster preconfigured at the container
level. So, it's a good idea to wait until all pods are ready before starting the
services. (Update: This problem is
[fixed](https://github.com/anelendata/docker_datasci/commit/1f6c753a).)

Once all pods are confirmed to be the running state, start the services:

```
cluster_host$ kubectl create -f service/core
cluster_host$ kubectl create -f service/sshtunnel
cluster_host$ kubectl create -f service/suite
cluster_host$ kubectl create -f service/airflow
```

Only bastion has the external IP availble and it may take a few minutes
before it's ready.

Go to [Services](https://console.cloud.google.com/kubernetes/discovery) page
and keep on clicking REFRESH button until you see stats=OK for all.

Alternatively, you can run

```
cluster_host$ kubectl get services
```

Make sure bastion service obtained an external IP before proceeding forward.

## Bastion server

Just as in the
[stand alone worker example](https://github.com/anelendata/docker_datasci/blob/master/README.md#set-up-ssh-keys),
the endpoints for Jupyter Hub and
RStudio are not exposed for the better security. You need to access through
an SSH tunnel.

To better manage the SSH tunnel, I am using @moul's [ssh portal](https://github.com/moul/sshportal).

In the cluster console,

```
cluster_host$ kubectl logs $(kubectl get  pod |grep bastion | cut -f 1 -d " ")
```

Find the line that says,

```
Admin user created, use the user 'invite:BpLnfgDsc2WD8F2q' to associate a public key with this account
```

Copy the invite:xxxx part.

Then from the local machine,

```
local_machine$ ssh <bastion external ip> -p 2222 -l invite:xxxx
```

<bastion external ip> can be found in Endpoints column on
[service list](https://console.cloud.google.com/kubernetes/discovery?&service_list_tablesize=50).

It will say something like:

```
Welcome admin!

Your key is now associated with the user "admin@sshportal".
Shared connection to <bastion external ip> closed.
```

Then from the local machine,

```
local_machine$ ssh <bastion external ip> -p 2222 -l admin
```

Then from the ssh shell,

```
config> host create --name <username on suite>_suite <username on suite>@suite
```

`<username on suite>` can be any registered user on the suite.
One user that should be always on worker is the one set as USER_NAME in the
[suite_deploy.yml](https://github.com/anelendata/docker_datasci/blob/master/kube/deploy/suite_deploy.yml)
(hopefully you changed the password!)

Exit the ssh once, and again from the local machine,

```
local_machine$ ssh <bastion external ip> -p 2222 -l admin key setup default
```

And copy the returned text to the clipboard. With OS X, you can

```
local_machine$ ssh <bastion external ip> -p 2222 -l admin key setup default | pbcopy
```

To achieve this.

Go back to the cluster,

```
cluster_host$ kubectl exec -it $(kubectl get  pod |grep suite | cut -f 1 -d " ") -- /bin/bash
```

Then in the shell,

```
sudo su <username>
cd
mkdir -p .ssh
<paste the command>
```

## Accessing the services through SSH tunnel

If you set up the SSH portal correctly as in the previous section, you should
be able to ssh to bastion server like this:

```
ssh <bastion external ip> -l <username on suite>_suite \
-L 8000:suite:8000 -L 8787:suite:8787 -L 8080:webserver:8080 -L 5555:flower:5555 -L 8793:worker:8793
```

The ports are forwarded, so as long as you maintain this SSH connection, you can point your browser to:

  - Jupyter Hub http://localhost:8000
  - RStudio Server http://localhost:8787
  - Airflow Web UI http://localhost:8080
  - Airflow's Celery Flower: http://localhost:5555

## Populating the dag files

The current set up use [hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)
to mount the host directory (/var/dags) to Airflow webserver, scheduler, and workers
at /usr/local/airflow/dags. The directory is empty at the deployment. So you
should bash into one of the worker instance and manually populate edit or
git-clone a repo you created to author the dags:

```
cluster_host$ kubectl exec -it $(kubectl get  pod |grep worker | cut -f 1 -d " ") -- /bin/bash
```

Then in the shell,

```
worker$ cd /usr/local/airflow/dags
worker$ git clone https://github.com/your_account/your_dags_repo
```

for example.

It may take a little before you see the added dags in the Airflow dashboard.

## Tips

### Log file size management

Airflow scheduler logs may use up disk space. Here is a handy command to delete
the logs older than 7 days:

```
cd kube/kubectl
./exec scheduler "find /usr/local/airflow/logs/*/* -type f  -mtime +7"
```

For worker log clean up, refer to @teamclairvoyant 's
[airflow-maintenance-dags](https://github.com/teamclairvoyant/airflow-maintenance-dags)

Airflow webserver container's logging very chatty by default.


## TODOs

- Client-side LDAP support (suite)

