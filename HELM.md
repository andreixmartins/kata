
## Install HELM Amazon AWS

To install Helm on Amazon Linux 2023, follow these steps:

1. **Update the system**:
   Ensure your system is up to date by running:

   ```bash
   sudo yum update -y
   ```

2. **Install dependencies**:
   Helm requires `wget` and `tar`. Install them if they are not already installed:

   ```bash
   sudo yum install -y wget tar
   ```

3. **Download Helm**:
   Get the latest stable version of Helm from the official Helm GitHub releases page:

   ```bash
   wget https://get.helm.sh/helm-v3.11.3-linux-amd64.tar.gz
   ```

4. **Extract the Helm archive**:
   After downloading, extract the Helm binary:

   ```bash
   tar -zxvf helm-v3.11.3-linux-amd64.tar.gz
   ```

5. **Move the binary to a directory in your `PATH`**:
   Move the `helm` binary to `/usr/local/bin` to make it accessible globally:

   ```bash
   sudo mv linux-amd64/helm /usr/local/bin/helm
   ```

6. **Verify the installation**:
   Check the Helm version to verify that it was installed successfully:

   ```bash
   helm version
   ```

This should install Helm on your Amazon Linux 2023 system!
