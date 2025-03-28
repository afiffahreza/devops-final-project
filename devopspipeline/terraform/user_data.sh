#!/bin/bash
dnf update -y
dnf install -y git
dnf install -y docker

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

systemctl start docker
systemctl enable docker

mkdir -p /root/.ssh
echo "${GH_DEPLOY_KEY}" | base64 --decode > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

ssh-keyscan github.com >> /root/.ssh/known_hosts

git clone ${GH_REPO_URL} /opt/devops-final-project

cd /opt/devops-final-project/devopspipeline
sudo docker-compose up -d
