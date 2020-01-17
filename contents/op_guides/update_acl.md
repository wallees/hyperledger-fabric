# 채널 ACL 값 변경하기
> BYFN으로 구성된 채널의 ACL 값을 변경한다.

<br/>

## 기존 Policy
<pre><code>Policies: &ApplicationDefaultPolicies
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"</code></pre>

<pre><code># ACL policy for invoking chaincodes on peer
peer/Propose: /Channel/Application/Writers</code></pre>

<br/>

## configtx.yaml에 ACL 추가하기(Optional)

일부 first-network 내부의 configtx.yaml 파일에는 ACL 내용이 작성되지 않은 경우가 있다.  
작성되어있지 않다면, 동적으로 ACL을 적용하기 위해 ACLs를 추가한다.

샘플 기준으로 __fabric-samples/config/configtx.yaml__ 의 ACLs를 first-network의 configtx.yaml의 동일한 위치(Application: &ApplicationDefaults) 에 복사한다.

<pre><code>Application: &ApplicationDefaults
    ACLs: &ACLsDefault
        # fabric-samples/config/configtx.yaml의 이 부분을 
        # fabric-samples/first-network.configtx.yaml로 복사
        ...
    # Organizations lists the orgs participating on the application side of the
    # network.
    Organizations:
    ...
</code></pre>

<br/>

## 새로운 Policy 작성하기

MyPolicy라는 새로운 Policy를 작성한다.

> _fabric-samples/first-network/configtx.yaml -> line 231_
<pre><code>...
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
        MyPolicy:
            Type: Signature
            Rule: "OR('Org1MSP.client')"
</code></pre>

<br/>

## Build Your First Network 실행

새롭게 작성된 정책이 포함된 first-network의 byfn을 실행한다.

<pre><code>$ ./byfn.sh up</code></pre>

<br/>

## Cli 컨테이너 실행

<pre><code>$ docker exec -it cli bash</code></pre>
- __이후의 모든 작업은 cli 컨테이너 내부에서 진행한다.__

<br/>

## 새로운 Policy 적용하기

### 환경변수 설정하기

<pre><code>$ export CHANNEL_NAME=mychannel
$ export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem</code></pre>

### 현재 채널의 설정 값 가져오기(fetch)
<pre><code>$ peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA</code></pre>

### 블록 파일(config_block.pb)을 JSON 형태로 변환하기
<pre><code>$ configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json</code></pre>

### 값을 변경할 사본 만들기
<pre><code>$ cp config.json modified_config.json</code></pre>

### peer/Propose Policy 값 변경하기
> sudo vi modified_config.json
<pre><code>...
426         "values": {
427           "ACLs": {
428             "mod_policy": "Admins",
429             "value": {
430               "acls": {
431                 "cscc/GetConfigBlock": {
432                   "policy_ref": "/Channel/Application/Readers"
433                 },
...                 ...
461                 "peer/Propose": {
462                   "policy_ref": "/Channel/Application/MyPolicy"
...                 ...
</code></pre>
- line 462 : /Channel/Application/Writers -> /Channel/Application/MyPolicy

### 수정된 modified_config.json 파일을 블록으로 변환하기
<pre><code>$ configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb</code></pre>

### config.json 파일을 config.pb 블록파일로 변환하기
<pre><code>$ configtxlator proto_encode --input config.json --type common.Config --output config.pb</code></pre>

### 수정 전후의 블록 파일을 비교하기
<pre><code>$ configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output diff_config.pb</code></pre>

### 블록 파일(diff_config.pb)을 JSON 형태로 변환하기
<pre><code>$ configtxlator proto_decode --input diff_config.pb --type common.ConfigUpdate | jq . > diff_config.json</code></pre>

### diff_config.json 파일에 헤더 값(채널 정보) 붙이기
<pre><code>$ echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat diff_config.json)'}}}' | jq . > diff_config_envelope.json</code></pre>

### diff_config_envelope.json 파일을 diff_config_envelope.pb 블록파일로 변환하기
<pre><code>$ configtxlator proto_encode --input diff_config_envelope.json --type common.Envelope --output diff_config_envelope.pb</code></pre>

### 변경된 내역 Sign 하기
> peer/Propose는 Application/Writer에 해당하므로, Org1과 Org2에서 Sign한다.

#### Org1 Admin
<pre><code>$ export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
$ export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
$ export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
$ export CORE_PEER_LOCALMSPID="Org1MSP"</code></pre>
<pre><code>$ peer channel signconfigtx -f diff_config_envelope.pb</code></pre>

#### Org2 Admin
<pre><code>$ export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
$ export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
$ export CORE_PEER_ADDRESS=peer0.org2.example.com:7051
$ export CORE_PEER_LOCALMSPID="Org2MSP"</code></pre>
<pre><code>$ peer channel signconfigtx -f diff_config_envelope.pb</code></pre>

### 채널 업데이트 하기
<pre><code>$ peer channel update -f diff_config_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA</code></pre>

### 결과 확인
> 체인코드 invoke
<pre><code>peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'</code></pre>

#### Org1에서 체인코드 invoke
<pre><code>2020-01-16 08:15:11.834 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200</code></pre>

#### Org2에서 체인코드 invoke
<pre><code>Error: error endorsing invoke: rpc error: code = Unknown desc = failed evaluating policy on signed data during check policy [/Channel/Application/MyPolicy]: [signature set did not satify policy] - proposal response: nil </code></pre>
- Org2에서는 오류가 나는 것을 확인할 수 있다.

<br/>

## MyPolicy의 Rule 수정하기

새로운 Policy를 등록할 때와 동일하게 진행되나, 값을 변경하는 부분만 다르게 한다.

### MyPolicy의 Rule 변경하기

MyPolicy의 Rule을 Org1MSP에서 Org2MSP로 변경한다.
> sudo vi modified_config.json
<pre><code>...
374           "MyPolicy": {
375             "mod_policy": "Admins",
376             "policy": {
377               "type": 1,
378               "value": {
379                 "identities": [
380                   {
381                     "principal": {
382                       "msp_identifier": "Org2MSP",
383                       "role": "CLIENT"
384                     },
385                     "principal_classification": "ROLE"
386                   }
387                 ],
388                 "rule": {
389                   "n_out_of": {
390                     "n": 1,
391                     "rules": [
392                       {
393                         "signed_by": 0
394                       }
395                     ]
396                   }
397                 },
398                 "version": 0
</code></pre>
- line 382 : Org1MSP -> Org2MSP

값을 변경한 후, 새로운 Policy를 등록할 때와 동일한 순서로 채널 업데이트까지 마무리한다.

### 결과 확인

#### Org1에서 체인코드 invoke
<pre><code>Error: error endorsing invoke: rpc error: code = Unknown desc = failed evaluating policy on signed data during check policy [/Channel/Application/MyPolicy]: [signature set did not satify policy] - proposal response: nil </code></pre>
- Org1에서는 오류가 나는 것을 확인할 수 있다.

#### Org2에서 체인코드 invoke
<pre><code>2020-01-16 08:15:11.834 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200</code></pre>