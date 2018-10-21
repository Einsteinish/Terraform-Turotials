#!/bin/bash

# user_data scripts automatically execute as root user, so sudo is not required

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
# in a production instance I would run "apt-get dist-upgrade -y" here,
# but I've ommitted it for purposes of speeding up instance launch
apt-cache policy docker-ce
apt-get install -y docker-ce
docker pull nginx:latest
docker run -d -p 80:80 --name nginx nginx
