

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
