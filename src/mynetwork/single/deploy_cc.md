# Deploying a smart contract to a channel

> Hyperledger Fabric v2.x에서 가장 큰 변화는 스마트 컨트랙트(이하 체인코드) 부분이므로, 이 부분을 조금 더 자세히 살펴보고자 한다.
>
> 체인코드는 fabcar를 사용한다. 소스는 [이곳](script/chaincode/deploy.sh)에서 볼 수 있다.

<br>

## Package the smart contract

기존에는 각 Peer에 바로 체인코드를 설치할 수 있었지만, 2.x버전부터는 패키징을 먼저 한 후에 설치할 수 있게 된다.

> 사실 이전 버전에서도 패키징 이후에 체인코드 설치가 가능했다. 특히, 여러개의 go파일을 갖고 있는 체인코드의 경우 패키징이 필수적이었다.
>
> 하지만 이전에는 단일 go 파일로 이루어진 체인코드의 경우 패키징을 생략할 수 있었지만, 2.x버전부터는 파일의 갯수와 상관없이 패키징이 무조건 선행되어야 하는 것으로 보인다.

패키징 과정은 '실제 비즈니스를 수행하는 체인코드'와 '체인코드 실행에 필요한 의존성 파일'을 하나로 모아주는 역할을 한다.

go언어를 기준으로 설명하면, go.mod 파일에 의존성 라이브러리 목록이 적히게 된다.

```go
# file/chaincode/fabcar/go/go.mod
module github.com/hyperledger/fabric-samples/chaincode/fabcar/go

go 1.13

require github.com/hyperledger/fabric-contract-api-go v1.1.0
```

의존성 파일은 module 하위의 경로(gopath 기준)에 위치하게 되며, 이러한 의존성 라이브러리 파일들은 vendor에 설치된다.

이제 실제 비즈니스 수행 체인코드와 이를 수행하기 위한 의존성 체인코드 전체를 패키징해준다.

중요한 것은, FABRIC_CFG_PATH이 core.yaml 파일이 있는 경로를 가리키고 있어야 한다.

```shell
export FABRIC_CFG_PATH=$PWD/../config/ # test-network 예제
peer lifecycle chaincode package ${TAR_FILE} --path ${SRC_PATH} / --lang ${LANGUAGE} --label ${LABEL}
```

- TAR_FILE: 패키징 결과 생성되는 파일의 이름 및 확장자 (basic.tar.gz)
- SRC_PATH: 패키징에 사용되는 체인코드 파일의 경로 (.../file/chaincode/fabcar/go)
- LANGUAGE: 체인코드 언어 (golang)
- LABEL: 설치된 체인코드를 구별하기 위해 사용, 체인코드의 이름과 버전을 함께 명시할 것을 권장 (fabcar_1)

패키징 된 체인코드(fabcar.tar.gz) 파일 내부를 보면 다음과 같다.

```
fabcar.tar.gz
ㄴ metadata.json
ㄴ code.tar.gz
   ㄴ src
      ㄴ fabcar.go      
      ㄴ go.mod, go.sum
      ㄴ vendor
         ㄴ github.com, golang.org, google.golang.org, gopkg.in, modules.txt
```

사용하려고 했던 체인코드의 경로(.../file/chaincode/fabcar/go)에 있는 모든 파일을 압축해놓은 것이라고 보면 되겠다.

<br>

## Install the chaincode package

위에서 패키징 된 체인코드(.tar.gz)를 각 피어에 설치해준다.

```shell
peer lifecycle chaincode install fabcar.tar.gz
```

<br>

## Approve a chaincode definition

2.x 버전부터 새롭게 생긴 과정인데, 체인코드를 설치한 후 각 organization(조직, org)로부터 체인코드의 이름, 버전, 보증 정책(endorsement policy)'을 승인받아야 한다. 승인을 담당하는 Org들은 Application/Channel/lifecycleEndorsement에 명시되는데, 기본값은 Majority of channel members(과반수 이상의 채널 구성원)이다.

> 채널을 구성하는 Org가 2개(Org1, Org2)라고 할 때, approvement 과정은 Majority = 2개의 Org에서 모두 수행되어야 한다 (3개라면 2개). 하지만 체인코드의 승인과정을 거치지 않고 이후의 커밋(commit)과정이 진행되면, 트랜잭션의 보증(endorsement)이 이루어지지 않게 된다. 그러므로, **Majority와 같은 기본값이 적용되어있다 하더라도 모든 채널 구성원으로부터 체인코드의 승인과정을 수행할 것을 권장**한다.
>
> (If you commit the definition before a channel member has approved the chaincode, the organization will not be able to endorse transactions. As a result, it is recommended that all channel members approve a chaincode before committing the chaincode definition.)

