# Pull base image.
FROM ubuntu:xenial

MAINTAINER Daigo Tanaka <daigo.tanaka@gmail.com>

# upgrade is not recommended by the best practice page
# RUN apt-get -y upgrade

ARG DS_HOME=/home/ds
RUN useradd ds -d $DS_HOME && echo "ds:ds" | chpasswd 

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
        python3-pip \
        python3-requests \
        # mysql-client \
        # mysql-server \
        # default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
        wget \
        git \
        openssh-server \
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



########
# R env with RStudio Server
RUN apt-get install -y r-base psmisc \
    && wget https://download2.rstudio.org/rstudio-server-1.1.453-amd64.deb \
    && gdebi rstudio-server-1.1.453-amd64.deb

########
# Python data science env with Jupyter Notebook

# Jupyter Notebook



########
# Airflow

# ARG AIRFLOW_VERSION=1.9.0
# ARG AIRFLOW_HOME=/usr/local/Airflow

# RUN useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
#     && pip install -U pip setuptools wheel \
#     && pip install Cython \
#     && pip install pytz \
#     && pip install pyOpenSSL \
#     && pip install ndg-httpsclient \
#     && pip install pyasn1 \
#     && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql]==$AIRFLOW_VERSION \
#     && pip install celery[redis]==4.1.1 \


########
# ungit


########
# dbt


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
# Wrapping up

COPY script/entrypoint.sh /entrypoint.sh

# Standard SSH port
# 22: SSH
# 8787: R Studio Server
# 8080:
# 5555:
# 8793:
EXPOSE 22 8787 8080 5555 8793

# Airflow
# COPY script/entrypoint.sh /entrypoint.sh
# COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg
# 
# RUN chown -R airflow: ${AIRFLOW_HOME}
# 
# EXPOSE 8080 5555 8793
# 
# USER airflow
# WORKDIR ${AIRFLOW_HOME}
# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["webserver"] # set default arg for entrypoint
 
# USER ds
# WORKDIR ${DS_HOME}

# CMD ["webserver"] # set default arg for entrypoint
# CMD ["/usr/sbin/sshd", "-D"]

ENTRYPOINT ["/entrypoint.sh"]
