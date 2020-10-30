#!/bin/bash

BASE_PATH=/root/git/src/mynetwork/instance0
UTIL_PATH=$BASE_PATH/util
DATA_PATH=$BASE_PATH/data
CRYPTO_PATH=$UTIL_PATH/cryptogen

echo "1. Cryptogen"
# output = install destination -> $
# Orderer (3)
sudo rm -Rf ${BASE_PATH}/data/cryptofile/*
cryptogen generate --config=$CRYPTO_PATH/crypto-config-orderer.yaml --output="${BASE_PATH}/data/cryptofile"
# Org1 (1)
cryptogen generate --config=$CRYPTO_PATH/crypto-config-org1.yaml --output="${BASE_PATH}/data/cryptofile"
# Org2 (2)
cryptogen generate --config=$CRYPTO_PATH/crypto-config-org2.yaml --output="${BASE_PATH}/data/cryptofile"

echo ""
echo "2. Configtxgen - Generate Orderer Genesis block"
#export FABRIC_CFG_PATH=${PWD}/configtx
export FABRIC_CFG_PATH=$UTIL_PATH/configtx
sudo rm -Rf ${BASE_PATH}/data/channel-artifacts/*
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock $DATA_PATH/channel-artifacts/system-genesis-block/genesis.block

echo ""
CHANNEL_NAME="mychannel"
echo "3. Create channel tx = ${CHANNEL_NAME}"
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx $DATA_PATH/channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

echo ""
echo "4. Update Anchor peer"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate $DATA_PATH/channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate $DATA_PATH/channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP

echo ""
echo "Done"


tar cvf data.tar ../data
scp -r data.tar root@orderer2.mynetwork.com:/root/mynetwork
scp -r data.tar root@orderer3.mynetwork.com:/root/mynetwork
sudo rm -f data.tar