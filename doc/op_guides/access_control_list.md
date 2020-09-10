# Access Control Lists (ACL)

하이퍼레저 패브릭은 ACL(액세스 제어 목록)을 사용하여 **특정 리소스에 접근할 수 있는 정책(일련의 ID에 대한 true/false 값)을 부여**한다. 
> Fabric uses access control lists (ACLs) to manage access to resources by associating a policy — which specifies a rule that evaluates to true or false, given a set of identities — with the resource.

<br>

### Resource

사용자 또는 시스템 체인코드, 이벤트 스트림 소스 등을 의미한다.  
configtx.yaml ([샘플](https://github.com/hyperledger/fabric/blob/release-1.2/sampleconfig/configtx.yaml)) 파일에 작성되며, component/resource 형태로 구성되는데 예를 들어 cscc/GetConfigBlock는 cscc 구성요소의 GetConfigBlock를 호출하기 위한 리소스를 말한다.

<br>

### Policies

어떠한 요청을 이행하는데 필요한 자원과 요청에 대한 ID(또는 ID 세트)를 연결해주는 방식을 의미한다.  
(쉽게 말해, 특정 자원을 사용하기 위해 요구되는 정책을 말한다.)

- Signature
  - 정책을 만족시키기 위한 사용자를 명시할 때 사용
  - AND, OR, NOutOf을 사용할 수 있다.
  - 예시) 정책 'MyPolicy'는 "Org1의 피어" 또는 "Org2의 피어"의 서명이 필요하다.
    ```yaml
    Policies:
        MyPolicy:
            Type: Signature
            Rule: “Org1.Peer OR Org2.Peer”    
    ```

- ImplicitMeta
  - 간단하고 포괄적인 표현으로 정책을 설정할 수 있다. 
  - <ALL | ANY | MAJORITY> <sub_policy> 방식으로 작성된다.
  - sub_policy: Admin, Writer, Reader가 있다.
    - Admin: 운영 역할을 가지며, 체인코드의 인스턴스화 같은 중요한 측면을 주로 담당한다.
    - Writer: 트랜잭션, 원장 업데이트 등을 주로 담당하며 관리 역할은 없다.
    - Reader: 정보에 엑세스 할 수는 있지만, 원장 업데이트나 관리 역할은 주어지지 않는다.
  - *NodeOU가 활성화 되어 있으면 피어 또는 클라이언트에 의해 변경될 수 있다.*
  - 예시) 정책 'AnotherPolicy'는 MAJORITY한 Admin들의 서명이 필요하다.
    ```yaml
    Policies:
        AnotherPolicy:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
    ```

<br>

## How ACLs are formatted in configtx.yaml

ACL은 configtx.yaml에서 key-value 형태로 작성된다.  
key는 자원을, value는 해당 자원의 정식 경로를 나타낸다.

```yaml
# ACL policy for invoking chaincodes on peer
peer/Propose: /Channel/Application/Writers
# ACL policy for sending block events
event/Block: /Channel/Application/Readers
```

<br>

### Updating ACL defaults in configtx.yaml

네트워크가 부트스트랩 되기 전 직접 configtx.yaml 파일을 수정하는 방법이다.

만약 peer/Propose에 대한 value를 /Channel/Application/Writers 에서 MyPolicy로 변경한다고 하자.  
먼저 MyPolicy 정책을 configtx.yaml의 Application.Policies에 추가한다.

```yaml
Policies: &ApplicationDefaultPolicies
    Readers:
        Type: ImplicitMeta
        Rule: "ANY Readers"
    Writers:
        Type: ImplicitMeta
        Rule: "ANY Writers"
    Admins:
        Type: ImplicitMeta
        Rule: "MAJORITY Admins"
    MyPolicy:
        Type: Signature
        Rule: "OR('SampleOrg.admin')"
```
- 여기서는 SampleOrg의 Admin의 서명을 필요로 하도록 작성한다.

이후, Application: ACLs 섹션에서 peer/Propose 값을 다음과 같이 변경한다.
- peer/Propose: /Channel/Application/MyPolicy

<br>

### Updating ACL defaults in the channel config

변경하고자 하는 ACL을 사용하는 채널이 이미 생성된 경우(일반적으로 네트워크가 이미 부트스트랩 된 이후), 블록에 구성된 ACL 요소를 하나씩 변경하는 방법이다. 

configtx.yaml에 작성되어 있는 다양한 Policy 중 하나로 변경한다.  
(즉, 먼저 configtx.yaml 파일에 사용하고자 하는 정책을 작성해놓아야 한다)

