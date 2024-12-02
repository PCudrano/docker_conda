# Dockerized Miniconda Environment with User Privilege Mapping

## Overview

This project provides a user-agnostic Docker image that allows users to run containers with their user and group privileges automatically mapped inside the container at runtime. This means that the same docker image can be shared by all users.<br> 
This image also includes Miniconda for managing Python environments and the provided setup maps every conda environment to a permanent storage location, which ensures that conda environments can be used and modified within the container while also persisting across container restarts.

Key features:

- **Automatic User Privilege Mapping**: The container dynamically maps the host user's UID and GID, along with their group memberships, ensuring proper file permissions and access control.
- **Persistent Conda Environments**: Conda environments are stored in a mounted volume, allowing them to persist even when the container is stopped or recreated.
- **Single Image for Multiple Users and Projects**: Build the image once and use it across different users and projects, saving disk space and time.
- **Pre-installed Basic Packages**: Essential `apt` packages and utilities are pre-installed. Additional packages can be added as needed by extending this image.

## Getting Started

### Building the Docker Image

To build the Docker image, run in this directory:

```bash
docker build -t $(whoami)/cuda-miniconda:latest .
```

This command builds the Docker image using the `Dockerfile` in the current directory and tags it as `<username>/cuda-miniconda:latest`.

### Running the Docker Container

Use the `run-docker-conda` script to run the container.
`run-docker-conda` command behaves exactly as `run-docker`, accepting the same CLI arguments. 
It automatically mounts the current directory as `/exp`, and can be fed with an optional `.runconfigs` at need.
Additional arguments are presented below.

Basic example:

```bash
./run-docker-conda '' '0-3' /bin/bash
```
opens a bash shell in your container running on CPU 0-3 and no GPU.

**Note**: Ensure the `run-docker-conda` script is executable by running

```bash
chmod +x run-docker-conda
```
before using it.

#### Optional: Installing `run-docker-conda`

You can also install this script in your local bin folder to be able to run it from every directory.
Run:
```bash
cp run-docker-conda ~/.local/bin/run-docker-conda
```
and make sure that `.local/bin` is in your path by adding this line to your `~/.bashrc`:
```bash
export PATH=$HOME/.local/bin:${PATH:+:${PATH}}
```
Now you can just run `run-docker-conda` from any directory!


### Additional arguments for `run-docker-conda`

```bash
Usage: run-docker-conda [OPTIONS] <gpu-list> <cpu-list> <command>
```

#### Options:

- **`--image <image_name>`**: Specify the Docker image to use (default: `<username>/cuda-miniconda:latest`).
- **`--name <container_name>`**: Specify the name for the running container. If not provided, the default name set by `run-docker` will be used.
- **`--project <project_dir>`**: Path to the project directory to mount in `/exp` (default: current directory, as with `run-docker`).
- **`--conda-envs <envs_dir>`**: Path to the directory where your conda environments are stored (default: `/multiverse/storage/<username>/conda_envs/`). This is used to persist conda environments across runs.
- **`--docker-args <args>`**: Additional arguments to pass to Docker, as with `run-docker`. These can include port mappings, environment variables, or other Docker runtime options.
- **`-h, --help`**: Show the help message detailing usage and options.

Additionally, any option specified in a `.runconfigs` file will be loaded directly by `run-docker`.

#### Positional Arguments:

As for command `run-docker`:

- **`<gpu-list>`**: Comma-separated list of GPUs to use. Leave empty (`''`) for no GPU restriction.
- **`<cpu-list>`**: Comma-separated list of CPU cores to use. Leave empty (`''`) for no CPU restriction.
- **`<command>`**: Command to run inside the container (default: `'bash'`). This can be any command, such as running a script or launching a Python shell.

### Using Conda Inside the Container

In your container, you can use conda seemlessly to create new environmnets and update them over time. 
Your conda environments are mounted in `/envs` inside your container, and permanently stored in storage (default: `/multiverse/storage/<username>/conda_envs/`). This ensures that any environments you create or modify will persist across container restarts.

#### Creating a New Conda Environment

1. **Initialize Conda (if needed)**:

   ```bash
   conda init bash
   exec bash
   ```

