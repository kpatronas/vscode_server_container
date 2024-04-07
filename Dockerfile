# Use the official Ubuntu base image
FROM ubuntu:latest

# Configuration Arguments
ARG USERNAME=a_username
ARG GIT_USERNAME="First Last"
ARG GIT_EMAIL="mail@example.com"

# Update and install various deb packages, insert yours here
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates git \
    openssh-server iputils-ping coreutils sudo curl wget python3 python3-pip python3-dev build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install various Python libs, insert yours here
RUN pip3 install ibm_db sqlalchemy ibm_db_sa notebook pandas sshtunnel matplotlib

# Create a new user named ${USERNAME} and set a password
RUN useradd -m -s /bin/bash "${USERNAME}"
RUN echo "${USERNAME}:password" | chpasswd

# Add ${USERNAME} to sudoers without password
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/coder

# Change to ${USERNAME}
USER ${USERNAME}

# Create paths for SSH keys and hosts.d for additional hosts file
RUN mkdir -p /home/${USERNAME}/.ssh && mkdir -p /home/${USERNAME}/projects && sudo mkdir -p /etc/hosts.d

# Copy SSH key files to the .ssh directory, be sure you have copied your keys in the current directory
COPY id_rsa /home/${USERNAME}/.ssh/id_rsa
COPY id_rsa.pub /home/${USERNAME}/.ssh/id_rsa.pub
COPY hosts /etc/hosts.d/

# Set correct permissions for .ssh directory and its contents
RUN sudo chmod 700 /home/${USERNAME}/.ssh
RUN sudo chmod 600 /home/${USERNAME}/.ssh/id_rsa
RUN sudo chmod 644 /home/${USERNAME}/.ssh/id_rsa.pub

# Configure Git user
RUN git config --global user.name "${GIT_USERNAME}"
RUN git config --global user.email "${GIT_EMAIL}"

# Create a directory for code-server extensions
RUN mkdir -p /home/${USERNAME}/.local/share/code-server/extensions

# Install VSCode Server along with python and jupyter extensions, insert yours here
RUN curl -fsSL https://code-server.dev/install.sh | sh && \
    code-server --install-extension ms-python.python && \
    code-server --install-extension ms-toolsai.jupyter

# Expose ports for SSH and code-server
EXPOSE 8080 22

# Start SSH service and code-server on container startup
CMD sudo service ssh start && code-server --auth none --bind-addr 0.0.0.0:8080
