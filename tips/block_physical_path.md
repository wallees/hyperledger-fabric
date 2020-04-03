# 하이퍼레저 네트워크에 생성된 블록 확인하기

__Answer:__   
To see the physical location of these data you can go to __/var/hyperledger/production__ in each peer container in your fabric network ([Stackoverflow](https://stackoverflow.com/questions/48764151/where-is-the-blockchain-physically))

<br/>

## 전제

- fabric-samples의 byfn을 이용하여 블록체인 시스템 구동
  <pre><code>$ ./byfn -m up</code></pre>
- 블록이 얼마나 쌓여있는지 확인하기 위해 peer0.org1.example.com 컨테이너로 진입
  <pre><code>$ docker exec -it peer0.org1.example.com /bin/bash</code></pre>
- 위에서 언급한 블록이 쌓이는 위치로 이동
  <pre><code>$ cd /var/hyperledger/production/  
  $ root@f217cebc0267:/var/hyperledger/production# ls
  chaincodes  ledgersData  transientStore </code></pre>

<br/>

## 현재까지 생성된 블록
<pre><code> $ cd /var/hyperledger/production/ledgersData/chains/chains/mychannel</code></pre>
  - BYFN 실행 직후라서 하나의 블록이 생성되어 있음을 볼 수 있다.
    > <pre><code>blockfile_000000</code></pre>

<br/>

## 데이터베이스
<pre><code>$ cd /var/hyperledger/production/ledgersData/stateLeveldb</code></pre>
  - 데이터(원장)이 아닌 곳은 대부분 아래와 같은 구조로 구성되어 있다.
    > <pre><code>000001.log  CURRENT  LOCK  LOG  MANIFEST-000000</code></pre>

<br/>

## 체인코드
<pre><code>$ cd /var/hyperledger/production/chaincodes</code></pre>
  - 현재 install/instantiate 된 체인코드와 체인코드의 버전을 보여준다.
    > <pre><code>mycc.1.0</code></pre>

<br/>

## 각 저장소 별 설명

### 1. The ledger ([원장](http://hyperledger-fabric.readthedocs.io/en/release/ledger.html))

실제 '블록체인'을 의미하며, 연속된 블록(Serialized block)을 저장하는 파일 기반으로 이루어져있다.  
각 블록에는 하나 이상의 트랜잭션(transaction, tx)이 존재하는데, 각 트랜잭션 별로 하나 이상의 key/value 쌍을 수정 또는 작성할 수 있는 Read/Write Set을 가지고 있다.  

원장은 Hyperledger Fabric 내에서 채널 마다 독립적으로 존재한다.

__원장은 블록체인을 구성하는 데이터 그 자체이므로, 변경하거나 삭제할 수 없다.__

### 2. The state database (World State)

Statedb(또는 World State)는 특정 키에 대해 최종적으로 커밋된(반영된) 값을 갖는다.  
블록체인 내에서 각 피어가 트랜잭션의 유효성을 검사한 후 커밋을 완료할 때 statedb에 값이 반영된다.  
Statedb는 각 트랜잭션의 최종 값이지만 블록(원장)은 아니므로, 원장이 재 처리될 경우 statedb 값은 변경될 수 있다.  

현재 LevelDB 또는 CouchDB 두가지 옵션으로 구성할 수 있다.

### 3. Chain

체인은 해시(Hash) 링크 블록으로 구성된 트랜잭션의 로그들인데, 각 블록마다 N개의 트랜잭션이 존재한다.  
(블록 내에 존재하는 트랜잭션의 갯수는 블록체인 네트워크를 구성할 때 설정할 수 있다)  

각 블록의 헤더에는 블록 트랜잭션의 해시와 이전 블록 헤더의 해시가 포함되는데, 일정 수 이상의 트랜잭션들이 순서대로 하나의 블록을 이루는 과정에서 원장의 모든 거래가 암호화되어 연결된다.
