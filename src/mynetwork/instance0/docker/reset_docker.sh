#!/bin/bash

docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker container prune -f
docker volume prune -f