2. **Create the Environment**:

   ```bash
   conda create -n myenv python=3.9
   ```

   Replace `myenv` with your desired environment name and `python=3.9` with the desired Python version.

3. **Activate the Environment**:

   ```bash
   conda activate myenv
   ```

#### Activating an Existing Conda Environment

If you already have existing environments, you can activate them directly:

```bash
conda activate existing_env_name
```

#### Installing Packages in a Conda Environment

With the environment activated, install packages using `conda` or `pip`:

- **Using Conda**:

  ```bash
  conda install numpy pandas
  ```

- **Using Pip**:

  ```bash
  pip install numpy pandas
  ```
  **Note**: If you use Pip to install a package in your environment, you **cannot** use `conda install` later on in that environment, due to conda internal functioning.

## Customization and Editing

### File Overview

- **`Dockerfile`**: Builds the Docker image. Contains instructions for installing packages and configuring the environment.
- **`entrypoint.sh`**: An entrypoint script that runs when the container starts. It sets up the user and group inside the container to match those on the host system.
- **`apt_requirements.txt`**: A plain text file listing additional `apt` packages to install.
- **`bashrc`**: Contains custom Bash configurations, aliases, and environment settings.
- **`run-docker-conda`**: A script to run the Docker container with the appropriate settings, including user and group mappings.

### Changing CUDA version

To change CUDA version you'll need to build a new image from scratch chosing a different base image.
This can be changed editing the first line in your Dockerfile:

```
FROM nvidia/cuda:12.2.0-base-ubuntu20.04
```

### Extending and Customizing the Docker Image

Once you have built the base Docker image, you can extend and customize it without having to rebuild the entire image from scratch. This approach is efficient and allows for adding new functionalities as needed for specific projects.

#### Adding New `apt` Requirements

If you need additional `apt` packages, you can extend the existing image adding your new packages to `apt-requirements.txt` and creating a new Dockerfile to extend this image.

1. **Create a New Dockerfile**:

   ```dockerfile
   FROM <username>/cuda-miniconda:latest

   # Install extra apt dependencies
   ADD apt_requirements.txt /apt_requirements.txt
   RUN apt-get update && cat /apt_requirements.txt | xargs apt-get install -y 
   RUN apt-get clean && rm -rf /var/lib/apt/lists/*
   ```

2. **Build the Extended Docker Image**:

   ```bash
   docker build -t <username>/cuda-miniconda:custom_apt .
   ```

This way, you can extend the base image by installing extra packages without altering the original.

#### Customizing Bash Configurations

If you want to add or modify shell behavior, such as adding aliases or environment variables, you can edit the provided `bashrc` and create a new Dockerfile to extend this image.

1. **Create a New Dockerfile**:

   ```dockerfile
   FROM <username>/cuda-miniconda:latest

   # Copy your custom bashrc file
   COPY bashrc /etc/bash.bashrc
   RUN chmod 644 /etc/bash.bashrc
   ```

2. **Build the Extended Docker Image**:

   ```bash
   docker build -t cudrano/cuda-miniconda:custom-bash .
   ```

**Note**: The `bashrc` file is copied to `/etc/bash.bashrc` inside the container and is applied globally to all users.


### Understanding `entrypoint.sh`

The `entrypoint.sh` script performs several key functions when the container starts:

- **User and Group Creation**:

  - Checks if the user's UID and GID exist inside the container and creates them if they don't.
  - Maps the host user's groups into the container to ensure proper permissions.

- **Ownership of Mounted Directories**:

  - Adjusts ownership of `/exp` and `/envs` to match the user, ensuring read/write permissions.

- **Suppressing Login Messages**:

  - Creates a `.hushlogin` file to suppress login messages for a clean shell prompt.

- **Switching to Non-Root User**:

  - Uses `gosu` to switch from the root user to the mapped user before executing the provided command.

## Contributing and Extending

Feel free to customize and extend this setup to suit your needs. You can create new images based on this one by adding additional instructions.

- **Creating Derived Images**:

  Use this image as a base in your own `Dockerfile`:

  ```dockerfile
  FROM <username>/cuda-miniconda:latest

  # Install additional packages or configurations
  ```

- **Submitting Improvements**:

  If you make improvements that could benefit others, consider sharing them.
