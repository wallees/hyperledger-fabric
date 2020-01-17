# 채널 설정 값 변경하기

> 구성된 채널의 특정 설정 값(max_message_count)을 변경한다.

<br/>

## 1. cli 컨테이너 들어가기
<pre><code>docker exec -it cli bash</code></pre>

## 2. 환경변수 설정하기
<pre><code>export CHANNEL_NAME=mychannel
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051</code></pre>

## 3. 현재 채널 설정 값 가져오기(fetch)
<pre><code>peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA</code></pre>

## 4. 블록파일 JSON 형태로 변환하기
<pre><code>configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json</code></pre>

## 5. 값을 변경할 사본 만들기
<pre><code>cp config.json modified_config.json</code></pre>

## 6. 값 변경하기
<pre><code>vim modified_config.json</code></pre>
> _modified_config.json : line 590_
<pre><code>   ...
        "values": {
          "BatchSize": {
            "mod_policy": "Admins",
            "value": {
              "absolute_max_bytes": 103809024,
              "max_message_count": 10,
              "preferred_max_bytes": 524288
            },
            "version": "0"
          }
    ...</code></pre>
- max_message_count : 10 -> 11

## 7. modified_config.json 파일을 블록으로 변환하기
<pre><code>configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb</code></pre>

## 8. config.json 파일을 config.pb 블록파일로 변환하기
<pre><code>configtxlator proto_encode --input config.json --type common.Config --output config.pb</code></pre>

## 9. 수정 전후 delta 값 비교하기
<pre><code>configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output diff_config.pb</code></pre>

## 10. 블록 파일(diff_config.pb)을 JSON 형태로 변환하기
<pre><code>configtxlator proto_decode --input diff_config.pb --type common.ConfigUpdate | jq . > diff_config.json</code></pre>

## 11. diff_config.json 파일에 헤더 값(채널 정보) 붙이기
<pre><code>echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat diff_config.json)'}}}' | jq . > diff_config_envelope.json</code></pre>

## 12. 헤더 정보 붙인 값을 블록 파일로 변환하기
<pre><code>configtxlator proto_encode --input diff_config_envelope.json --type common.Envelope --output diff_config_envelope.pb</code></pre>

## 13. 최종 변경된 내용 오더러로 사인하기
<pre><code>export CORE_PEER_ADDRESS=orderer.example.com:7050
export CORE_PEER_LOCALMSPID="OrdererMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/users/Admin\@example.com/msp</code></pre>
<pre><code>peer channel signconfigtx -f diff_config_envelope.pb</code></pre>

## 14. 채널 업데이트하기
<pre><code>peer channel update -f diff_config_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA</code></pre>

## 15. 결과 확인
<pre><code>peer channel fetch config config_block2.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA</code></pre>
<pre><code>configtxlator proto_decode --input config_block2.pb --type common.Block | jq .data.data[0].payload.data.config > config2.json</code></pre>
<pre><code>vim config2.json</code></pre>
> _config2.json : line 590_
<pre><code>   ...
        "values": {
          "BatchSize": {
            "mod_policy": "Admins",
            "value": {
              "absolute_max_bytes": 103809024,
              "max_message_count": 11,
              "preferred_max_bytes": 524288
            },
            "version": "0"
          }
    ...</code></pre>