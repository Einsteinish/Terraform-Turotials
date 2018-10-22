#!/bin/bash

# user_data scripts automatically execute as root user, 
# so, no need to use sudo

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update

# install docker community edition
apt-cache policy docker-ce
apt-get install -y docker-ce

# pull nginx image
docker pull nginx:latest

# run container with port mapping - host:container
docker run -d -p 80:80 --name nginx nginx