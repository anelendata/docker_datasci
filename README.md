# Anelen's Data Science environment docker image

Loaded with:

- JupyterHub
- RStudio Server with a lot of commonly used packages
- dbt
- git
- Airflow worker

## How to run

1. Install docker and docker-compose
2. Copy env_example to .env and edit
3. Edit volume section of docker-compose.yml
  - The path before ":" is an existing directory that will be visible to Jupyter and RStudio.
  - If you change USER_NAME in .env file, change the path after ":" accordingly.
4. Run `docker-compose up -d`
5. If running locally, point your browser to
  - Jupyter Hub http://localhost:8000
  - RStudio Server http://localhost:8787

* Port 8793 is reserved for Airflow worker.

## git

Before using git, set up git configuration by running:

```
$HOME/bin/setup_git.sh "Your Name" "your email"
```

You should use https protocol to pull and push to remote repository.


## TODOs

- Run Airflow in Docker swarm mode with
  [Airflow master node](https://github.com/puckel/docker-airflow)
- Connection to Spark
- Tensorflow

