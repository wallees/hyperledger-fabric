#!/bin/bash

CHANNEL_NAME=mychannel

BASE_PATH=/root/mynetwork
DATA_PATH=$BASE_PATH/data
UTIL_PATH=$BASE_PATH/util

export FABRIC_CFG_PATH=$UTIL_PATH/config/
export CORE_PEER_TLS_ENABLED=true

ORDERER_CA=$DATA_PATH/cryptofile/ordererOrganizations/mynetwork.com/orderers/orderer1.mynetwork.com/msp/tlscacerts/tlsca.mynetwork.com-cert.pem
ORG1_CA=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/peers/peer1.org1.mynetwork.com/tls/ca.crt
ORG2_CA=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/peers/peer1.org2.mynetwork.com/tls/ca.crt

echo "1. Create Channel"
echo " - peer1.org1.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_CA
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:17051
peer channel create -o orderer1.mynetwork.com:10010 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer1.mynetwork.com \
-f $DATA_PATH/channel-artifacts/${CHANNEL_NAME}.tx --outputBlock $DATA_PATH/channel-artifacts/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA

echo ""
echo "2. Join Channel"
echo " - peer1.org1.mynetwork.com"
# export CORE_PEER_LOCALMSPID="Org1MSP"
# export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_CA
# export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
# export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:17051
peer channel join -b $DATA_PATH/channel-artifacts/$CHANNEL_NAME.block

echo " - peer1.org2.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_CA
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/users/Admin@org2.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:27051
peer channel join -b $DATA_PATH/channel-artifacts/$CHANNEL_NAME.block

echo " - peer2.org2.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_CA
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/users/Admin@org2.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer2.org2.mynetwork.com:28051
peer channel join -b $DATA_PATH/channel-artifacts/$CHANNEL_NAME.block

echo ""
echo "3. Update Anchor peer"
echo " - peer1.org1.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_CA
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:17051
peer channel update -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com -c $CHANNEL_NAME -f $DATA_PATH/channel-artifacts/Org1MSPanchors.tx --tls --cafile $ORDERER_CA

echo " - peer1.org2.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_CA
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/users/Admin@org2.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:27051
peer channel update -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com -c $CHANNEL_NAME -f $DATA_PATH/channel-artifacts/Org2MSPanchors.tx --tls --cafile $ORDERER_CA

echo ""
