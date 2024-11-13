pipeline {
    agent {
        // Use a Docker-in-Docker setup
        docker { image 'docker:20.10.24' }
    }
    environment {
        DOCKER_BUILDKIT = "1"
        DOCKER_CLI_EXPERIMENTAL = "enabled"
        DOCKER_NAMESPACE = "ianmgg"
        IMAGE_NAME = "jenkins"
    }
    stages {
        stage('Setup Buildx') {
            steps {
                script {
                    // Set up Docker Buildx if not already available
                    sh '''
                    docker buildx create --name mybuilder --use || true
                    docker buildx inspect mybuilder --bootstrap
                    '''
                }
            }
        }
        stage('Build and Push Jenkins DinD Image') {
            steps {
                script {
                    // Build and push multi-platform image
                    sh '''
                    docker buildx build \
                        --platform linux/amd64,linux/arm64 \
                        -t ${DOCKER_NAMESPACE}/${IMAGE_NAME}:latest \
                        --push .
                    '''
                }
            }
        }
    }
    post {
        always {
            script {
                // Clean up builder
                sh 'docker buildx rm mybuilder || true'
            }
        }
    }
}
