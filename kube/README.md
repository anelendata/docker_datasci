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
cluster_host$ kubectl create -f deploy
cluster_host$ kubectl create -f service
```

Go to [Workload](https://console.cloud.google.com/kubernetes/workload) page
and keep on clicking REFRESH button until you see stats=OK for all.

Alternatively, you can run

```
cluster_host$ kubectl get pods
```

to check. It may take a few minutes before worker deploy finishes because
the docker image has a few gigabytes.

## Bastion server

Just as in the
[stand alone worker example](https://github.com/anelendata/docker_datasci/blob/master/README.md#set-up-ssh-keys),
the endpoints for Jupyter Hub and
RStudio are not exposed for the better security. You need to access through
an SSH tunnel.

To better manage the SSH tunnel, I am using @moul's[ssh portal](https://github.com/moul/sshportal).

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
config> host create --name <username on worker>_suite <username on suite>@suite
```

<username on suite> can be any registered user on the suite.
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

Finally from the local machine, you can

```
ssh <bastion external ip> -l <username on suite>_suite \
-L 8000:suite:8000 -L 8787:suite:8787 -L 8080:webserver:8080 -L 5555:flower:5555
```

To directly ssh into suite. The port 8000 and 8787 are forwarded, so as long
as you maintain this SSH connection, you can point your browser to:

  - Jupyter Hub http://localhost:8000
  - RStudio Server http://localhost:8787
  - Airflow Web UI http://localhost:8080
  - Airflow's Celery Flower: http://localhost:5555