# Updating max_message_count in the channel config

## Prerequisites

1. fabric-samples/first-network 기반으로 테스트
2. max_message_count 값을 10 -> 20으로 수정

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

# Change the max_message_count Crypto Material
export MAXBATCHSIZEPATH=".channel_group.groups.Orderer.values.BatchSize.value.max_message_count"
jq "$PEERPROPOSE_POLICYREF" config.json
jq "$MAXBATCHSIZEPATH = 20" config.json > modified_config.json
jq "$MAXBATCHSIZEPATH" modified_config.json

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
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat update.json)'}}}' | jq . > update_in_envelope.json

# Leverage the configtxlator tool one last time and convert it into the fully fledged protobuf format that Fabric requires
configtxlator proto_encode --input update_in_envelope.json --type common.Envelope --output update_in_envelope.pb

# Sign from OrdererMSP
# Channel configuration has dependencies to OrdererMSP
export CORE_PEER_ADDRESS=orderer.example.com:7050
export CORE_PEER_LOCALMSPID="OrdererMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/users/Admin\@example.com/msp

peer channel signconfigtx -f update_in_envelope.pb

# Update Channel
peer channel update -f update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA

# 확인
peer channel fetch config new_config.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA

configtxlator proto_decode --input new_config.pb --type common.Block | jq .data.data[0].payload.data.config > new_config.json

jq "$MAXBATCHSIZEPATH" new_config.json
```

