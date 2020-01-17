# 체인코드 업그레이드

> 기존 체인코드의 버전보다 증가된 버전을 사용해야 한다.

<br/>

## TLS 적용 안하는 경우
<pre><code>peer chaincode upgrade -o orderer.example.com:7050 -C mychannel -n mycc -v 1.2 -c '{"Args":["init","a","100","b","200"]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')"</code></pre>

<br/>

## TLS 적용 시
<pre><code>peer chaincode upgrade -o orderer.example.com:7050 --tls --cafile $ORDERER_CA -C mychannel -n mycc -v 1.2 -c '{"Args":["init","a","100","b","200"]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')"</code></pre>

