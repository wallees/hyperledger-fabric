#!/bin/bash

if [ $1 == "up" ]; then
	DOCKER_PATH=/root/fabric-samples/mynetwork/docker
    	docker-compose -f $DOCKER_PATH/docker-compose-mynetwork-orderer3.yaml up -d
	docker-compose -f $DOCKER_PATH/docker-compose-mynetwork-peer1-org2.yaml up -d
    	docker-compose -f $DOCKER_PATH/docker-compose-mynetwork-peer2-org2.yaml up -d
	docker ps
fi

if [ $1 == "down" ]; then
	docker stop $(docker ps -aq)
	docker rm $(docker ps -aq)
	docker container prune -f
	docker volume prune -f

    sudo rm -R /root/fabric-samples/mynetwork/volume/orderer3.mynetwork.com/*
    sudo rm -R /root/fabric-samples/mynetwork/volume/peer1.org2.mynetwork.com/*
    sudo rm -R /root/fabric-samples/mynetwork/volume/peer2.org2.mynetwork.com/*
fi


