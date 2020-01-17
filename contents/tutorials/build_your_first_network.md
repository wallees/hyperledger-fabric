> 하이퍼레저 패브릭에서 제공하는 BYFN(Build Your First Network) 예제를 하나씩 가볍게 살펴본다.

<br/>

# 1. 인증서, 키 만들기

<pre><code>$ cryptogen generate --config=./crypto-config.yaml</code></pre>

## crypto-config.yaml
- [github.com에서 살펴보기](https://github.com/hyperledger/fabric-samples/blob/release-1.4/first-network/crypto-config.yaml)
- 하이퍼레저 네트워크의 개략적인 구조를 작성해놓은 파일.
- 오더러(Orderer), 조직(Org), 피어(Peer)의 이름과 갯수를 명시하고 있다.

## cryptogen
- crypto-config.yaml 파일의 내용을 기반으로 하이퍼레저 네트워크에서 사용되는 인증서와 키를 만드는 명령어.
- 생성된 인증서와 키는 crypto-config라는 이름의 폴더 안에 저장된다.
- _Fabric-CA를 사용하는 경우도 간혹 있지만, 대부분 cryptogen을 사용한다._

<br/>

# 2. 채널 구성하기

## configtx.yaml
- [github.com에서 살펴보기](https://github.com/hyperledger/fabric-samples/blob/release-1.4/first-network/configtx.yaml)
- __하이퍼레저 네트워크는 '채널'을 기반으로 동작한다.__
- 하이퍼레저 네트워크의 전반적인 부분을 명시하고, 이를 기반으로 채널을 구성한다.  
(자세한 내용은 configtx.yaml 파일 참조)
    - Orderer, 채널 별 Org와 Peer의 구성 요소 및 정책
    - Orderer의 합의 방식(Solo, Kafka, Raft)

## 2.1. 작업디렉토리 설정
<pre><code>$ export FABRIC_CFG_PATH=$PWD</code></pre>
configtx.yaml 파일이 현재 위치에 존재한다는 것을 명시해준다.

## 2.2. 제네시스(Genesis) 블록 생성
<pre><code>$ configtxgen -profile TwoOrgsOrdererGenesis -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block</code></pre>

- TwoOrgsOrdererGenesis 
    - configtx.yaml 파일의 343번째 줄에 명시된 프로파일.
    - 프로파일에 작성된 내용으로 제네시스 블록을 생성한다. 
- byfn-sys-channel : Orderer 시스템 채널의 이름(실제 채널과 무관).
- 완료되면 channel-artifacts 폴더 내에 genesis.block 파일이 생성된다.

## 2.3. 채널 프로파일 생성
<pre><code>$ configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel</code></pre>

- TwoOrgsChannel
    - configtx.yaml 파일의 356번째 줄에 명시된 프로파일.
    - 프로파일에 작성된 내용으로 채널을 생성하고 채널 내에 Org를 구성한다.
- mychannel : 채널의 이름, 아이디.
- 완료되면 channel-artifacts 폴더 내에 channel.tx 파일이 생성된다.

## 2.4. 앵커 피어 설정
앵커 피어(Anchor Peer) : 서로 다른 조직(Org) 간 트랜잭션을 공유하고 동기화하는데 사용하는 피어.

<pre><code>$ configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP</code></pre>

<pre><code>$ configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP</code></pre>

이렇게 하면 configtx.yaml의 15번째 줄 'Organization' 내에 작성된 각 Org별 AnchorPeers(69, 100번째 줄)에 명시된 peer가 앵커 피어로 지정된다.

<br/>

# 3. 컨테이너 구동하기

하이퍼레저를 구성하는 오더러와 피어, 심지어 체인코드는 모두 도커 기반의 컨테이너로 동작한다. 
>(Org는 Peer가 모여있는 논리적인 조직이지, 그 자체가 동작을 하는 기반은 아니다.  
물론 채널도 조직이 모여있는 하나의 논리적인 구성일뿐!

여기서는 컨테이너로 구성된 하이퍼레저를 구성하는 노드(오더러, 피어, 그리고 클라이언트)를 구동한다.

## 3.1. docker-compose 파일 설정
byfn에서는 [docker-compose-cli.yaml](https://github.com/hyperledger/fabric-samples/blob/release-1.4/first-network/docker-compose-cli.yaml) 파일을 이용하여 하이퍼레저 네트워크의 각 노드를 컨테이너로 올린다.

<pre><code>cli:
    ...
    volumes:
        - /var/run/:/host/var/run/
        - ./../chaincode/:/opt/gopath/src/github.com/chaincode
        - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
        - ./scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/
        - ./channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts
</code></pre>

> 위의 내용은 로컬과 도커 컨테이너를 링크(linking)하는 과정이다. 동기화라고 표현하기에는 애매하지만, 자세한 내용을 확인하려면 [여기](https://0902.tistory.com/6)를 살펴보자.

## 3.2. docker-compose up
<pre><code>$ docker-compose -f docker-compose-cli.yaml up -d</code></pre>

컨테이너가 모두 올라간 후 
<pre><code>$ docker ps -a</code></pre>

를 통하여 컨테이너가 모두 정상적으로 시작되었는지 확인할 수 있다.

<br/>

# 4. cli 컨테이너로 들어가기

__앞으로 모든 실행은 cli(클라이언트) 컨테이너에서 진행된다.__

<pre><code>$ docker exec -it cli /bin/bash </code></pre>

## 환경변수

위에서 '앞으로 모든 실행은 cli 컨테이너에서 진행'된다고 했다. 그렇다면 질문해볼 수 있는데, "지금 내가 하고 있는 이 명령어가 어떤 피어를 대신하여 하고 있는지 cli는 어떻게 알 수 있을까?"  

여기서 우리는 __환경변수를 사용해서 cli가 지금 어떤 피어의 역할을 수행하고 있는지를 명시__ 해 줄 것이다. 이 후 문구 중 'xxx의 환경변수 설정'이 나오면 이 중에 해당되는 환경 변수를 실행한 후 명령어를 진행하면 된다.

1. Org1
- CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
- CORE_PEER_LOCALMSPID="Org1MSP"
- CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

    1.1. peer0
    - CORE_PEER_ADDRESS=peer0.org1.example.com:7051

    1.2. peer1
    - CORE_PEER_ADDRESS=peer1.org1.example.com:8051

2. Org2
- CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
- CORE_PEER_LOCALMSPID="Org2MSP"
- CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

    2.1. peer0
    - CORE_PEER_ADDRESS=peer0.org2.example.com:9051

    2.2. peer1
    - CORE_PEER_ADDRESS=peer1.org2.example.com:10051

<br/>

# 5. 채널 만들고, 참여시키기

## 5.1. 채널 만들기

우리는 peer0.org1.example.com에서 채널을 만들 것이므로(다른곳에서 만들어도 상관은 없다), peer0.org1의 환경변수를 실행하자.

<pre><code>$ peer0.org1 환경변수 실행</code></pre>

<pre><code>$ peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem</code></pre>

- -c : 채널 이름 (채널이름은 250자 미만, [a-z] [a-z0-9 .-]* 과 일치해야 함)
- -f : 채널 트랜잭션 생성 위치와 이름 (channel-artifacts/channel.tx)
- --cafile : Orderer의 루트 인증서 경로
- __결과 파일 : mychannel.block (컨테이너 내부에 만들어진 채널의 첫 블록 = 채널의 제네시스 블록)__

> 채널은 구성된 하이퍼레저 네트워크 상에서 딱 하나만 존재할 수 있다 (이름이 중복될 수 없음)

## 5.2. 채널 가져오기(fetch)

> byfn 기본 예제에서는 사용되지 않으나, eyfn에서 org3를 추가하는 과정에서는 사용된다.

물리적으로 구별된 두 개의 서버(A, B)가 있고 A는 org1, B는 org2를 나타낸다고 하자. A의 peer0.org1에서 mychannel이라는 채널을 이미 만들었고 B에서도 이 채널을 사용하고 싶다면, 이 채널을 A라는 외부 서버로부터 가져와야한다.  

이처럼 물리적으로 구별된 멀티노드로 구성된 환경에서 이미 만들어진 특정 채널을 사용하고자 할 때, fetch 명령어를 통해 해당 채널을 가져올 수 있다. 물론 어차피 같은 이름으로 채널을 만들려고 시도하면 실제로 만들어지지는 않을 것이다.

<pre><code>$ peer channel fetch 0 mychannel.block -o orderer.example.com:7050 -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem</code></pre>

## 5.3. 채널 참여하기(join)

byfn 예제에서는 각 org의 peer0번만 채널에 조인시키고 이를 앵커피어로 등록해서 트랜잭션을 전달한다.

1. peer0.org1의 채널 참여
    <pre><code>$ peer0.org1 환경변수 실행</code></pre>
    <pre><code>$ peer channel join -b mychannel.block</code></pre>

2. peer0.org2의 채널 참여
    <pre><code>$ peer0.org2 환경변수 실행</code></pre>
    <pre><code>$ peer channel join -b mychannel.block</code></pre>

## 5.4. 앵커피어 설정하기

채널에 참여한 각 org의 peer0을 앵커피어로 설정해서, 오더러로부터 전달되는 트랜잭션을 받아 이를 각 조직의 peer1에게 전달하도록 해준다.

1. org1의 앵커피어 등록: peer0.org1
    <pre><code>$ peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem</code></pre>

2. org2의 앵커피어 등록: peer0.org2
    <pre><code>$ peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem</code></pre>

<br/>

# 6. 체인코드 설치하고 초기화하기

채널 생성과 참여가 완료되었으면, 블록체인의 실제 업무인 '체인코드'를 설치해야한다.  
> *Applications interact with the blockchain ledger through chaincode* .....

## 6.1. 체인코드 설치(install)

<pre><code>$ peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02/go/</code></pre>

- -p : 체인코드 경로 (github.com/chaincode/chaincode_example02/go/)  
- -n : 체인코드 이름 (mycc)
- -v : 체인코드 버전 (1.0)

일반적으로 체인코드는 모든 피어에 설치해주는데, byfn 예제([scripts/script.sh, line:89](https://github.com/hyperledger/fabric-samples/blob/release-1.4/first-network/scripts/script.sh))를 보면 각 org의 peer0에만 체인코드를 설치하고 있다. _이렇게 되면 각 org의 peer2에서는 체인코드의 호출이 불가능하다._

## 6.2. 체인코드 초기화(instantiate)

<pre><code>$ peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')"</code></pre>

- -P : 체인코드의 유효성 검증 수준(Endorsement)
    - "AND ('Org1MSP.peer','Org2MSP.peer')" : Org1MSP.peer와 Org2MSP.peer 모두의 보증 필요

> 체인코드의 초기화는 각 채널별로 '1번만' 실행하면 된다. 중복 호출할 경우 같은 버전의 체인코드가 존재한다는 오류가 출력되며, 이후 체인코드가 수정될 때는 버전을 변경(증가)한 후 업그레이드(upgrade)를 호출한다.  

## 6.3. 체인코드 업그레이드(upgrade)

<pre><code>$ peer chaincode upgrade -o orderer.example.com:7050 --tls true --cafile ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('Org1MSP.peer','Org2MSP.peer')"</code></pre>

- instantiate와 비슷하지만 변경된 체인코드에 대하여 version을 '증가' 시켜줘야 한다.  
- 추가로 endorsement policy를 변경할 수 있는데, 위에서는 _OR ('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')_ 으로 변경해주고 있다

<br/>

# 7. 체인코드 호출

체인코드의 호출 방법은 invoke와 query가 있다.
- invoke : write/read 모두 가능하며, 트랜잭션을 통해 블록을 '생성'하는 과정을 포함한다. invoke를 통해 read하려면 체인코드로 get(read) 기능을 구현해야 한다.
- query : read의 역할을 하며, 트랜잭션을 통해 해당 key의 내용을 확인하지만 블록의 생성에 관여하지는 않는다. 체인코드에서 별도로 구현하지 않아도 가능한, 기본적으로 제공하는 기능이다.

> invoke는 proposal, endorsement 등 오더러의 업무가 수반되므로 단순 읽기 과정만 보면 성능에 전혀 도움되지 않으므로, __값을 작성(변경)할 경우에만 invoke__ 를 쓰도록 하자.

## 7.1. 체인코드 invoke 

<pre><code>$ peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'</code></pre>

- -o : 오더러(Orderer)
- --tls : TLS 여부
- --cafile : 오더러 인증서의 경로
- -C : 채널 이름 (mychannel)
- -n : 체인코드 이름 (mycc)
- --peerAddresses : 체인코드의 endorsement에 참여하는 피어들의 주소
    - 기존에 endorsement 정책이 _AND ('Org1MSP.peer','Org2MSP.peer')_ 이므로 위와 같이 작성되었으며, 만약 _OR ('Org1MSP.peer','Org2MSP.peer')로 주었을 경우 peerAddresses에는 두 개의 Org 중 하나만 작성_ 하면 된다.
- --tlsRootCertFiles: TLS 루트 주소
- -c : 해당 체인코드를 초기화하기 위한 아규먼트(Argument)

## 7.2. 체인코드 query 

<pre><code>$ peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
</code></pre>

- -c : Args에 query를 적어주고, 어떤 키(a)를 쿼리할 것인지 명시한다.



