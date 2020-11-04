#!/bin/bash

CHANNEL_NAME=mychannel
BASE_PATH=/root/git/src/mynetwork/instance0
UTIL_PATH=$BASE_PATH/util
DATA_PATH=$BASE_PATH/data

export FABRIC_CFG_PATH=$UTIL_PATH/config/
export CORE_PEER_TLS_ENABLED=true

echo "2. Install chaincode"
echo " - peer1.org1"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/peers/peer1.org1.mynetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:17051
peer lifecycle chaincode install basic.tar.gz
echo ""
echo " - peer1.org2"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/peers/peer1.org2.mynetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/users/Admin@org2.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:27051
peer lifecycle chaincode install basic.tar.gz
echo ""
echo " - peer2.org2"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/peers/peer1.org2.mynetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/users/Admin@org2.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer2.org2.mynetwork.com:28051
peer lifecycle chaincode install basic.tar.gz

