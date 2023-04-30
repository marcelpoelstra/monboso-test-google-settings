#!/bin/bash
#
# Monte Rosa Solutiions
# Config script MRS Stack on Ubuntu Server 23.04
#
# run as root
#
#Settings
export DEBIAN_FRONTEND=noninteractive
export API_KEY=($(cat /etc/machine-id | md5sum))
export UspLicenseKey=bWFyY2VsQG1hcmNlbHBvZWxzdHJhLm5sfDIwMjIwOTA1IDAwOjAwOjAwLDM5NXxzdHJlYW0odm9kLGxpdmUsdm9kMmxpdmUpO2RybShhZXMsc2FtcGxlX2FlcyxwbGF5cmVhZHkscGxheXJlYWR5X2VudmVsb3BlLHBpZmYyY2VuYyxmYXhzLG1hcmxpbix3aWRldmluZSxkeGRybSx2ZXJpbWF0cml4X2hscyxjb25heF9wcl9obHMsaXJkZXRvX3NrZSk7cGFja2FnZShkYXNoLGhscyxpc3MsaGRzLG1wNCxjbWFmKTtjYXB0dXJlKGlzcyxoZHMsaGxzLGRhc2gsZGVjcnlwdCk7cmVtaXgobnB2cix2b2QsbGl2ZSk7ZW5jb2RlKGF2Yyk7ZGVjb2RlKGF2Yyk7bWV0YWRhdGEodGltZWQpO3N1cHBvcnQoMSk7aW9fb3B0KCk7Y2hlY2soKTtvZW0oKTt2aXJ0dWFsX2NoYW5uZWwoYmFzZSxkcm0sdGltZWRfbWV0YWRhdGEsbGl2ZV9zb3VyY2UpO3ZpcnR1YWxfY2hhbm5lbF9jb3VudCgxMCk7dmVyc2lvbigxLjExLjEzKXxwcm9kdWN0aW9uX0NlcnRpZmllZF9LZXl8NjdhYTBlMmYxNGFkNDQ2M2E3MmNlNGRhZjk3NWZjM2V8MjJhNjExYmQyYmI4ZGI4MzFlZDcyMzJkNTU3YTkwOTU4MDVhNzJiM2ZkY2ZlNTg3N2U0YmRjMTdkYjBjMjkwYWZiYjc3MDZmNDUxZDYxYTBkYWNiZDg3OWNhNzVlMDkzNmFlMGM0ODg4YTdhMTFiMjFhNDJkMzQxNWY3M2YzMWQyNzNkODhlZDg4MTNlNDg0ODcxN2I5ZGMyOGUwNDNmZTUwNzFlZTUxNjU1YWE3YzY5ZThiNjI4ZmQ5OWQ5YzkzMWYwYTQzMDJlNzg4MDBkZGRiNmM4MDk4ODQyYmQ1MGQzZGI5M2Q0YmJkNjI4NzYwMDRhMWZkOTc0MDZkMzU5Zg==
export REMOTE_STORAGE_URL=https://objectstorage.nl-ams-1.scalia.io/mrs-video-content/content/
export S3_ACCESS_KEY=X7H7GM5Q6CLY2Z55KTRC
export S3_SECRET_KEY=PtWmCSHjZ0Tl7K5OLUiW22vdHAXngQrnHIvmMqQ7
export S3_REGION=us-east-1
export SUBDOMAIN=template.monterosacdn.net
export LOGLEVEL=info
export GITHUB_USER=marcelpoelstra
export GITHUB_TOKEN=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
export GITHUB_REPOSITORY=marcelpoelstra/mrs-prod
#
#begin installation
apt update && apt -y dist-upgrade
#install pre requisites
apt -y install ca-certificates apt-transport-https ca-certificates curl software-properties-common
gnupg git mc 
#install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update && apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
#prepare for VSCode
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o microsoft.gpg
mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
apt-get update &&vapt-get install -y code
code --install-extension ms-vscode-remote.remote-ssh --force
code --install-extension ms-azuretools.vscode-docker --force
# fix temp dir to use tmpfs
ln -s /usr/share/systemd/tmp.mount /etc/systemd/system/
systemctl enable tmp.mount
#ssh listen on port 2222 :
mkdir -p /etc/systemd/system/ssh.socket.d
cat >/etc/systemd/system/ssh.socket.d/listen.conf <<EOF
[Socket]
ListenStream=
ListenStream=2222
EOF
systemctl daemon-reload
systemctl restart ssh.socket

#firewall config :
ufw default allow outgoing
ufw default deny incoming
ufw allow 2222/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8000/tcp
echo "y" | sudo ufw enable

# Set persistant environment
echo "export SUBDOMAIN=playout.monterosacdn.net" >> /etc/environment
echo "export API_KEY=${API_KEY}" >> /etc/environment
echo "export API_INSECURE=FALSE" >> /etc/environment
echo "export API_PORT=8000" >> /etc/environment
echo "export RABBITMQ_DEFAULT_USER=unified" >> /etc/environment
echo "export RABBITMQ_DEFAULT_PASS=unified" >> /etc/environment
echo "export RABBITMQ_HOST=rabbitmq" >> /etc/environment

# if unset will be generated as "pyamqp://$RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASS@$RABBITMQ_HOST"
echo "export CELERY_BROKER=" >> /etc/environment
echo "export CELERY_BACKEND=redis://redis:6379/0" >> /etc/environment

echo  "export APP_BACKEND=redis://redis:6379/1" >> /etc/environment

echo  "export S3_ACCESS_KEY=${S3_ACCESS_KEY}" >> /etc/environment
echo  "export S3_SECRET_KEY=${S3_SECRET_KEY}" >> /etc/environment
echo  "export S3_REGION=${S3_REGION}" >> /etc/environment
echo  "export SUBDOMAIN=${SUBDOMAIN}" >> /etc/environment
echo  "export REMOTE_STORAGE_URL=${REMOTE_STORAGE_URL}" >> /etc/environment

echo  "export UspLicenseKey=${UspLicenseKey}" >> /etc/environment

echo  "export LOG_LEVEL=${LOGLEVEL}" >> /etc/environment

#activate variables immediately
source /etc/environment


# clone application stack

git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}

#start stack
cd  mrs-prod

docker-compose up -d


