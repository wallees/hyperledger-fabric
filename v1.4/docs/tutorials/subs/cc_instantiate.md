# 체인코드 인스턴스화
> 채널 별로 체인코드 인스턴스화는 '한 번' 가능하다.

<br/>

## TLS 적용 안하는 경우
<pre><code>peer chaincode instantiate -o orderer.example.com:7050 -C $CHANNEL_NAME -n mycc -l ${LANGUAGE} -v ${VERSION} -c '{"Args":["init","a","100","b","200"]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')"</code></pre>
- -o : 오더러
- -C : 채널명
- -n : 체인코드명
- -l : 체인코드 언어(설치 때 명시한 내용과 동일)
- -c : 체인코드 초기화 시 아규먼트(첫 체인코드 호출)
- -v : 
- -P : 체인코드 정책(AND 또는 OR)

<br/>

## TLS 적용 시
<pre><code>peer chaincode instantiate -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -l ${LANGUAGE} -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')"</code></pre>
- --tls : tls 적용하겠다는 의미
- --cafile : 오더러의 CA 파일 경로