승인 과정에는 체인코드의 패키지 ID가 필요하다. 이 패키지 ID는 피어에 설치된 체인코드를 이용하여 각 Org에서 보증(endorse) 과정을 수행할 수 있도록 한다.

패키지 ID는 체인코드가 설치된 각 피어에서 다음의 명령어를 통해 얻을 수 있다.

```shell
peer lifecycle chaincode queryinstalled
```

결과는 다음과 같이 출력될 수 있다.

```shell
Installed chaincodes on peer:
Package ID: fabcar_1:69de748301770f6ef64b42aa6bb6cb291df20aa39542c3ef94008615704007f3, Label: fabcar_1
```

- 패키지 ID는 체인코드 라벨과 체인코드 바이너리의 해시값을 조합한 형태로 구성된다.
- 결국 패키지 된 체인코드 별로 ID가 생성되기 때문에, 서로 다른 피어에 설치되어있다 하더라도 같은 체인코드 패키지에 대하서는 동일한 ID가 출력된다.

이제 체인코드의 승인 과정에 위의 패키지 ID를 사용한다. 

```shell
PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" packageId.txt)
```

> **TODO**: 완벽하게 같은 체인코드를 라벨만 다르게 하여 구성한다면, 체인코드 바이너리를 구성하는 해시값은 그대로 유지되고 라벨만 다르게 변경되는가?

체인코드 승인 과정은 org 단위로 진행되며, 각 org별로 하나의 피어에서 승인 과정이 통과되면 gossip 통신을 이용하여 결과가 다른 피어로 전달된다. 그러므로 각 org마다 한 번씩 승인과정을 진행하면 된다.

```shell
peer lifecycle chaincode approveformyorg -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name $CC_NAME --version ${CC_VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${CC_VERSION}
```

- ORDERER_ADDR: 승인 과정에 참여할 오더러(orderer)의 주소 (localhost:7050 / orderer1.mynetwork.com:7050)

- ORDERER_TLS_HOSTNAME: TLS 통신에서 사용할 오더러의 도메인 명칭(orderer.example.com / orderer1.mynetwork.com)

- **CC_PACKAGE_ID**: 위에서 저장한 패키지 ID를 승인 과정에 사용한다.

- SEQUENCE: 현재 패키징 된 체인코드가 승인된 횟수를 나타내며, 기본적으로 초기엔 1로 세팅한다.

  > 체인코드가 업그레이드 되면 sequence를 순차적으로 증가시켜준다. 버전과는 별개로 체인코드가 얼마나 변경되었는지를 카운트해준다.

- ORDERER_CA: 오더러의 CA 파일이 있는 경로

>  Fabric에서 제공하는 Shim API를 사용한 체인코드의 경우, --init-required 플래그를 사용하면 체인코드의 초기화 과정에 init 함수를 무조건 호출한다. 

체인코드의 승인 과정은 admin 역할을 하는 식별자(peer/org)로부터 수행되어야 하므로, CORE_PEER_MSPCONFIGPATH 값이 admin 역할을 포함하고 있는 MSP 폴더를 가리켜야 한다 (client 역할을 하는 사용자에게서는 수행할 수 없다).

승인 과정은 오더링 서비스(ordering service)를 거치게 되고, admin 서명을 검증한 후에 다른 피어로 승인 과정을 전달한다.

<br>

## Committing the chaincode definition to the channel

승인 과정이 정상적으로 완료되면, 채널을 구성하는 org 중 하나로부터 체인코드의 커밋(commit) 과정을 수행할 수 있다. 승인 과정이 완료되었기 때문에 더이상 패키지 ID는 사용되지 않는다.

peer lifecycle chaincode checkcommitreadiness 명령어는 현재 채널 내에서 승인을 완료한 org의 목록을 json 형태로 출력해준다.

```shell
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name ${CC_NAME} --version ${CC_VERSION} --sequence ${SEQUENCE} --tls --cafile ${ORDERER_CA} --output json
```

