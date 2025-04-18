

## Building locally
```
docker build -t ianmgg/jenkins .
```

Or for multi platform:
```
export DOCKER_BUILDKIT=1
docker buildx create --name mybuilder --use
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t ianmgg/jenkins:latest \
    --push .
```

### Running
```
docker run -d \
    --name jenkins \
    --restart always \
    --privileged \
    --memory=16g \
    -p 8088:8080 \
    -p 50000:50000 \
    -v jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    ianmgg/jenkins
```
# Jenkins Docker-in-Docker (DinD) Setup

This repository contains configuration files for setting up a Jenkins server with Docker-in-Docker capabilities and multi-architecture build support. The setup includes a Jenkins master and agent containers that can build Docker images for both x64 (amd64) and arm64 architectures.

## Overview

This setup provides:

- Jenkins master with Docker capabilities
- Jenkins agents with Docker and multi-architecture build support
- Automatic updates via Watchtower
- Support for building x64 and arm64 Docker images

## Components

### Docker Images

- **Jenkins Master** (`ianmgg/jenkins:latest`): Custom Jenkins image with Docker CLI, BuildX, and AWS CLI
- **Jenkins Agent** (`ianmgg/jenkins-agent:latest`): Custom agent image with Docker CLI, BuildX, and QEMU for multi-architecture builds

### Configuration Files

- `Dockerfile`: Defines the Jenkins master image
- `jenkins-agent.Dockerfile`: Defines the Jenkins agent image
- `Jenkinsfile`: CI/CD pipeline for building and pushing the Docker images
- `daemon.json`: Docker daemon configuration for BuildKit support
- `docker-compose.yml`: Orchestrates the deployment of Jenkins master, agents, and Watchtower

## Setup Instructions

### Prerequisites

- Docker and Docker Compose installed
- Git installed
- A Docker Hub account (for pushing images)

### Deployment Steps

1. **Clone this repository**:
   ```bash
   git clone https://github.com/imorland/jenkins-dind.git
   cd jenkins-dind
   ```

2. **Configure Jenkins credentials**:
   - Create a Docker Hub credentials entry in Jenkins with ID `docker-hub-credentials`
   - Create a Watchtower token credentials entry in Jenkins with ID `watchtower-token`

3. **Deploy the stack**:
   ```bash
   docker-compose up -d
   ```

4. **Access Jenkins**:
   - Open a browser and navigate to `http://localhost:8088`
   - Follow the initial setup instructions
   - Install recommended plugins

5. **Configure Jenkins agents**:
   - Go to "Manage Jenkins" > "Manage Nodes and Clouds"
   - Add a new node with name "agent1" and label "multiarch"
   - Set the launch method to "Launch agent by connecting it to the master"
   - Save the configuration and copy the agent secret
   - Update the `JENKINS_SECRET` in your docker-compose.yml file
   - Repeat for "agent2" if needed

6. **Restart the stack with updated secrets**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Multi-Architecture Build Support

This setup supports building Docker images for both x64 (amd64) and arm64 architectures using:

- QEMU for architecture emulation
- Docker BuildX for multi-architecture builds
- Jenkins pipeline with multi-architecture build configuration

The Jenkinsfile includes stages for:
1. Setting up QEMU and Docker BuildX
2. Building and pushing the Jenkins master image for multiple architectures
3. Building and pushing the Jenkins agent image for multiple architectures
4. Triggering Watchtower to update the running containers

## Docker Compose Configuration

The `docker-compose.yml` file defines:

- **Jenkins Master**: Exposes ports 8088 (web UI) and 50000 (agent communication)
- **Jenkins Agent**: Connects to the master using JNLP with the provided secret
- **Watchtower**: Monitors and automatically updates the containers

Key configuration aspects:
- Docker socket is mounted to enable Docker-in-Docker functionality
- Agent workspace directories are mounted for persistence
- Init process is enabled for proper subprocess handling
- Agents run as root to manage Docker socket permissions

## Maintenance

### Updating Images

The images are automatically rebuilt and pushed to Docker Hub using the Jenkins pipeline. To trigger a rebuild:

1. Make changes to the Dockerfile or jenkins-agent.Dockerfile
2. Commit and push the changes to the repository
3. Run the Jenkins pipeline job

Watchtower will automatically update the running containers after the new images are pushed.

### Troubleshooting

- **Docker permission issues**: Ensure the Docker socket is properly mounted and accessible
- **Agent connection issues**: Verify the agent secrets and network connectivity
- **Build failures**: Check the Jenkins logs for specific error messages

## Security Considerations

- Running containers with Docker socket access has security implications
- The agents run as root to manage Docker socket permissions
- Consider implementing more restrictive security measures in production environments
