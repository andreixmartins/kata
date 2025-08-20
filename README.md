

# Kata cluster

- Build cluster
```bash
tofu init
tofu apply -auto-approve
```
- Destroy cluster
```bash
tofu destroy -auto-approve
```

# Build Dockerfile Jenkins Agent

# amd64
docker build -t axsoftware/jenkins-agent .

# arm64 (Apple Silicon) via buildx
docker buildx build --platform linux/arm64 -t axsoftware/jenkins-agent .

# publish ro registry
docker push axsoftware/jenkins-agent:latest

# Delete cluster
kind delete cluster --name kata-cluster || true

