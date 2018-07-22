# Deploying with Docker Swarm

## Prepare Swarm

- [Getting started with swarm mode](https://docs.docker.com/engine/swarm/swarm-tutorial/)
- [Create a swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/)
- [Add nodes to the swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/add-nodes/)

(Don't deploy a service yet)

```
mkdir /var/home
mkdir /var/pgdata
mkdir /var/dag
```

## Environment file

```
mv env_example .env
```

Don't forget to edit the file to change the sensitive information!

## docker-compose file

The example docker-commpose file (docker-compose-CeleryExecutor-swarm.yml)
assumes there is a master and worker node, and shows how to deploy:

- postgres, redis, airflow webserver, flower, and scheduler on the master node
- suite (= Jupyter Hub and R Studio Server) and Airflow worker on the worker node.

Edit docker-compose-CeleryExecutor-swarm.yml file by replacing master-node and
worker-node with appropriate host names.

## Deploy

```
docker stack deploy --compose-file=docker-compose-CeleryExecutor-swarm.yml datasci
```

## Shutdown

```
docker stack rm datasci
```

## Issue

Docker Swarm seems to have an issue looking up
[external domain names](https://github.com/clearcontainers/runtime/issues/121)
