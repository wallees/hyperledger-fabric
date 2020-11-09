#!/bin/bash

export CHANNEL_NAME=$1
export BASE_PATH=/root/git/src/mynetwork/single
export FABRIC_CFG_PATH=$BASE_PATH/file/config
export CORE_PEER_TLS_ENABLED=true

ORDERER_CA=$BASE_PATH/data/org/ordererOrganizations/mynetwork.com/orderers/orderer1.mynetwork.com/msp/tlscacerts/tlsca.mynetwork.com-cert.pem
ORG1_ROOT_CA=$BASE_PATH/data/org/peerOrganizations/org1.mynetwork.com/peers/peer1.org1.mynetwork.com/tls/ca.crt
ORG1_MSPCONFIG=$BASE_PATH/data/org/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
ORG2_ROOT_CA=$BASE_PATH/data/org/peerOrganizations/org2.mynetwork.com/peers/peer1.org2.mynetwork.com/tls/ca.crt
ORG2_MSPCONFIG=$BASE_PATH/data/org/peerOrganizations/org2.mynetwork.com/users/Admin@org2.mynetwork.com/msp

echo "1. Create Channel"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:7051
peer channel create -o orderer1.mynetwork.com:10010 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer1.mynetwork.com \
-f $BASE_PATH/data/channel-artifacts/${CHANNEL_NAME}.tx --outputBlock $BASE_PATH/data/channel-artifacts/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA
echo ""

echo "2. Join Channel"
echo " - peer1.org1.mynetwork.com"
peer channel join -b $BASE_PATH/data/channel-artifacts/$CHANNEL_NAME.block
echo " - peer1.org2.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG2_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:9051
peer channel join -b $BASE_PATH/data/channel-artifacts/$CHANNEL_NAME.block
echo ""

echo "3. Update Anchor peer"
echo " - peer1.org1.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:7051
peer channel update -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com \
-c $CHANNEL_NAME -f $BASE_PATH/data/channel-artifacts/Org1MSPanchors.tx --tls --cafile $ORDERER_CA
echo " - peer1.org2.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG2_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:9051
peer channel update -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com \
-c $CHANNEL_NAME -f $BASE_PATH/data/channel-artifacts/Org2MSPanchors.tx --tls --cafile $ORDERER_CA
echo ""
