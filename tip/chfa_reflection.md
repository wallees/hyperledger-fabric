# CHFA reflection

## Summary
- Hyperledger fabric v1.4 기준으로 진행 
    - https://hyperledger-fabric.readthedocs.io/en/release-1.4/
    - https://hyperledger-fabric-ca.readthedocs.io/en/release-1.4/ 
- Ubuntu 16.04
- 총 14문제
- ORDERER_CA 또는 각 피어의 환경변수값은 문제 내에서 부여함

<br>

## Question 1
### 배점: 6%

In Hyperledger Fabric Smart Contracts are called chaincode. In this task you will install and instantiate a new chaincode written in Node.js to a single peer within your organisation.  

Given that network is up and running in node fab-00-00 with configuration files located at /srv/fabric-samples/. Install chaincode version v1.0 to peer0.org1.example.com in org1 specifying the chaincode ID as testcc and chaincode path as /opt/gopath/src/github.com/chaincode/chaincode_example02/node in channel mychannel.
 
```
peer chaincode install -n testcc -v v1.0 -l node -p /opt/gopath/src/github.com/chaincode/chaincode_example02/node
```

List the installed chaincodes for the peer and output the results to the file /srv/HFAL00101/installed.txt in node fab-00-00.
 
```
peer chaincode list --installed 
```

Instantiate the new chaincode on channel mychannel and initialize with args ["init","a","100","b","200"] by specifying a default endorsement policy.
 
```
peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT_PATH -C mychannel -n testcc -l node -v v1.0 -c '{"Args":["init","a", "100", "b","200"]}' 
```

List the instantiated chaincodes for the peer and output the results to the file /srv/HFAL00101/instantiated.txt in node fab-00-00.
 
```
peer chaincode list --instantiated -c mychannel
```
Perform the required operations by logging into the cli container.

<br>

## Question 2.
### 배점: 3%

A Hyperledger network is up and running with 2 orgs and 2 peers in node fab-00-05

Modify the configuration present at /srv/fabric-samples to make all the channels need majority of admins to write

```sh
cd /srv/fabric-samples
sudo vi configtx.yaml

########### configtx.yaml ###########
Channel: &ChannelDefaults
    # Policies defines the set of policies at this level of the config tree
    # For Channel policies, their canonical path is
    #   /Channel/<PolicyName>
    Policies:
        # Who may invoke the 'Deliver' API
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        # Who may invoke the 'Broadcast' API
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        # By default, who may modify elements at this config level
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
######################################

export FABRIC_CFG_PATH=$PWD
export CHANNEL_NAME=mychannel

sudo configtxgen -profile TwoOrgsOrdererGenesis -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block

sudo configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel

sudo configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP

sudo configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP
```

Restart the network after configuring the network

## Question 3.
### 배점: 10%

Hyperledger Fabric CA has been installed on node fab-00-24.

Fabric CA config files are present in /etc/fabric-ca-server and server is running as a systemd service with the name fabric-ca-server.

A software version of PKCS11 called softhsm has been installed on the system at path: /usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so

A token has been created and labelled FabTok

The PIN for the token has been set to 93845132

Configure the CA server to store private keys in a Hardware Security Module via PKCS11.

Make sure that the Fabric CA service restarted successfully after the configuration update.

```sh
sudo vi /etc/fabric-ca-server/fabric-ca-server-config.yaml

###### fabric-ca-server-config.yaml > bsscp ######
bccsp:
  default: PKCS11
  pkcs11:
    Library: /usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so
    Pin: 93845132
    Label: FabTok
    hash: SHA2
    security: 256
    filekeystore:
      # The directory used for the software file-based keystore
      keystore: msp/keystore
##################################################

sudo systemctl restart fabric-ca-server.service 
```

## Question 4.
### 베점: 14%

Given an active Hyperledger Fabric network comprises of two Organizations with two Peers each and one Orderer with configuration files located at /srv/fabric-samples/ in node fab-00-17, modify the channel configuration by setting the maximum message count of Batch size to 20.

Perform necessary steps to ensure the modifications are reflected in the network.

Hint: You may use jq for JSON manipulations

Perform the required operations by logging into the cli container.

```sh
docker exec -it cli /bin/bash

export CHANNEL_NAME=mychannel

peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA_TLS_CERT_PATH

configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json

export MAXBATCHSIZEPATH=".channel_group.groups.Orderer.values.BatchSize.value.max_message_count"
jq "$MAXBATCHSIZEPATH" config.json
jq "$MAXBATCHSIZEPATH = 20" config.json > modified_config.json
jq "$MAXBATCHSIZEPATH" modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb

configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output org3_update.pb

configtxlator proto_decode --input org3_update.pb --type common.ConfigUpdate | jq . > org3_update.json

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat org3_update.json)'}}}' | jq . > org3_update_in_envelope.json

configtxlator proto_encode --input org3_update_in_envelope.json --type common.Envelope --output org3_update_in_envelope.pb

source /opt/envfiles/orderer_admin.env
peer channel signconfigtx -f org3_update_in_envelope.pb

source /opt/envfiles/org1_admin.env
peer channel update -f org3_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT_PATH

source /opt/envfiles/org2_admin.env
peer channel update -f org3_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT_PATH (이부분은 이상함... 확인 필요)
```

