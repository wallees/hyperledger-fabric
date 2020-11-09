#!/bin/bash

export FABRIC_CFG_PATH=/root/git/src/mynetwork/single/file/config

export ORG1_ROOTCA=/root/git/src/mynetwork/single/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export ORG1_MSPCONFIG=/root/git/src/mynetwork/single/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp

export ORG1_ROOTCA=/root/git/src/mynetwork/single/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export ORG1_MSPCONFIG=/root/git/src/mynetwork/single/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$ORG1_ROOTCA
export CORE_PEER_MSPCONFIGPATH=$ORG1_MSPCONFIG
export CORE_PEER_ADDRESS=localhost:7051

peer chaincode query -C mychannel -n fabcar -c '{"Args":["queryAllCars"]}'
