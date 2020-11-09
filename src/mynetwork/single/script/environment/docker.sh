#!/bin/bash

export BASE_PATH=/root/git/src/mynetwork/single
if [ $1 == "up" ]; then
	docker-compose -f $BASE_PATH/file/docker/docker-compose.yaml up -d
	docker ps
fi

if [ $1 == "down" ]; then
	docker stop $(docker ps -aq)
	docker rm $(docker ps -aq)
	docker container prune -f
	docker volume prune -f
fi


