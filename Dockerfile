# Start from the official Jenkins LTS image with Java 21
FROM jenkins/jenkins:lts-jdk21

# Switch to root user for installing packages
USER root

# Update the package list and install dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    qemu-user-static \
    binfmt-support \
    && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin && \
    # register *all* QEMU binfmt handlers at build time
+   update-binfmts --enable qemu-aarch64 --enable qemu-arm \
    # Install AWS CLI v2
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    elif [ "$ARCH" = "arm64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    else \
        echo "Unsupported architecture: $ARCH"; \
        exit 1; \
    fi && \
    apt-get install -y unzip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip && \
    apt-get clean

COPY ./daemon.json /etc/docker/

# Ensure at runtime that the DinD daemon can actually exec QEMU
# (this only works if you launch this container with --privileged)
RUN chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap

# Set environment variable for BuildKit
ENV DOCKER_BUILDKIT=1

# Expose Jenkins ports
EXPOSE 8080 50000

# Set up Jenkins home volume
VOLUME /var/jenkins_home

# Set up Docker socket for Docker-in-Docker
VOLUME /var/run/docker.sock

# Set default Jenkins user back to Jenkins
#USER jenkins

# Entrypoint for Jenkins
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
