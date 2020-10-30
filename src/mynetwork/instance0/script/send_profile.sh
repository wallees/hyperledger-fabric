#!/bin/bash

echo "1. Archive /data -> data.tar"
tar cvf data.tar ../data
echo "2. Send data.tar -> instance1"
scp -r data.tar root@orderer2.mynetwork.com:/root/git/src/mynetwork/instance1
echo "3. Send data.tar -> instance2"
scp -r data.tar root@orderer3.mynetwork.com:/root/git/src/mynetwork/instance2
echo "4. Remove archived file (data.tar)"
sudo rm -f data.tar
echo "Done"