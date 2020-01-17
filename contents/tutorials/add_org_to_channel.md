# 채널에 조직(Org) 추가하기
> BYFN(2org 4peer)에 org3를 추가한다.

> 하이퍼레저 공식 문서 : [hyperledger-fabric.readthedocs.io](https://hyperledger-fabric.readthedocs.io/en/release-1.4/channel_update_tutorial.html#adding-an-org-to-a-channel)

<br/>

## 전제
- BYFN(Build Your First Network)을 이용한 org 2개, peer 4개 구성
    <pre><code>cd ~/fabric-samples/first-network/ && ./byfn.sh up</code></pre>

<br/>

## Org3 구성하기
### Org3 인증서, 키 생성하기
<pre><code>cd ~/fabric-samples/first-network/org3-artifacts/</code></pre>
<pre><code>cryptogen generate --config=./org3-crypto.yaml</code></pre>

### configtx.yaml을 이용하여 org3의 설정 파일 생성하기
<pre><code>configtxgen -printOrg Org3MSP > ../channel-artifacts/org3.json</code></pre>

### 오더러 MSP 정보 등록하기
<pre><code>cd ../</code></pre> 
<pre><code>cp -r crypto-config/ordererOrganizations org3-artifacts/crypto-config/</code></pre>

<br/>

## Cli 컨테이너 들어가기
<pre><code>docker exec -it cli bash</code></pre>

<br/>

## 현재 구성된 채널 내용 수정하기

### 환경변수 설정하기
<pre><code>export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CHANNEL_NAME=mychannel</code></pre>

### 채널의 최신 블록 가져오기
<pre><code>peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA</code></pre>

### 블록을 JSON 형태로 변환하기
<pre><code>configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json</code></pre>

### Org3 내용 적용하기
<pre><code>jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json ./channel-artifacts/org3.json > modified_config.json</code></pre>
- modified_config.json에는 Org3까지 포함되어 있다.

### Org3 Anchor Peer 적용하기(optional)
<pre><code>jq '.channel_group.groups.Application.groups.Org3MSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.org3.example.com","port": 11051}]},"version": "0"}}' config.json > modified_anchor_config.json</code></pre>

### 기존 내용과 변경된 내용 사이의 차이(delta) 계산하기

#### JSON 파일 블록 파일로 변환하기
- config.json
    <pre><code>configtxlator proto_encode --input config.json --type common.Config --output config.pb</code></pre>
- modified_config.json
    <pre><code>configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb</code></pre>

#### 차이(delta) 계산하기
<pre><code>$ configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output org3_update.pb
</code></pre>

### 블록에 헤더(채널 정보) 추가하기
#### 블록을 JSON 형태로 변환하기
<pre><code>configtxlator proto_decode --input org3_update.pb --type common.ConfigUpdate | jq . > org3_update.json</code></pre>

#### JSON 파일에 헤더(채널 정보) 작성하기
<pre><code>echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat org3_update.json)'}}}' | jq . > org3_update_in_envelope.json</code></pre>

#### JSON 파일 블록 파일로 변환하기
<pre><code>configtxlator proto_encode --input org3_update_in_envelope.json --type common.Envelope --output org3_update_in_envelope.pb</code></pre>

<br/>

## 조직 추가 내용 채널에 반영하기

### 기존 정책 확인
> configtx.yaml
<pre><code>Channel: &ChannelDefaults
    ...
    Policies:
        ...
        # By default, who may modify elements at this config level
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
    ...
</code></pre>
- 채널의 Admin 정책이 MAJORITY 이므로, 기존의 모든 조직(Org1, Org2)으로부터 승인이 필요하다.

### Org1 Admin 승인
<pre><code>$ peer channel signconfigtx -f org3_update_in_envelope.pb</code></pre>
- cli가 이미 Org1으로 세팅되어 있으므로 바로 sign 가능

### Org2 Admin 승인
<pre><code>export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:9051
</code></pre>
<pre><code>peer channel update -f org3_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA
</code></pre>
- update 과정에 Org2 Admin의 Sign 내용이 첨부되어 진행

### Org3 가십(Gossip) 설정

오더링(Ordering)서비스를 통해 블록을 수신할 수 있도록, 가십을 설정해준다.
> 샘플에서는 동적으로 설정한다.

- 정적(Static) 리더 선출방식
<pre><code>CORE_PEER_GOSSIP_USELEADERELECTION=false

CORE_PEER_GOSSIP_ORGLEADER=true
</code></pre>

- 동적(Dynamic) 리더 선출방식
<pre><code>CORE_PEER_GOSSIP_USELEADERELECTION=true

CORE_PEER_GOSSIP_ORGLEADER=false
</code></pre>

<br/>

## Org3용 Cli 컨테이너 올리고 들어가기

<pre><code>docker-compose -f docker-compose-org3.yaml up -d</code></pre>
<pre><code>docker exec -it Org3cli bash</code></pre>

<br/>

## Org3 채널에 등록(Join)하기

### 환경변수 설정하기
<pre><code>export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CHANNEL_NAME=mychannel</code></pre>

### 채널 가져오기(fetch)
<pre><code>peer channel fetch 0 mychannel.block -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA</code></pre>

### 채널 조인하기(join)
#### peer0.org3
<pre><code>peer channel join -b mychannel.block</code></pre>
- 초기에 peer0으로 세팅되어 있으므로 바로 채널에 조인해준다.

#### peer1.org3
<pre><code>export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls/ca.crt

export CORE_PEER_ADDRESS=peer1.org3.example.com:12051</code></pre>
<pre><code>peer channel join -b mychannel.block</code></pre>

<br/>

## 체인코드 등록하기
### 체인코드 설치(install)하기
> Org가 추가되면, 새로운 버전의 체인코드를 모두에게 설치 및 초기화 해주어야 한다.  
여기서는 각 조직별 peer0에만 설치해본다.

### peer0.org3 (Org3cli에 접속해 있는 상태이므로)
<pre><code>peer chaincode install -n mycc -v 2.0 -p github.com/chaincode/chaincode_example02/go/</code></pre>

#### peer0.org1 (cli 컨테이너로 변경)
##### 환경변수
<pre><code>export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051</code></pre>
<pre><code>peer chaincode install -n mycc -v 2.0 -p github.com/chaincode/chaincode_example02/go/</code></pre>

#### peer0.org2
##### 환경변수
<pre><code>export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:9051</code></pre>
<pre><code>peer chaincode install -n mycc -v 2.0 -p github.com/chaincode/chaincode_example02/go/</code></pre>

### 체인코드 업그레이드(upgrade)하기
> Org1, Org2에는 이미 체인코드가 초기화 되어있으므로, 업그레이드 해주어야 한다.  
Org3에서 진행해도 된다(어차피 채널당 초기화 또는 업그레이드는 한번만 하면 된다)
#### 환경변수 설정하기
<pre><code>export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CHANNEL_NAME=mychannel</code></pre>
#### 체인코드 업그레이드
<pre><code>peer chaincode upgrade -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')"
</code></pre>