## Question 5.
### 배점: 8%

Given that network is up and running in node fab-00-01 with configuration files located at /srv/fabric-samples/. The chaincode with name mycc and language Node.js has been instantiated on channel mychannel in peer0.org1.example.com. Upgrade the chaincode to new version v3.0, initialize with args ["init","a","100","b","200"], and endorse it by both Org1MSP and Org2MSP.

Perform the required operations by logging into the cli container.

```sh
## 모든 피어에 체인코드 새로 인스톨
peer chaincode install -n mycc -v v3.0 -l node -p /opt/gopath/src/github.com/chaincode/chaincode_example02/node

## 체인코드 인스턴스화 (both = and)
peer chaincode upgrade -o orderer.example.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT_PATH -C mychannel -n mycc -v v3.0 -c '{"Args":["init","a","100","b","200"]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')"
```

## Question 6.
### 배점: 7%

Given that the network is up and running in node fab-00-12 with configuration files located at /srv/fabric-samples/. Check and find the issue while instantiating chaincode located at /opt/gopath/src/github.com/chaincode/chaincode_example02/go in cli container with the name mycc and with arguments ["init","a","100","b","200"] for peer0 of org1 service which is joined to the channel mychannel.

Copy the error in peer0 of org1 container logs to a file /srv/HFDT00501/instantiate_error.txt in node fab-00-12, fix the issue and verify by instantiating the chaincode successfully.

```sh
peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT_PATH -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}' >&/srv/HFDT00501/instantiate_error.txt
```
> Error: could not assemble transaction, err proposal response was not successful, error code 500, msg cannot get packagefor chaincode (mycc:1.0)

Perform the required operations by logging into the cli container.

```
### 문제에 체인코드 버전에 대한 명시가 없어서 1.0으로 기본 세팅함
peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02/go/

peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT_PATH -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}'
```

## Question 7.
### 배점: 4%

Hyperledger Fabric CA has been installed on your node fab-00-22 and issued with org3.evpcaa affiliation. Revoke peer identity with an ID of peer4 which is issued by the CA org3.evpcaa for the reason aacompromise. Ensure the certificate appears in the CRL.

You can enroll the fabric admin user with name admin and password adminpw.

Fabric CA server is running as a systemd service with the name fabric-ca-server.

```sh
fabric-ca-client enroll -u http://admin:adminpw@localhost:7054

fabric-ca-client affiliation list --affiliation org3.evpcaa
fabric-ca-client revoke -e peer4 -r aacompromise

sudo systemctl restart fabric-ca-server.service(맞나.. 제공해줌!)

fabric-ca-client identity list --id peer4 (확인)
```

## Question 8.
### 배점: 10%

Given a node fab-00-19 with the required configuration files. Rename the profile SampleSingleMSPKafka in the file /srv/fabric-samples/configtx.yaml to Sample2OrdererGenesis. Then generate a genesis block file /srv/fabric-samples/genesisA.block with Sample2OrdererGenesis profile. Configure orderer to be launched with this genesis block by editing config file /srv/fabric-samples/orderer.yaml.

```sh
cd /srv/fabric-samples
sudo vi configtx.yaml

SampleSingleMSPKafka -> Sample2OrdererGenesis 변경

sudo configtxgen -profile Sample2OrdererGenesis -channelID byfn-sys-channel -outputBlock /srv/fabric-samples/genesisA.block

sudo vi orderer.yaml

### orderer.yaml > General
General:
    ...
    GenesisMethod: file
    GenesisProfile: Sample2OrdererGenesis (사실 의미없음)
    GenesisFile: genesisA.block
```
## Question 9.
### 배점: 6%

In this task you will perform an upgrade on chaincode that is written into a single peer within your organisation.

Given that network is up and running in node fab-00-03 with configuration files located at /srv/fabric-samples. The chaincode located at /opt/gopath/src/github.com/chaincode/chaincode_example02/go/ is installed and instantiated with name thecc on the channel mychannel in peer0.org1.example.com.

Upgrade the existing chaincode with version v3.0.2 and initialize with args ["init","a","786","b","200"] by specifying a default endorsement policy.

Perform the required operations by logging into the cli container.

