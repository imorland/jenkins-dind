pipeline {
    agent {
        label 'multiarch'  // Use any agent with the 'multiarch' label
    }
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        WATCHTOWER_TOKEN       = credentials('watchtower-token')
        DOCKER_BUILDKIT         = '1'
        DOCKER_CLI_EXPERIMENTAL = 'enabled'
        DOCKER_NAMESPACE        = 'ianmgg'
        JENKINS_IMAGE_NAME      = 'jenkins'
        AGENT_IMAGE_NAME        = 'jenkins-agent'
    }
    stages {
        stage('Prepare Workspace') {
            steps {
                // Clean workspace and initialize git
                sh '''
                rm -rf .git || true
                git init
                git config --global --add safe.directory "*"
                git remote add origin https://github.com/imorland/jenkins-dind.git
                git fetch --depth 1 origin master
                git checkout FETCH_HEAD
                '''
            }
        }
        stage('Set up QEMU and Docker Buildx') {
            steps {
                script {
                    sh 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
                    sh '''
                    docker buildx create --name JenkinsDinDbuilder --use || true
                    docker buildx inspect JenkinsDinDbuilder --bootstrap
                    '''
                }
            }
        }
        stage('Build and Push Jenkins DinD Image') {
            steps {
                script {
                    sh 'echo $DOCKER_HUB_CREDENTIALS_PSW | docker login -u $DOCKER_HUB_CREDENTIALS_USR --password-stdin'
                    sh '''
                    docker buildx build \
                        --platform linux/amd64,linux/arm64 \
                        -t ${DOCKER_NAMESPACE}/${JENKINS_IMAGE_NAME}:latest \
                        --push .
                    '''
                }
            }
        }
        stage('Build and Push Jenkins Agent Image') {
            steps {
                script {
                    sh '''
                    docker buildx build \
                        --platform linux/amd64,linux/arm64 \
                        -t ${DOCKER_NAMESPACE}/${AGENT_IMAGE_NAME}:latest \
                        -f jenkins-agent.Dockerfile \
                        --push .
                    '''
                }
            }
        }
        stage('Schedule Watchtower Update') {
            steps {
                script {
                    // One‑off container that sleeps 2m then notifies Watchtower
                    sh '''
                    docker run -d --rm \
                      busybox:1.35 \
                      sh -c "sleep 120 && \
                        wget -qO- \\
                          --header 'Authorization: Bearer $WATCHTOWER_TOKEN' \\
                          http://host.docker.internal:8081/v1/update?containers=jenkins,jenkins-agent1,jenkins-agent2"
                    '''
                }
            }
        }
    }
    post {
        always {
            node(env.NODE_NAME) {
                // Clean up the Buildx builder
                sh 'docker buildx rm JenkinsDinDbuilder || true'
            }
        }
    }
}
