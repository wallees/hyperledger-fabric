# Private data

## What is private data?

하이퍼레저 패브릭 v1.2부터 제공되고 있으며, 채널 내 org별로 데이터를 관리하고 싶은 경우에 사용한다.  
예를 들어 채널 'mychannel' 내부에 org1, org2, org3가 있다고 가정할 때, 이중 org1, org2에만 접근 가능한 데이터를 구분하기 위해 사용된다.  
기존에는 org1, org2를 위한 별도의 채널을 구성했지만, private data를 사용하면 체인코드 버전, 정책, MSP 등의 추가관리요소 없이 데이터를 org 별로 관리할 수 있게 된다.

<br>

## What is a private data collection?

collection은 두가지 요소로 구성된다.
1. The actual private data
    - 가십프로토콜(Gossip Protocol)을 통해 권한이 부여된 org에만 전송되는 데이터
    - side database라고 불리는 특정 공간에 저장된다.
    - 오더링 서비스를 이용해서 데이터를 확인할 수 없다.
    - org간 통신을 위해, 피어 별 CORE_PEER_GOSSIP_EXTERNALENDPOINT 를 구성해야 한다.

2. A hash of that data
    - endorsing, ordering을 거쳐 모든 피어의 원장에 기록되는 데이터
    - 트랜잭션이 일어났음을 검증하기 위해 사용된다.

<br>

- ### When to use a collection within a channel vs. a separate channel
  1. 채널에서 특정 org에만 기밀로 유지되어야 하는 데이터가 있을 경우
  2. 데이터에 접근 가능한 org를 계층적으로 구분해야 하는 필요가 있을 경우

<br>

## Transaction flow with private data

데이터의 기밀성을 유지하기 위해, private data에서는 propose, endorse, commit 과정이 다르게 진행된다.

1. 애플리케이션에서 private data를 위한 체인코드 함수를 호출하면, collection 내부에 권한이 부여된 org의 endorsing peer에게 proposal을 요청한다. **이 때 private data는 proposal 내 transient 필드에 위치한다.**
2. Endorsing peer는 트랜잭션을 시뮬레이션하고, 이를 transient data store에 저장한다. 이후 가쉽을 이용하여 private data를 collection policy에 지정된 peer에게 배포한다.
3. Endorsing peer는 proposal의 결과값(공개 데이터를 포함한 Read/Write set, private data의 key/value 해시값)을 클라이언트에게 돌려준다. 이 때 private data는 보내지 않는다.
4. 애플리케이션은 private data의 해시가 포함된 트랜잭션을 ordering service에 전송하고, 이는 블록으로 만들어져 모든 peer에게 배포된다. 이를 통해 **채널 내부의 모든 peer는 실제 private data를 몰라도 이에 대한 해시와 트랜잭션은 일관된 상태롸 관리하게 된다.**
5. 블록을 commit할 때, 피어는 collection policy를 이용하여 자신에게 private data의 접근 권한이 있는지 확인한다. 이후 체인코드 endorse 과정에서 로컬의 transient 데이터 저장소에 private data가 저장되었는지 확인하고, 없으면 다른 승인된 피어로부터 데이터를 가져온다. 이후 블록의 해시값과 private data의 유효성을 판단하고 블록을 commit 한다. 이후 private data는 transient 데이터 저장소에서 삭제된다.

<br>

## Purging private data

private data는 주기에 따라 삭제되고, 이를 트랜잭션에 남겨 증거를 기록할 수도 있다.  
단, private data는 peer의 private database에만 존재해야 한다.  
특정 블록 수 이상으로 수정되지 않았을 경우 삭제가 가능하며, 삭제된 데이터는 조회 또는 요청할 수 없다.

