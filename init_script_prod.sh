#!/bin/bash
#
# Monte Rosa Solutiions
# Config script MRS Stack 
# Tested and confirmed on Ubuntu Server 23.04  30/04/2023
#
# run as root
#
# CUSTOM SETTINGS
#
DEBIAN_FRONTEND=noninteractive
# Virtual Channel API KEY default derived from machine-id, but changing is possible
API_KEY=($(cat /etc/machine-id | md5sum))
# Unified Streaming License Key
UspLicenseKey=bWFyY2VsQG1hcmNlbHBvZWxzdHJhLm5sfDIwMjIwOTA1IDAwOjAwOjAwLDM5NXxzdHJlYW0odm9kLGxpdmUsdm9kMmxpdmUpO2RybShhZXMsc2FtcGxlX2FlcyxwbGF5cmVhZHkscGxheXJlYWR5X2VudmVsb3BlLHBpZmYyY2VuYyxmYXhzLG1hcmxpbix3aWRldmluZSxkeGRybSx2ZXJpbWF0cml4X2hscyxjb25heF9wcl9obHMsaXJkZXRvX3NrZSk7cGFja2FnZShkYXNoLGhscyxpc3MsaGRzLG1wNCxjbWFmKTtjYXB0dXJlKGlzcyxoZHMsaGxzLGRhc2gsZGVjcnlwdCk7cmVtaXgobnB2cix2b2QsbGl2ZSk7ZW5jb2RlKGF2Yyk7ZGVjb2RlKGF2Yyk7bWV0YWRhdGEodGltZWQpO3N1cHBvcnQoMSk7aW9fb3B0KCk7Y2hlY2soKTtvZW0oKTt2aXJ0dWFsX2NoYW5uZWwoYmFzZSxkcm0sdGltZWRfbWV0YWRhdGEsbGl2ZV9zb3VyY2UpO3ZpcnR1YWxfY2hhbm5lbF9jb3VudCgxMCk7dmVyc2lvbigxLjExLjEzKXxwcm9kdWN0aW9uX0NlcnRpZmllZF9LZXl8NjdhYTBlMmYxNGFkNDQ2M2E3MmNlNGRhZjk3NWZjM2V8MjJhNjExYmQyYmI4ZGI4MzFlZDcyMzJkNTU3YTkwOTU4MDVhNzJiM2ZkY2ZlNTg3N2U0YmRjMTdkYjBjMjkwYWZiYjc3MDZmNDUxZDYxYTBkYWNiZDg3OWNhNzVlMDkzNmFlMGM0ODg4YTdhMTFiMjFhNDJkMzQxNWY3M2YzMWQyNzNkODhlZDg4MTNlNDg0ODcxN2I5ZGMyOGUwNDNmZTUwNzFlZTUxNjU1YWE3YzY5ZThiNjI4ZmQ5OWQ5YzkzMWYwYTQzMDJlNzg4MDBkZGRiNmM4MDk4ODQyYmQ1MGQzZGI5M2Q0YmJkNjI4NzYwMDRhMWZkOTc0MDZkMzU5Zg==
# S3 Bucket address
REMOTE_STORAGE_URL=https://objectstorage.nl-ams-1.scalia.io/mrs-video-content/content/
# S3 Credentials
S3_ACCESS_KEY=X7H7GM5Q6CLY2Z55KTRC
S3_SECRET_KEY=PtWmCSHjZ0Tl7K5OLUiW22vdHAXngQrnHIvmMqQ7
S3_REGION=us-east-1
# RabbitMQ credentials and host. Defaults are ok, change when using external RabbitMQ instance.
RABBITMQ_DEFAULT_USER=unified
RABBITMQ_DEFAULT_PASS=unified
RABBITMQ_HOST=rabbitmq
# RabbitMQ setting to avoid message queue timeout for celery jobs with long delay. Do not change unlless advised to do so.
RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS=-rabbit consumer_timeout 31622400000
# Celery settings, leave CELERY_BROKER to empty for local use, change CELERY_BACKEND only when using external Redis instance.
# If unset will be generated as "pyamqp://$RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASS@$RABBITMQ_HOST"
CELERY_BROKER=
CELERY_BACKEND=redis://redis:6379/0
# Redis Database location, change only when using external Redis instance.
APP_BACKEND=redis://redis:6379/0
# Timeout setting for the Unified Remix task. Can potentially break things, only change when needed.
REMIX_TASK_TIMEOUT=600
# Time out for the housekeeping job to clean out no longer needed transitions. Only removes transitions, not the channel.
DAYS_TO_KEEP_TRANSITIONS_FOR=7
# CDNHOST and CDNDOMAIN will form the base url for playout. Change CDNHOST! Default CDN domain monterosacdn.net change only when needed.
CDNHOST=foo
CDNDOMAIN=monterosacdn.net
# Log level for all containers in the stack
LOGLEVEL=info
# Github credentials for fetching the stack. Please note the token has an expiration date
GITHUB_USER=marcelpoelstra
GITHUB_TOKEN=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
GITHUB_REPOSITORY=marcelpoelstra/mrs-prod
GIT_BRANCHE=master
#
# DON'T EDIT BELOW THIS LINE
#
# Begin installation
#
# Set SSH to listen on port 2222 only
mkdir -p /etc/systemd/system/ssh.socket.d
cat >/etc/systemd/system/ssh.socket.d/listen.conf <<EOF
[Socket]
ListenStream=
ListenStream=2222
EOF
systemctl daemon-reload
systemctl restart ssh.socket
#
# Set system firewall to only allowing strictly needed access.
ufw default allow outgoing
ufw default deny incoming
ufw allow 2222/tcp
ufw allow 80/tcp
ufw allow 8000/tcp
echo "y" | sudo ufw enable
#
# Fix temp dir to use tmpfs ramdisk
ln -s /usr/share/systemd/tmp.mount /etc/systemd/system/
systemctl enable tmp.mount
#
# Set persistant environment variables
echo "export SUBDOMAIN=playout.monterosacdn.net" >> /etc/environment
echo "export API_KEY=${API_KEY}" >> /etc/environment
echo "export API_INSECURE=FALSE" >> /etc/environment
echo "export API_PORT=8000" >> /etc/environment
echo "export RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER}" >> /etc/environment
echo "export RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS}" >> /etc/environment
echo "export RABBITMQ_HOST=${RABBITMQ_HOST}" >> /etc/environment
echo "export RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS=${RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS}" >> /etc/environment
echo "export CELERY_BROKER=${CELERY_BROKER}" >> /etc/environment
echo "export CELERY_BACKEND=${CELERY_BACKEND}" >> /etc/environment
echo "export APP_BACKEND=${APP_BACKEND}" >> /etc/environment
echo "export REMIX_TASK_TIMEOUT=${REMIX_TASK_TIMEOUT}" >> /etc/environment
echo "export DAYS_TO_KEEP_TRANSITIONS_FOR=${DAYS_TO_KEEP_TRANSITIONS_FOR}" >> /etc/environment
echo  "export S3_ACCESS_KEY=${S3_ACCESS_KEY}" >> /etc/environment
echo  "export S3_SECRET_KEY=${S3_SECRET_KEY}" >> /etc/environment
echo  "export S3_REGION=${S3_REGION}" >> /etc/environment
echo  "export SUBDOMAIN=${CDNHOST}.${CDNDOMAIN}" >> /etc/environment
echo  "export REMOTE_STORAGE_URL=${REMOTE_STORAGE_URL}" >> /etc/environment
echo  "export UspLicenseKey=${UspLicenseKey}" >> /etc/environment
echo  "export LOG_LEVEL=${LOGLEVEL}" >> /etc/environment
#
# Instantly activate the variables
source /etc/environment
#
# Install pending Ubuntu updates
apt update && apt -y dist-upgrade
#
# Install prerequisite packages
apt -y install ca-certificates apt-transport-https ca-certificates curl software-properties-common gnupg git
#
# Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
#
# Install VSCode Server and prepare for access through SSH and install the Docker extension
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o microsoft.gpg
mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
apt-get update &&vapt-get install -y code
code --install-extension ms-vscode-remote.remote-ssh --force
code --install-extension ms-azuretools.vscode-docker --force
#
# Clone the application stack from github
cd
git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}
cd  mrs-prod
git checkout ${GIT_BRANCHE}
# Start the stack
docker-compose up -d 


