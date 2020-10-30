#!/bin/bash
BASE_PATH=/root/git/src/mynetwork/instance0
if [ $1 == "up" ]; then
	DOCKER_PATH=$BASE_PATH/docker
	docker-compose -f $DOCKER_PATH/docker-compose-mynetwork.yaml up -d
	docker ps
fi

if [ $1 == "down" ]; then
	docker stop $(docker ps -aq)
	docker rm $(docker ps -aq)
	docker container prune -f
	docker volume prune -f

	#sudo rm -R $BASE_PATH/volume/orderer1.mynetwork.com/*
fi


