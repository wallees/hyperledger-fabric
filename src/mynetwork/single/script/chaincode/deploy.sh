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

export CC_NAME=$2
export CC_SRC_PATH="$BASE_PATH/file/chaincode/fabcar/go/"
export CC_RUNTIME_LANGUAGE="golang"
export CC_VERSION=$3

echo "1. Package chaincode"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:7051
echo " - Vendoring Go dependencies"
pushd $CC_SRC_PATH
GO111MODULE=on go mod vendor
popd
echo " - Package chaincode with lifecycle"
peer lifecycle chaincode package $CC_NAME.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION}
echo ""

echo "2. Install chaincode"
echo " - peer1.org1.mynetwork.com"
peer lifecycle chaincode install ${CC_NAME}.tar.gz
echo " - peer1.org2.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG2_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:9051
peer lifecycle chaincode install ${CC_NAME}.tar.gz
rm -f ${CC_NAME}.tar.gz
echo ""

echo "3. Query installed chaincode"
echo " - peer1.org1.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:7051
peer lifecycle chaincode queryinstalled
echo " - peer1.org2.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG2_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:9051
peer lifecycle chaincode queryinstalled >&packageId.txt
PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" packageId.txt)
rm -f packageId.txt
echo ""

echo "4. Approve for organizations"
echo " - Organization 1"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:7051
peer lifecycle chaincode approveformyorg -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com --tls --cafile $ORDERER_CA \
--channelID $CHANNEL_NAME --name $CC_NAME --version ${CC_VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${CC_VERSION}
echo " - Organization 2"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG2_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:9051
peer lifecycle chaincode approveformyorg -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com --tls --cafile $ORDERER_CA \
--channelID $CHANNEL_NAME --name $CC_NAME --version ${CC_VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${CC_VERSION}
echo ""

echo "5. Check commit readiness"
echo " - Organization 1"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:7051
peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $CC_NAME --version ${CC_VERSION} --sequence ${CC_VERSION} --output json --init-required
echo " - Organization 2"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG2_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:9051
peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $CC_NAME --version ${CC_VERSION} --sequence ${CC_VERSION} --output json --init-required
echo ""

echo "6. Check chaincode definition"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:7051
peer lifecycle chaincode commit -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com --tls --cafile $ORDERER_CA \
--channelID $CHANNEL_NAME --name $CC_NAME --version ${CC_VERSION} --sequence ${CC_VERSION} --init-required \
--peerAddresses peer1.org1.mynetwork.com:7051 --tlsRootCertFiles $ORG1_ROOT_CA \
--peerAddresses peer1.org2.mynetwork.com:9051 --tlsRootCertFiles $ORG2_ROOT_CA
echo ""

echo "7. Query committed chaincode"
echo " - peer1.org1.mynetwork.com"
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME
sleep 3
echo " - peer1.org2.mynetwork.com"
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG2_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG2_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org2.mynetwork.com:9051
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME
sleep 3
echo ""

echo "8. Invoke chaincode (Init)"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:7051
peer chaincode invoke -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com --tls --cafile $ORDERER_CA \
-C $CHANNEL_NAME -n $CC_NAME \
--peerAddresses peer1.org1.mynetwork.com:7051 --tlsRootCertFiles $ORG1_ROOT_CA \
--peerAddresses peer1.org2.mynetwork.com:9051 --tlsRootCertFiles $ORG2_ROOT_CA \
--isInit -c '{"function":"initLedger","Args":[]}'
sleep 10
echo ""

echo "9. Query chaincode"
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOT_CA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=peer1.org1.mynetwork.com:7051
peer chaincode query -C mychannel -n fabcar -c '{"Args":["queryAllCars"]}'
echo ""

echo "Done"
