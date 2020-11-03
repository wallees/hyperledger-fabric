#!/bin/bash

CHANNEL_NAME=mychannel

BASE_PATH=/root/git/src/mynetwork/instance0
UTIL_PATH=$BASE_PATH/util

export FABRIC_CFG_PATH=$UTIL_PATH/config/
export CORE_PEER_TLS_ENABLED=true

# Chaincode information
export CC_SRC_PATH=$BASE_PATH/chaincode/asset-transfer-basic/chaincode-go
export CC_NAME="basic"
export CC_LANG="golang"
export CC_VERSION="1.0"

echo "1. Package Chaincode - peer1.org1"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_CA
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:17051
peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_LANG} --label ${CC_NAME}_${CC_VERSION} >&log.txt



