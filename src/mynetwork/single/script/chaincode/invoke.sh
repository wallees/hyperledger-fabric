#!/bin/bash

export BASE_PATH=/root/git/src/mynetwork/single
export FABRIC_CFG_PATH=$BASE_PATH/file/config
export CORE_PEER_TLS_ENABLED=true

export CHANNEL_NAME=$1
export CC_NAME=$2

ORDERER_CA=$BASE_PATH/data/org/ordererOrganizations/mynetwork.com/orderers/orderer1.mynetwork.com/msp/tlscacerts/tlsca.mynetwork.com-cert.pem
ORG1_ROOT_CA=$BASE_PATH/data/org/peerOrganizations/org1.mynetwork.com/peers/peer1.org1.mynetwork.com/tls/ca.crt
ORG1_MSPCONFIG=$BASE_PATH/data/org/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
ORG2_ROOT_CA=$BASE_PATH/data/org/peerOrganizations/org2.mynetwork.com/peers/peer1.org2.mynetwork.com/tls/ca.crt
ORG2_MSPCONFIG=$BASE_PATH/data/org/peerOrganizations/org2.mynetwork.com/users/Admin@org2.mynetwork.com/msp

echo "8. Invoke chaincode (Init)"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:17051
peer chaincode invoke -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com --tls --cafile $ORDERER_CA \
-C $CHANNEL_NAME -n $CC_NAME \
--peerAddresses peer1.org1.mynetwork.com:17051 --tlsRootCertFiles $ORG1_ROOT_CA \
--peerAddresses peer1.org2.mynetwork.com:27051 --tlsRootCertFiles $ORG2_ROOT_CA \
--isInit -c '{"function":"initLedger","Args":[]}'
sleep 10
echo ""