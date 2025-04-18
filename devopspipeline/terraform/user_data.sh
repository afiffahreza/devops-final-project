#!/bin/bash
dnf update -y
dnf install -y git
dnf install -y docker

# Docker Compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

systemctl start docker
systemctl enable docker

chmod 666 /var/run/docker.sock
mkdir /opt/zap-logs

export GH_DEPLOY_KEY=$(echo "${GH_DEPLOY_KEY}")
export GH_REPO_URL=$(echo "${GH_REPO_URL}")
export PROD_IP=$(echo "${PROD_IP}")

mkdir -p /root/.ssh
echo "$GH_DEPLOY_KEY" | base64 --decode > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

ssh-keyscan github.com >> /root/.ssh/known_hosts

git clone $GH_REPO_URL /opt/devops-final-project

mkdir /opt/env
echo "GH_DEPLOY_KEY=${GH_DEPLOY_KEY}" >> /opt/env/.env
echo "GH_REPO_URL=${GH_REPO_URL}" >> /opt/env/.env
echo "PROD_IP=${PROD_IP}" >> /opt/env/.env

cd /opt/devops-final-project/devopspipeline

sudo docker-compose up -d
