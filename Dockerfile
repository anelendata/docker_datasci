# Pull base image.
FROM ubuntu:xenial

MAINTAINER Daigo Tanaka <daigo.tanaka@gmail.com>

# upgrade is not recommended by the best practice page
# RUN apt-get -y upgrade

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive

# Define locale
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

# Install dependencies via apt-get
# Note: Always combine apt-get update and install
RUN set -ex \
    && buildDeps=' \
        python-dev \
        python3-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libpq-dev \
    ' \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        sudo \
        apparmor-utils \
        python-setuptools \
        python-pip \
        python3-requests \
        python3-setuptools \
        python3-pip \
        mysql-client \
        mysql-server \
        libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        wget \
        git \
        openssh-server \
        postgresql postgresql-contrib \
        vim \
        gdebi-core \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

########
# SSH stuff

RUN mkdir -p /var/run/sshd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
# Or do this?
# RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN apt-get update && apt-get install -y r-base \
        # https://github.com/IRkernel/IRkernel
        libzmq3-dev \  
        # http://stackoverflow.com/questions/26445815/error-when-installing-devtools-package-for-r-in-ubuntu
        libcurl4-gnutls-dev \ 
        # http://stackoverflow.com/questions/20671814/non-zero-exit-status-r-3-0-1-xml-and-rcurl
        # libcurl4-openssl-dev \ 
        # http://stackoverflow.com/questions/20671814/non-zero-exit-status-r-3-0-1-xml-and-rcurl
        libxml2-dev && \  
    apt-get clean


########
# JDK

# Install JDK 8
RUN apt-get install -y openjdk-8-jdk
RUN ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/default-java
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH="$PATH:$JAVA_HOME/bin"


########
# Graphics
RUN apt-get update && apt-get install -y libcairo2-dev libxt-dev


########
# tini

RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean


########
# dbt
# https://dbt.readme.io

# RUN pip install -U pip setuptools \
RUN pip3 install dbt


########
# Airflow

ARG AIRFLOW_VERSION=1.9.0
ARG AIRFLOW_HOME=/usr/local/airflow

RUN pip3 install setuptools wheel

RUN useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip3 install Cython \
    && pip3 install pytz \
    && pip3 install pyOpenSSL \
    && pip3 install ndg-httpsclient \
    && pip3 install pyasn1 \
    && pip3 install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql]==${AIRFLOW_VERSION} \
    && pip3 install celery[redis]==4.1.1


########
# R env with RStudio Server
ARG RSTUDIO_SERVER_VERSION=1.1.453
RUN apt-get install -y r-base psmisc \
    && wget https://download2.rstudio.org/rstudio-server-${RSTUDIO_SERVER_VERSION}-amd64.deb \
    && gdebi --non-interactive rstudio-server-${RSTUDIO_SERVER_VERSION}-amd64.deb


########
# Anaconda and JupyterHub

ARG ANACONDA_PYTHON_VERSION=3
ARG ANACONDA_VERSION=5.2.0
ENV PATH="$PATH:/opt/conda/bin"

RUN apt-get update --fix-missing && \
    apt-get install -y bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1

RUN wget --quiet https://repo.anaconda.com/archive/Anaconda${ANACONDA_PYTHON_VERSION}-${ANACONDA_VERSION}-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc


# JupyterHub
RUN /opt/conda/bin/conda install -y -c conda-forge jupyterhub


########
# TODO: Redash

# This one could be on a separate Dockerfile and deployed together via docker-compose


########
# TODO: ungit


########
# Clean up

RUN apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base


########
# Install R packages

# prophet depends on rstan, but its installation in R fails for Ubuntu
# RUN Rscript -e "install.packages('rstan', repos = 'https://cloud.r-project.org/', dependencies=TRUE)")
# Workaround: https://github.com/stan-dev/rstan/issues/487#issuecomment-361355750
RUN apt-get update && apt-get -y install software-properties-common python-software-properties
RUN add-apt-repository -y "ppa:marutter/rrutter"
RUN add-apt-repository -y "ppa:marutter/c2d4u"
RUN apt-get update && apt-get -y install r-cran-rstan

RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile

RUN Rscript -e "install.packages(c('rJava', 'RJDBC', 'RCurl', 'bigrquery'), dependencies=TRUE)"
RUN Rscript -e "install.packages(c('dplyr', 'tidyr', 'stringr', 'dummies'), dependencies=TRUE)"
RUN Rscript -e "install.packages(c('knitr', 'ggplot2', 'ggthemes', 'gridExtra', 'rCharts'), dependencies=TRUE)"
RUN Rscript -e "install.packages(c('randomForest', 'xgboost'), dependencies=TRUE)"
RUN Rscript -e "install.packages('prophet', dependencies=TRUE)"
RUN Rscript -e "install.packages(c('caret', 'pmml'), dependencies=TRUE)"
RUN Rscript -e "install.packages('devtools', dependencies=TRUE)"
RUN Rscript -e "devtools::install_github('rstudio/bookdown')"


########
# Install conda packages

RUN conda install -y -c conda-forge tensorflow keras google-cloud-bigquery


########
# Wrapping up

COPY script/entrypoint.sh /entrypoint.sh
COPY script/start_airflow.sh /start_airflow.sh

COPY config/rserver.conf /etc/rstudio/rserver.conf
COPY config/jupyterhub /etc/init.d/jupyterhub
COPY script/setup_git.sh /setup_git.sh
COPY script/add_user.sh /add_user.sh

COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg
RUN chown -R airflow: ${AIRFLOW_HOME}

ARG AIRFLOW_LOG_DIR=/usr/local/airflow
RUN mkdir -p ${AIRFLOW_LOG_DIR}
RUN chown -R airflow: ${AIRFLOW_LOG_DIR}


# Standard SSH port
# 22: SSH
# 5555: Celery Flower to use in Airflow
# 8000: Jupyter Hub
# 8080: Airflow Web UI
# 8787: R Studio Server
# 8793: Airflow worker log server port
EXPOSE 22 5555 8000 8080 8787 8793

# USER airflow
# WORKDIR ${AIRFLOW_HOME}
 

ENTRYPOINT ["/entrypoint.sh"]
CMD ["worker"] # set default arg for entrypoint for Airflow setup
