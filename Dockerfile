# Base image with CUDA and Python installed
# FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04
FROM nvidia/cuda:12.2.2-cudnn8-devel-ubuntu20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/miniconda/bin:$PATH"
ENV CONDA_ENVS_PATH="/envs"

# Install basic utilities and gosu for safe user switching
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    git \
    bzip2 \
    zip \
    unzip \
    sudo \
    vim \
    less \
    gosu \
    cmake \
    build-essential \
    ca-certificates

# Install Miniconda
# Latest (supports only Python 3.9+)
# RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
# Support for python 3.8
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py39_23.11.0-2-Linux-x86_64.sh -O /tmp/miniconda.sh && \  
    bash /tmp/miniconda.sh -b -p /opt/miniconda && \
    rm /tmp/miniconda.sh

# Update pip and setuptools
RUN /opt/miniconda/bin/pip install --upgrade pip setuptools

# Install extra apt dependencies
ADD apt_requirements.txt /apt_requirements.txt
RUN apt-get update && cat /apt_requirements.txt | xargs apt-get install -y 
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Create directories for environments
RUN mkdir -p /exp /envs && \
    chmod -R 777 /exp /envs

# Add entrypoint script to create user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# Add entrypoint script to create user
COPY entrypoint.sh /usr/local/bin/entrypoint-vscode.sh
RUN chmod 755 /usr/local/bin/entrypoint-vscode.sh

# Set default bashrc
COPY bashrc /etc/bash.bashrc
RUN chmod 644 /etc/bash.bashrc

# Default to bash
CMD ["bash"]

USER 0
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

WORKDIR /exp
