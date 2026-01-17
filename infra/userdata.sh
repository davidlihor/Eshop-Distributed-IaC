#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

TOKEN=$(aws secretsmanager get-secret-value --secret-id "gitlab/runner/token" --query "SecretString" --output text --region us-east-1)
if [ -z "$TOKEN" ]; then
    echo "ERROR: Unable to retrieve token from Secrets Manager"
    exit 1
fi

sudo dnf update -y
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ssm-user

sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
sudo chmod a+x /usr/local/bin/gitlab-runner
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash

sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --token $TOKEN \
  --executor "docker" \
  --docker-image "alphine:latest" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --description "AWS-Private-EC2-Runner"
sudo gitlab-runner start

unset GITLAB_TOKEN
