
## Install HELM Amazon AWS

To install Helm on Amazon Linux 2023, follow these steps:

1. **Update the system**:
   ```bash
   sudo yum update -y
   ```

2. **Install dependencies**:
   ```bash
   sudo yum install -y wget tar
   ```

3. **Download Helm**:
   ```bash
   wget https://get.helm.sh/helm-v3.11.3-linux-amd64.tar.gz
   ```

4. **Extract the Helm archive**:
   ```bash
   tar -zxvf helm-v3.11.3-linux-amd64.tar.gz
   ```

5. **Move the binary to a directory in your PATH **:
   ```bash
   sudo mv linux-amd64/helm /usr/local/bin/helm
   ```

6. **Verify the installation**:
   ```bash
   helm version
   ```

## HELM useful commands

- Find the release & namespace
```bash
helm list -A
```
- Uninstall it (Helm 3)
```bash
helm uninstall <release-name> -n <namespace>
```

- Helm upgrade
```
helm upgrade jenkins jenkins/jenkins -f jenkins-values.yaml
```


