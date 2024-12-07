# Base image with CUDA and Python installed
FROM <username>/cuda-miniconda:latest

# Add entrypoint script to create user
COPY entrypoint.sh /usr/local/bin/entrypoint-vscode.sh
RUN chmod 755 /usr/local/bin/entrypoint-vscode.sh

# Default to bash
CMD ["bash"]

USER 0
ENTRYPOINT ["/usr/local/bin/entrypoint-vscode.sh"]

WORKDIR /exp
