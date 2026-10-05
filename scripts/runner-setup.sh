#!/usr/bin/env bash
# One-time setup of the runner server. Run as the ubuntu user.
set -euo pipefail
sudo apt-get update
sudo apt-get install -y git unzip pipx gnupg
# Terraform, from HashiCorp's package repository
wget -qO- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform
# Ansible, plus the AWS libraries its server inventory needs
pipx install ansible-core
pipx inject ansible-core boto3 botocore
pipx ensurepath
mkdir -p ~/.terraform.d/plugin-cache
echo "Done. Type exit, then 'sudo -iu ubuntu' again."