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
export CC_SEQUENCE=1

ORDERER_CA=$DATA_PATH/cryptofile/ordererOrganizations/mynetwork.com/orderers/orderer1.mynetwork.com/msp/tlscacerts/tlsca.mynetwork.com-cert.pem

export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/peers/peer1.org1.mynetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:17051

peer chaincode invoke -o localhost:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com -C $CHANNEL_NAME -n $CC_NAME \
--tls --cafile ${ORDERER_CA} \
--peerAddresses peer1.org1.mynetwork.com:17051 --tlsRootCertFiles $DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/peers/peer1.org1.mynetwork.com/tls/ca.crt \
--peerAddresses peer1.org2.mynetwork.com:27051 --tlsRootCertFiles $DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/peers/peer1.org2.mynetwork.com/tls/ca.crt \
--peerAddresses peer2.org2.mynetwork.com:28051 --tlsRootCertFiles $DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/peers/peer2.org2.mynetwork.com/tls/ca.crt \
-c '{"function":"InitLedger","Args":[]}'
