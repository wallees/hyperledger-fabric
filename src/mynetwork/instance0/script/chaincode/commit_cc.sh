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

export FABRIC_CFG_PATH=$UTIL_PATH/config/
export CORE_PEER_TLS_ENABLED=true

echo "5. Check committed readiness"
echo " - peer1.org1.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/peers/peer1.org1.mynetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/users/Admin@org1.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:17051

peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $CC_NAME --version $CC_VERSION --sequence $CC_SEQUENCE --tls --cafile $ORDERER_CA --output json

echo ""
echo "6. Commit chaincode"
peer lifecycle chaincode commit -o localhost:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com --tls --cafile $ORDERER_CA \
 --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} \
 --peerAddresses peer1.org1.mynetwork.com:17051 --tlsRootCertFiles $DATA_PATH/cryptofile/peerOrganizations/org1.mynetwork.com/peers/peer1.org1.mynetwork.com/tls/ca.crt \
 --peerAddresses peer1.org2.mynetwork.com:27051 --tlsRootCertFiles $DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/peers/peer1.org2.mynetwork.com/tls/ca.crt

echo ""
echo "7. Query committed chaincode"
echo " - peer1.org1.mynetwork.com"
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME --cafile $ORDERER_CA
echo " - peer1.org2.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/peers/peer1.org2.mynetwork.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$DATA_PATH/cryptofile/peerOrganizations/org2.mynetwork.com/users/Admin@org2.mynetwork.com/msp
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:27051
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME --cafile $ORDERER_CA
