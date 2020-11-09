#!/bin/bash

export BASE_PATH=/root/git/src/mynetwork/single


echo "1. Clear previous crpyto files"
sudo rm -Rf $BASE_PATH/data/org/*


echo "1. Cryptogen"
# Orderer (3)
cryptogen generate --config=$BASE_PATH/file/cryptogen/crypto-config-orderer.yaml --output="${BASE_PATH}/data/org"
# Org1 (1)
cryptogen generate --config=$BASE_PATH/file/cryptogen/crypto-config-org1.yaml --output="${BASE_PATH}/data/org"
# Org2 (2)
cryptogen generate --config=$BASE_PATH/file/cryptogen/crypto-config-org2.yaml --output="${BASE_PATH}/data/org"

echo ""
echo "2. Configtxgen - Generate Orderer Genesis block"
export FABRIC_CFG_PATH=$BASE_PATH/file/configtx
if [ ! -d $BASE_PATH/data/channel-artifacts ]; then
    mkdir -p $BASE_PATH/data/channel-artifacts
fi
sudo rm -Rf ${BASE_PATH}/data/channel-artifacts/*
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock $BASE_PATH/data/channel-artifacts/system-genesis-block/genesis.block

echo ""
CHANNEL_NAME="mychannel"
echo "3. Create channel tx = ${CHANNEL_NAME}"
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx $BASE_PATH/data/channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

echo ""
echo "4. Update Anchor peer"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate $BASE_PATH/data/channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate $BASE_PATH/data/channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP

echo "Done"