- CC_NAME: 체인코드의 이름
- CC_VERSION: 체인코드의 버전 (1.4.x 버전에서 사용하던 체인코드의 버전)
- SEQUENCE: 체인코드 승인과정에 사용한 시퀀스 번호

```json
# output 결과 중 Approvals 부분 예시(Org1, Org2 모두로부터 정상적인 승인이 완료되었다)
	{
            "Approvals": {
                    "Org1MSP": true,
                    "Org2MSP": true
            }
    }
```

승인 과정이 정상적으로 완료되었다는 것을 확인하였으면, 실제 커밋 과정을 진행한다.

```shell
peer lifecycle chaincode commit -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com \
--tls --cafile $ORDERER_CA \
--channelID $CHANNEL_NAME --name $CC_NAME --version ${CC_VERSION} --sequence ${CC_VERSION} --init-required \
--peerAddresses peer1.org1.mynetwork.com:7051 --tlsRootCertFiles $ORG1_ROOT_CA \
--peerAddresses peer1.org2.mynetwork.com:9051 --tlsRootCertFiles $ORG2_ROOT_CA
```

> Error: transaction invalidated with status (ENDORSEMENT_POLICY_FAILURE) 
>
> - commit 트랜잭션이 endorsement policy를 충족하지 못했을 경우 발생하며, configtx.yaml의 Channel/Application/Endorsement에 작성되어 있다.
> - 각 Org별 Endorsement 정책과 Application/Policies를 확인하여 org별 피어를 추가해주도록 한다.

> 대부분 승인 과정에서 사용한 형식과 비슷한 것을 볼 수 있는데, 기존에 v1.4.x 에서 invoke 과정에서만 각 피어의 TLS ROOT CERT 파일의 경로를 모두 참조했던 것과 다르게 커밋 과정에서도 동일하게 진행하는 것을 볼 수 있다. 

- peer lifecycle chaincode commit 명령어를 실행하면 채널에 조인된 모든 피어로부터 자신이 승인한 체인코드에 대해 정의된 내용을 query 해준다. 
- 체인코드 deploy 과정에 필요하다고 정의된 정책을 충족할 수 있는 갯수(또는 특정 피어)에 맞게 --peerAddresses가 작성되어야 하며, 모든 피어로부터 보증(validate) 과정에 대한 응답을 받은 후 종료된다.

체인코드가 채널에 커밋된 것을 확인하려면 peer lifecycle chaincode querycommitted를 사용한다.

```shell
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME
```

정상적으로 커밋이 완료된 경우, 예시로 다음과 같은 결과값을 보인다.

```shell
Committed chaincode definition for chaincode 'fabcar' on channel 'mychannel':
Version: 1, Sequence: 1, Endorsement Plugin: escc, Validation Plugin: vscc, Approvals: [Org1MSP: true, Org2MSP: true]
```

<br>

## Invoking the chaincode (Init)

체인코드 호출(invoke) 과정에서 이전 v1.4.x 버전과 다른 부분이 있다면, initiation 과정이 사라지고 invoke 과정에 --isInit 플래그를 사용하여 초기화를 동시에 진행한다는 것이다. 

```shell
peer chaincode invoke -o orderer1.mynetwork.com:10010 --ordererTLSHostnameOverride orderer1.mynetwork.com \
--tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CC_NAME \
--peerAddresses peer1.org1.mynetwork.com:7051 --tlsRootCertFiles $ORG1_ROOT_CA \
--peerAddresses peer1.org2.mynetwork.com:9051 --tlsRootCertFiles $ORG2_ROOT_CA \
--isInit -c '{"function":"initLedger","Args":[]}'
```

쿼리(query) 과정은 동일하다.

```shell
peer chaincode query -C mychannel -n fabcar -c '{"Args":["queryAllCars"]}'
```

<br>

## Upgrading a smart contract

체인코드를 업그레이드 하는 과정도 위의 체인코드 설치 및 초기화 과정과 전부 동일하다. 

Hyperledger fabric v2.2에서 chaincode lifecycle을 적용하면 upgrade 명령어가 아닌 invoke 과정에서 체인코드를 initialize 해준다.

실제 체인코드의 업그레이드 과정은 같은 이름의 체인코드 버전을 증가시키는 것으로, approve -> commit 과정을 진행하면서 새로운 버전의 체인코드 설치는 마무리된다. 그러므로 이후 invoke 과정을 통해 체인코드를 인스턴스화 시켜준다.

