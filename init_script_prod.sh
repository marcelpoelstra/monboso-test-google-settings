#!/bin/bash
#
# Monte Rosa Solutiions
# Config script MRS Stack 
# Tested and confirmed on Ubuntu Server 23.04  30/04/2023
#
# Make sure to run this script as root user (Don't use Sudo)
#
if [ $EUID -ne 0 ]; then
    echo "This script must be run as user root. Please run the script with root privileges."
    exit 1
fi
#
# CUSTOM SETTINGS
#DEBIAN_FRONTEND=noninteractive
# SSH public key

SSH_PUB_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC067R6KscUGcrdv0at5OLkE+goKESc3nIR2N0b4O77kBz0TmF6rgoS92NBpsMs7smofnCxILhJj1AZIKxhcRrLINe5vuBnhn0WZNjg/WXlIJkMGiWwzQQJJL5ZGaWnc/VWW6tBq1RBx5yME21As8RrQRbjiIs937LfNAaDcxi4soYXN3Q/s/ReGm/fMRPV4K3s1GRrAR9DBicC6wY4N/hfM9nng4uoRQLOgvcMfwlVWfJUdS0Tm533O3Z0Fc03Lo11njhl2jieOkwLIXoA5Ar5464uQc7xqekhDBomq6ybRw3vKqhsYzJVbGVi5UsUMOnXh8+2RnqkDcI+F60f/5d0Qxl2vC4q08SIxBenF07XUr1+jlED0kUcBIZ9xWep6cJP529PSwydCMW9cQ2nCflkS7fMDCniUO/GnKbrkcSfAjzdfboKblUaZk+NTJqBWNpjFyN+WKSvIDZ2bckMfgpwgw/sv6q4lv1E/1AF07b7K4pLrZjy7jAjs8pWkJ/h+rU='
# Virtual Channel API KEY default derived from machine-id, but changing is possible
API_KEY=($(cat /etc/machine-id | md5sum))
# Unified Streaming License Key
UspLicenseKey='bWFyY2VsQG1hcmNlbHBvZWxzdHJhLm5sfDIwMjIwOTA1IDAwOjAwOjAwLDM5NXxzdHJlYW0odm9kLGxpdmUsdm9kMmxpdmUpO2RybShhZXMsc2FtcGxlX2FlcyxwbGF5cmVhZHkscGxheXJlYWR5X2VudmVsb3BlLHBpZmYyY2VuYyxmYXhzLG1hcmxpbix3aWRldmluZSxkeGRybSx2ZXJpbWF0cml4X2hscyxjb25heF9wcl9obHMsaXJkZXRvX3NrZSk7cGFja2FnZShkYXNoLGhscyxpc3MsaGRzLG1wNCxjbWFmKTtjYXB0dXJlKGlzcyxoZHMsaGxzLGRhc2gsZGVjcnlwdCk7cmVtaXgobnB2cix2b2QsbGl2ZSk7ZW5jb2RlKGF2Yyk7ZGVjb2RlKGF2Yyk7bWV0YWRhdGEodGltZWQpO3N1cHBvcnQoMSk7aW9fb3B0KCk7Y2hlY2soKTtvZW0oKTt2aXJ0dWFsX2NoYW5uZWwoYmFzZSxkcm0sdGltZWRfbWV0YWRhdGEsbGl2ZV9zb3VyY2UpO3ZpcnR1YWxfY2hhbm5lbF9jb3VudCgxMCk7dmVyc2lvbigxLjExLjEzKXxwcm9kdWN0aW9uX0NlcnRpZmllZF9LZXl8NjdhYTBlMmYxNGFkNDQ2M2E3MmNlNGRhZjk3NWZjM2V8MjJhNjExYmQyYmI4ZGI4MzFlZDcyMzJkNTU3YTkwOTU4MDVhNzJiM2ZkY2ZlNTg3N2U0YmRjMTdkYjBjMjkwYWZiYjc3MDZmNDUxZDYxYTBkYWNiZDg3OWNhNzVlMDkzNmFlMGM0ODg4YTdhMTFiMjFhNDJkMzQxNWY3M2YzMWQyNzNkODhlZDg4MTNlNDg0ODcxN2I5ZGMyOGUwNDNmZTUwNzFlZTUxNjU1YWE3YzY5ZThiNjI4ZmQ5OWQ5YzkzMWYwYTQzMDJlNzg4MDBkZGRiNmM4MDk4ODQyYmQ1MGQzZGI5M2Q0YmJkNjI4NzYwMDRhMWZkOTc0MDZkMzU5Zg=='
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
RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-rabbit consumer_timeout 31622400000"
# Celery settings, leave CELERY_BROKER to empty for local use, change CELERY_BACKEND only when using external Redis instance.
# If unset will be generated as "pyamqp://$RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASS@$RABBITMQ_HOST"
CELERY_BROKER=
CELERY_BACKEND='redis://redis:6379/0'
# Redis Database location, change only when using external Redis instance.
APP_BACKEND='redis://redis:6379/0'
# Timeout setting for the Unified Remix task. Can potentially break things, only change when needed.
REMIX_TASK_TIMEOUT=600
# Time out for the housekeeping job to clean out no longer needed transitions. Only removes transitions, not the channel.
DAYS_TO_KEEP_TRANSITIONS_FOR=7
# CDNHOST and CDNDOMAIN will form the base url for playout. Change CDNHOST! Default CDN domain monterosacdn.net change only when needed.
CDNHOST=playout
CDNDOMAIN=monterosacdn.net
# Log level for all containers in the stack
LOGLEVEL=info
# Github credentials for fetching the stack. Please note the token has an expiration date
GITHUB_USER=marcelpoelstra
GITHUB_TOKEN='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'
GITHUB_REPOSITORY=marcelpoelstra/mrs-prod
GIT_BRANCHE=master
#
# DON'T EDIT BELOW THIS LINE
#
# Begin installation
#
# Set SSH key access for root
echo "$SSH_PUB_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
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
echo "export SUBDOMAIN=playout.monterosacdn.net" >> /etc/profile.d/mrs_custom_params.sh
echo "export API_KEY=${API_KEY}" >> /etc/profile.d/mrs_custom_params.sh
echo "export API_INSECURE=FALSE" >> /etc/profile.d/mrs_custom_params.sh
echo "export API_PORT=8000" >> /etc/profile.d/mrs_custom_params.sh
echo "export RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER}" >> /etc/profile.d/mrs_custom_params.sh
echo "export RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS}" >> /etc/profile.d/mrs_custom_params.sh
echo "export RABBITMQ_HOST=${RABBITMQ_HOST}" >> /etc/profile.d/mrs_custom_params.sh
echo "export RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS=\"${RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS}\"" >> /etc/profile.d/mrs_custom_params.sh
echo "export CELERY_BROKER=${CELERY_BROKER}" >> /etc/profile.d/mrs_custom_params.sh
echo "export CELERY_BACKEND=${CELERY_BACKEND}" >> /etc/profile.d/mrs_custom_params.sh
echo "export APP_BACKEND=${APP_BACKEND}" >> /etc/profile.d/mrs_custom_params.sh
echo "export REMIX_TASK_TIMEOUT=${REMIX_TASK_TIMEOUT}" >> /etc/mrs_custom_params.sh
echo "export DAYS_TO_KEEP_TRANSITIONS_FOR=${DAYS_TO_KEEP_TRANSITIONS_FOR}" >> /etc/profile.d/mrs_custom_params.sh
echo "export S3_ACCESS_KEY=${S3_ACCESS_KEY}" >> /etc/profile.d/mrs_custom_params.sh
echo "export S3_SECRET_KEY=${S3_SECRET_KEY}" >> /etc/profile.d/mrs_custom_params.sh
echo "export S3_REGION=${S3_REGION}" >> /etc/profile.d/mrs_custom_params.sh
echo "export SUBDOMAIN=${CDNHOST}.${CDNDOMAIN}" >> /etc/profile.d/mrs_custom_params.sh
echo "export REMOTE_STORAGE_URL=${REMOTE_STORAGE_URL}" >> /etc/profile.d/mrs_custom_params.sh
echo "export UspLicenseKey=${UspLicenseKey}" >> /etc/profile.d/mrs_custom_params.sh
echo "export LOG_LEVEL=${LOGLEVEL}" >> /etc/profile.d/mrs_custom_params.sh
#
# Instantly activate the variables
source /etc/profile
#
# Install pending Ubuntu updates
apt update && apt -y dist-upgrade
#
# Install prerequisite packages
apt -y install ca-certificates apt-transport-https ca-certificates curl software-properties-common gnupg git vim mc
#
# Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
#
# Cleanup
apt autoremove --purge
apt clean
#
# Clone the application stack from github
cd
git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}
cd  mrs-prod
git checkout ${GIT_BRANCHE}
# Start the stack
docker-compose up -d 
history -c && history -w





