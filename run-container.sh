#!/bin/bash

# Default values
IMAGE_NAME="cudrano/cuda-miniconda:latest"
CONTAINER_NAME="dynamic-user-container"
PROJECT_DIR="$(pwd)"  # Default to the current directory
CONDA_ENV_DIR="/multiverse/storage/cudrano/conda_envs/"  # Fixed path for Conda environments
DOCKER_ARGS=""

# Help message
print_help() {
    echo "Usage: run-container [OPTIONS]"
    echo ""
    echo "Run a Docker container with dynamic user and group setup for proper permissions."
    echo ""
    echo "Options:"
    echo "  --image <image_name>       Specify the Docker image to use (default: cudrano/cuda-miniconda:latest)."
    echo "  --name <container_name>    Specify the name for the running container (default: dynamic-user-container)."
    echo "  --project <project_dir>    Path to the project directory to mount (default: current directory)."
    echo "  --conda-envs <envs_dir>    Path to the directory where conda environments are stored (default: /multiverse/storage/cudrano/conda_envs/)."
    echo "  -h, --help                 Show this help message."
    echo ""
    echo "Additional arguments can be passed directly to Docker, e.g., '-p 8080:8080'."
    echo ""
    echo "Example:"
    echo "  run-container --project /path/to/project"
}

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --project)
            PROJECT_DIR="$2"
            shift 2
            ;;
        --conda-envs)
            CONDA_ENV_DIR="$2"
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            DOCKER_ARGS+="$1 "
            shift
            ;;
    esac
done

# Extract user and group info
USER_ID=$(id -u)
GROUP_ID=$(id -g)
USER_NAME=$(whoami)
USER_GROUPS=$(id -Gn | xargs -n1 getent group | awk -F: '{print $1":"$3}' | tr '\n' ',' | sed 's/,$//')

# Run the container
docker run --gpus all -it --rm \
    --name "${CONTAINER_NAME}" \
    -e USER_ID="${USER_ID}" \
    -e GROUP_ID="${GROUP_ID}" \
    -e USER_NAME="${USER_NAME}" \
    -e GROUPS="${USER_GROUPS}" \
    -v "${PROJECT_DIR}:/project" \
    -v "${CONDA_ENV_DIR}:/envs" \
    ${DOCKER_ARGS} \
    "${IMAGE_NAME}"
