FROM jenkins/inbound-agent:latest-jdk21

USER root

# Install Docker CLI and dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    qemu-user-static \
    binfmt-support && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin && \
    apt-get clean

# Create directory for Docker config
RUN mkdir -p /home/jenkins/.docker && \
    chown -R jenkins:jenkins /home/jenkins/.docker

# Switch back to jenkins user
USER jenkins

# Set Docker experimental features and buildkit
ENV DOCKER_CLI_EXPERIMENTAL=enabled \
    DOCKER_BUILDKIT=1
