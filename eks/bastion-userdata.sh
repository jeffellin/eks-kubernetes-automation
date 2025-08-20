#!/bin/bash

# Update system packages
yum update -y

# Install necessary tools
yum install -y git curl wget unzip

# Install AWS CLI v2 -
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install session manager plugin for AWS CLI
yum install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

# Create .kube directory for ec2-user
mkdir -p /home/ec2-user/.kube
chown ec2-user:ec2-user /home/ec2-user/.kube

# Configure kubectl for the EKS cluster (will be available once cluster is created)
cat > /home/ec2-user/configure-kubectl.sh << 'EOF'
#!/bin/bash
aws eks --region ${region} update-kubeconfig --name ${cluster_name}
EOF

chmod +x /home/ec2-user/configure-kubectl.sh
chown ec2-user:ec2-user /home/ec2-user/configure-kubectl.sh

# Create a welcome message
cat > /etc/motd << 'EOF'
================================================
         WIZ EKS Bastion Host
================================================

This bastion host provides secure access to your
EKS cluster and private resources.

To configure kubectl for your EKS cluster, run:
./configure-kubectl.sh

Available tools:
- AWS CLI v2
- kubectl
- helm
- git, curl, wget, unzip

================================================
EOF