아래 [소스](#source)에서는 MyPolicy라는 정책을 추가하고, 네트워크에 채널이 생성된 이후 peer/Propose 정책의 경로를 MyPolicy로 변경하는 작업을 진행한다.

<br>

## Source

### 새로운 정책(MyPolicy) 작성

configtx.yaml에 MyPolicy라는 새로운 Policy를 작성한다.

```yaml
Application: &ApplicationDefaults    
    ...
    Policies: &ApplicationDefaultPolicies
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        MyPolicy:   # 추가
            Type: Signature
            Rule: "OR('Org1MSP.client')"
```

<br>

### 네트워크 부트스트랩, 채널 생성

BYFN(Build Your First Network)를 이용하여 자동으로 체인코드 인스턴스화까지 진행한다.

```bash
./byfn.sh up
```

<br>

### cli

```bash
docker exec -it cli /bin/bash
```

<br>

### 새로운 Policy 적용

#### 1. 채널 fetch

```bash
peer channel fetch config config_block.pb -o orderer.example.com:7050 -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

#### 2. 블록 파일(config_block.pb)을 JSON 형태로 변환

```bash
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
```

#### 3. 값 변경을 위한 사본 생성
```bash
cp config.json modified_config.json
```

#### 4. peer/Propose Policy 값 변경
```bash
sudo vi modified_config.json


    "values": {
        "ACLs": {
            "mod_policy": "Admins",
                "value": {
                    "acls": {
                        "cscc/GetConfigBlock": {
                            "policy_ref": "/Channel/Application/Readers"
                        },
                        "peer/Propose": {
                            "policy_ref": "/Channel/Application/MyPolicy" # 변경

```
- /Channel/Application/Writers -> /Channel/Application/MyPolicy로 변경

#### 5. modified_config.json 블록으로 변환
```bash
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
```

#### 6. config.json -> config.pb 블록으로 변환
```bash
configtxlator proto_encode --input config.json --type common.Config --output config.pb
```

#### 7. 수정 전후의 블록 비교
```bash
configtxlator compute_update --channel_id mychannel --original config.pb --updated modified_config.pb --output diff_config.pb
```

#### 8. diff_config.pb JSON 형태로 변환
```bash
configtxlator proto_decode --input diff_config.pb --type common.ConfigUpdate | jq . > diff_config.json
```

#### 9. 헤더 값(채널 정보) 추가
```bash
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat diff_config.json)'}}}' | jq . > diff_config_envelope.json
```

#### 10. diff_config_envelope.pb 블록 생성
```bash
configtxlator proto_encode --input diff_config_envelope.json --type common.Envelope --output diff_config_envelope.pb
```

#### 11. 변경된 내역 Sign
- 기존의 peer/Propose는 Application/Writer 였기 때문에, Org1과 Org2에서 Sign한다.

```bash
#### Org1 Admin
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID="Org1MSP"

peer channel signconfigtx -f diff_config_envelope.pb

#### Org2 Admin
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.org2.example.com:9051
export CORE_PEER_LOCALMSPID="Org2MSP"

peer channel signconfigtx -f diff_config_envelope.pb

### Channel Update
peer channel update -f diff_config_envelope.pb -c mychannel -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

#### 12. 결과 확인
```bash
# 체인코드 invoke
peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'
```
- org1 (성공)
  - 2020-01-16 08:15:11.834 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200
- org2 (오류)
    - Error: error endorsing invoke: rpc error: code = Unknown desc = failed evaluating policy on signed data during check policy [/Channel/Application/MyPolicy]: [signature set did not satify policy] - proposal response: nil

<br>

peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'

### MyPolicy의 Rule 수정하기

새로운 Policy를 등록할 때와 동일하게 진행되나, 값을 변경하는 부분만 다르게 한다.

MyPolicy의 Rule을 Org1MSP에서 Org2MSP로 변경한다.

```bash
sudo vi modified_config.json

"MyPolicy": {
    "mod_policy": "Admins",
    "policy": {
        "type": 1,
        "value": {
            "identities": [
                {
                    "principal": {
                        "msp_identifier": "Org2MSP", # 변경
                        "role": "CLIENT"
                    },
                    "principal_classification": "ROLE"
                }
            ],
            "rule": {
                "n_out_of": {
                    "n": 1,
                    "rules": [
                        {
                            "signed_by": 0
                        }
                    ]
                }
            },
            "version": 0
```
- Org1MSP -> Org2MSP

값을 변경한 후, 새로운 Policy를 등록할 때와 동일한 순서로 채널 업데이트까지 마무리한다.

<br>

#### 결과 확인
- org1 (오류)
    - Error: error endorsing invoke: rpc error: code = Unknown desc = failed evaluating policy on signed data during check policy [/Channel/Application/MyPolicy]: [signature set did not satify policy] - proposal response: nil
- org2 (성공)
    - 2020-01-16 08:15:11.834 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200







