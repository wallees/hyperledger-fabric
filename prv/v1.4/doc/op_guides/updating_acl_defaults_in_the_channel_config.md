# Updating ACL defaults in the channel config

## Prerequisites

1. fabric-samples/first-network 기반으로 테스트

2. configtx.yaml
    - Application: &ApplicationDefaults > ACLs: &ACLsDefault 추가
        - fabric-samples/config/configtx.yaml 참조
    - Orderer: &OrdererDefaults > Policies: MyPolicy 추가

        ```
        MyPolicy:
                Type: Signature
                Rule: "OR('Org1MSP.admin')"
        ```

3. peer/Propose에 대한 정책을 MyPolicy로 변경

<br>

## Source

docker exec -it cli /bin/bash

``` sh
# 환경변수 설정
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem && export CHANNEL_NAME=mychannel

# Fetch the Configuration
peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA

# Convert the Configuration to JSON and Trim It Down
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json

# Change the peer/Propose Crypto Material
export PEERPROPOSE_POLICYREF='.channel_group.groups.Application.values.ACLs.value.acls."peer/Propose".policy_ref'
jq "$PEERPROPOSE_POLICYREF" config.json
export POLICY_REF='"/Channel/Application/MyPolicy"'
jq "$PEERPROPOSE_POLICYREF = $POLICY_REF" config.json > modified_config.json

# First, translate config.json back into a protobuf called config.pb
configtxlator proto_encode --input config.json --type common.Config --output config.pb

# Next, encode modified_config.json to modified_config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

# Now use configtxlator to calculate the delta between these two config protobufs
configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output update.pb

# Let’s decode this object into editable JSON format
configtxlator proto_decode --input update.pb --type common.ConfigUpdate | jq . > update.json

# Wrap json file in an envelope message
# echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat update.json)'}}}' | jq . > update_in_envelope.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat update.json)'}}}' | jq . > update_in_envelope.json

# Leverage the configtxlator tool one last time and convert it into the fully fledged protobuf format that Fabric requires
configtxlator proto_encode --input update_in_envelope.json --type common.Envelope --output update_in_envelope.pb

# Sign and Submit the Config Update
# Default peer/Propose = /Channel/Application/Writers
# Org1, Org2의 chaincode invoke가 가능한 peer의 sign이 필요
# peer0.org1.example.com
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel signconfigtx -f update_in_envelope.pb

# peer0.org2.example.com
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.org2.example.com:9051
export CORE_PEER_LOCALMSPID="Org2MSP"

# Channel Update
peer channel update -f update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA

# Invoke - peer0.org1
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID="Org1MSP"

peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'

# Invoke - peer0.org2
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.org2.example.com:7051
export CORE_PEER_LOCALMSPID="Org2MSP"

peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'
```

<br>

## ONE MORE THING
MyPolicy의 msp_identifier를 Org1MSP->Org2MSP로 변경하고, 체인코드가 Org2에서만 동작하는지 확인한다
- jq를 이용하여 config 파일을 원활하게 수정할 수 있는 것에 의의를 둔 테스트

docker exec -it cli /bin/bash
``` sh
# 환경변수 설정
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem && export CHANNEL_NAME=mychannel

# Fetch the Configuration
peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA

# Convert the Configuration to JSON and Trim It Down
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json

# Change the MyPolicy Crypto Material
export MYPOLICY_MSPID='.channel_group.groups.Application.policies.MyPolicy.policy.value.identities[].principal.msp_identifier'
export NEWORG='"Org2MSP"'
jq "$MYPOLICY_MSPID" config.json
jq "$MYPOLICY_MSPID = $NEWORG" config.json > modified_config.json
jq "$MYPOLICY_MSPID" modified_config.json

# First, translate config.json back into a protobuf called config.pb
configtxlator proto_encode --input config.json --type common.Config --output config.pb

# Next, encode modified_config.json to modified_config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

# Now use configtxlator to calculate the delta between these two config protobufs
configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output update.pb

# Let’s decode this object into editable JSON format
configtxlator proto_decode --input update.pb --type common.ConfigUpdate | jq . > update.json

# Wrap json file in an envelope message
# echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat update.json)'}}}' | jq . > update_in_envelope.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat update.json)'}}}' | jq . > update_in_envelope.json

# Leverage the configtxlator tool one last time and convert it into the fully fledged protobuf format that Fabric requires
configtxlator proto_encode --input update_in_envelope.json --type common.Envelope --output update_in_envelope.pb

# Sign and Submit the Config Update
# Default peer/Propose = /Channel/Application/Writers
# Org1, Org2의 chaincode invoke가 가능한 peer의 sign이 필요
# peer0.org1.example.com
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

peer channel signconfigtx -f update_in_envelope.pb

# peer0.org2.example.com
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.org2.example.com:9051
export CORE_PEER_LOCALMSPID="Org2MSP"

# Channel Update
peer channel update -f update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA

# Invoke - peer0.org1
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID="Org1MSP"

peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'

# Invoke - peer0.org2
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.org2.example.com:7051
export CORE_PEER_LOCALMSPID="Org2MSP"

peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'
```



