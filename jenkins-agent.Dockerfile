FROM jenkins/inbound-agent:latest-jdk21

USER root

# Install Docker CLI, Git, and other dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    qemu-user-static \
    binfmt-support \
    sudo \
    git && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin && \
    apt-get clean

# Configure Git
RUN git config --system user.email "jenkins@example.com" && \
    git config --system user.name "Jenkins" && \
    git config --system core.longpaths true

# Create directory for Docker config
RUN mkdir -p /home/jenkins/.docker && \
    chown -R jenkins:jenkins /home/jenkins/.docker

# Create a startup script to fix Docker socket permissions and prepare workspace
RUN echo '#!/bin/bash\n\
# Fix Docker socket permissions\n\
if [ -S /var/run/docker.sock ]; then\n\
  DOCKER_GID=$(stat -c "%g" /var/run/docker.sock)\n\
  if [ "$DOCKER_GID" != "0" ]; then\n\
    if ! getent group $DOCKER_GID > /dev/null; then\n\
      groupadd -g $DOCKER_GID docker-external\n\
    fi\n\
    usermod -aG $DOCKER_GID jenkins\n\
  fi\n\
  chmod 666 /var/run/docker.sock\n\
fi\n\
\n\
# Ensure workspace directory exists and has correct permissions\n\
mkdir -p /home/jenkins/agent/workspace\n\
chown -R jenkins:jenkins /home/jenkins/agent\n\
\n\
# Execute the original entrypoint\n\
exec /usr/local/bin/jenkins-agent "$@"' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Add jenkins to sudoers for the startup script
RUN echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch back to jenkins user
USER jenkins

# Set Docker experimental features and buildkit
ENV DOCKER_CLI_EXPERIMENTAL=enabled \
    DOCKER_BUILDKIT=1

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
