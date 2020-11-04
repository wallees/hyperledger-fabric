#!/bin/bash

CHANNEL_NAME=mychannel
BASE_PATH=/root/git/src/mynetwork/instance0
UTIL_PATH=$BASE_PATH/util
DATA_PATH=$BASE_PATH/data

export FABRIC_CFG_PATH=$UTIL_PATH/config/
export CORE_PEER_TLS_ENABLED=true

# Chaincode information
export CC_SRC_PATH=$BASE_PATH/chaincode/asset-transfer-basic/chaincode-go
export CC_NAME="basic"
export CC_LANG="golang"
export CC_VERSION="1.0"

ORDERER_CA=$DATA_PATH/cryptofile/ordererOrganizations/mynetwork.com/orderers/orderer1.mynetwork.com/msp/tlscacerts/tlsca.mynetwork.com-cert.pem

echo "3. Approve a chaincode definition"
echo " - Query installed chaincode - peer1.org1"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/peers/peer1.org1.mynetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:17051
peer lifecycle chaincode queryinstalled > package_id.txt
PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" package_id.txt)
rm -f package_id.txt

export CC_SEQUENCE=1

echo ""
echo " - Approve for organization1"
peer lifecycle chaincode approveformyorg -o localhost:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE}
echo ""
echo " - Approve for organization2"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/peers/peer1.org2.mynetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/users/Admin@org2.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:27051
peer lifecycle chaincode approveformyorg -o localhost:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE}
echo ""

