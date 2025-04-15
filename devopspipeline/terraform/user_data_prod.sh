#!/bin/bash
dnf update -y
dnf install -y git
dnf install -y docker

export GH_DEPLOY_KEY=$(echo "${GH_DEPLOY_KEY}")
export GH_REPO_URL=$(echo "${GH_REPO_URL}")

mkdir -p /root/.ssh
echo "$GH_DEPLOY_KEY" | base64 --decode > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

ssh-keyscan github.com >> /root/.ssh/known_hosts

git clone $GH_REPO_URL /opt/devops-final-project

mkdir /opt/env
echo "GH_DEPLOY_KEY=${GH_DEPLOY_KEY}" >> /opt/env/.env
echo "GH_REPO_URL=${GH_REPO_URL}" >> /opt/env/.env

cd /opt/devops-final-project/devopspipeline