```sh
peer chaincode install -n thecc -v v3.0.2 -p github.com/chaincode/chaincode_example02/go/ (GOPATH 확인!)

peer chaincode upgrade -o orderer.example.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT_PATH -C mychannel -n thecc -v v3.0.2 -c '{"Args":["init","a","786","b","200"]}' 
```

## Question 10.
### 배점: 6%

In this task you will create a new channel and join a peer to the channel.

Given that network is up and running in node fab-00-15 with configuration files located at /srv/fabric-samples/. A channel configuration transaction is provided already in ./channel-artifacts/cars.tx within the cli docker container.

Create a new channel called boats.
Join peer0.org1.example.com to the new channel boats.
List the channels to which the peer has joined and output the results to the file /srv/HFNM00401/peerchannels.txt in node fab-00-15.
Perform the required operations by logging into the cli container.

```sh
peer channel create -o orderer.example.com:7050 -c boats -f ./channel-artifacts/cars.tx --tls --cafile $ORDERER_CA_TLS_CERT_PATH

peer channel join -b boats.block

peer channel list >&/srv/HFNM00401/peerchannels.txt
```

## Question 11.
### 배점: 5%

On the existing Fabric network on node fab-00-07 with configuration files located at /srv/fabric-samples/, which is comprised of two Organisations (Org1 & Org2) with 2 peers on each, configure to enable a static leader election policy for Organisation org1 and set peer0 as the leader. Restart the fabric network to reflect the changes.

```sh
cd /srv/fabric-samples
sudo vi base/peer-base.yaml

## 해당 부분 주석 처리
- CORE_PEER_GOSSIP_USELEADERELECTION=true
- CORE_PEER_GOSSIP_ORGLEADER=false

sudo vi base/docker-compose.yaml (맞나?)

## peer0.org1
- CORE_PEER_GOSSIP_USELEADERELECTION=false
- CORE_PEER_GOSSIP_ORGLEADER=false

## peer1.org1
- CORE_PEER_GOSSIP_USELEADERELECTION=false
- CORE_PEER_GOSSIP_ORGLEADER=true

## peer0.org2 peer1.org2
- CORE_PEER_GOSSIP_USELEADERELECTION=true
- CORE_PEER_GOSSIP_ORGLEADER=false

docker-compose -f docker-compose-cli.yaml up -d
```

## Questio 12.
### 배점: 8%

Given that Hyperledeger Fabric CA is built in the node fab-00-20 with the configuration files located at /etc/fabric-ca-server. Fabric CA server is configured as systemd service with the name fabric-ca-server. The log file is located at /var/log/fabric-ca-server/fabric-ca-server.log.

Diagnose the issue while starting the Fabric CA server and fix the issue to start it successfully.

You can use the following command to start/stop/restart the fabric-ca-server

sudo systemctl start|stop|restart fabric-ca-server

```sh
>> 'Registry.Identities': source data must be an array or slice, got map

fabric-ca-server-config.yaml 파일의 registry > identities > name이 주석처리되어 있음 -> 주석 해제하면 오류 해결

sudo systemctl restart fabric-ca-server
```

## Question 13.
### 배점: 6%

Hyperledger Fabric CA has been installed in node fab-00-23. Create an identity with name userABC of type user, affiliation as org1.department1 and secret as passwd.

The userABC identity should have the following privileges 1. Can register new identities of type user 2. Can revoke the identities.

You can enroll the fabric admin user with name admin and password adminpw.

Fabric CA server is configured as systemd service with the name fabric-ca-server.

```sh
fabric-ca-client enroll -u http://admin:adminpw@localhost:7054

fabric-ca-client register -d --id.name userABC --id.affiliation org1.department1 --id.secret passwd --id.attrs '"hf.Registrar.Roles=user",hf.Revoker=true'
```

## Question 14.
### 배점:7%

Given a node fab-00-06 with configuration files located at /srv/fabric-samples/. You have an existing configuration of Fabric network, that is comprised of two Organisations with 2 peers each.

Generate a genesis block to ensure that the orderers are configured to make use of Raft. The genesis block should be named genesis.block in the location /srv/fabric-samples/channel-artifacts/. Once this is done bring up the network. Make sure changes take effect after starting the network.

You can use the /srv/fabric-samples/start_fabric_network.sh script to restart the network.

```sh
## configtx.yaml 내 Raft 관련 프로파일
SampleMultiNodeEtcdRaft

sudo configtxgen -profile SampleMultiNodeEtcdRaft -channelID byfn-sys-channel -outputBlock /srv/fabric-samples/channel-artifacts/genesis.block

docker-compose -f /srv/fabric-samples/docker-compose-cli.yaml -f /srv/fabric-samples/docker-compose-etcdraft2.yaml up -d
```






