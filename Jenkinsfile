pipeline {
    agent any
    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        WATCHTOWER_TOKEN       = credentials('watchtower-token')
        DOCKER_BUILDKIT         = '1'
        DOCKER_CLI_EXPERIMENTAL = 'enabled'
        DOCKER_NAMESPACE        = 'ianmgg'
        IMAGE_NAME              = 'jenkins'
    }
    stages {
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
                        -t ${DOCKER_NAMESPACE}/${IMAGE_NAME}:latest \
                        --push .
                    '''
                }
            }
        }
        stage('Schedule Watchtower Update') {
            steps {
                script {
                    // One‑off container that sleeps 10m then notifies Watchtower
                    sh '''
                    docker run --rm \
                      busybox:1.35 \
                      sh -c "sleep 600 && \
                        wget -qO- \\
                          --header 'Authorization: Bearer $WATCHTOWER_TOKEN' \\
                          http://host.docker.internal:8081/v1/update?containers=jenkins"
                    '''
                }
            }
        }
    }
    post {
        always {
            // Clean up the Buildx builder
            sh 'docker buildx rm JenkinsDinDbuilder || true'
        }
    }
}
