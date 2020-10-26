# Service Discovery

## Why do we need service discovery?

하이퍼레저 패브릭 v1.2 부터 적용된 방식으로, 이전의 '정적'인 방식은 다음의 문제점을 갖고 있었다.
- 네트워크의 변경(체인코드가 설치된 피어 추가, 정지 등)에 대해 추가적인 작업이 없이는 동적으로 확인할 수 없음.
- 어느 피어가 원장을 업데이트 했는지 알 수 없으므로, 동기화되지 않은 피어에게 불필요한 proposal을 보낼 수 있음.

The discovery service improves this process by having the peers **compute the needed information dynamically** and **present it to the SDK in a consumable manner**. 
- 피어가 필요한 정보를 동적으로 계산하고, 이를 SDK에게 동적으로 전달해줌으로써 위의 문제를 해결하였다.

<br>

## How service discovery works in Fabric

- 동일한 org 내에 있는 피어를 사용하는 것이 좋다.
- 피어에서 EXTERNAL_ENDPOINT를 사용한다.
  - 서비스 디스커버리를 사용하기 위해 꼭 필요하다.
  - 예시) CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer1.org1.example.com:8051
- 응용프로그램이 아닌 피어에서 실행되며, 가십 통신 계층에서 관리되는 메타데이터 정보를 이용하여 온라인으로 피어를 검색하며, 피어의 statedb에서 관련된 endorsement policy를 가져온다.
  
그러므로 서비스 디스커버리를 통해, 응용프로그램은 인증과정이 필요한 피어를 별도로 지정하지 않아도 된다.  

SDK에서 채널명과 체인코드ID 값을 이용하여 필요한 피어가 누구인지 묻는 쿼리를 서비스 디스커버리로 보내면 다음의 결과 값을 얻게 된다.
- Layouts: 피어 그룹과 피어 수
- Group to peer mapping: layout의 그룹에서 채널 당 피어 목록


AND(Org1, Org2)을 표현하면 다음과 같다.

```yaml
Layouts: [
     QuantitiesByGroup: {
       “Org1”: 1,
       “Org2”: 1,
     }
],
EndorsersByGroups: {
  “Org1”: [peer0.org1, peer1.org1],
  “Org2”: [peer0.org2, peer1.org2]
}
```

<br>

### Capabilities of the discovery service

서비스 디스커버리는 다음의 요청(query)에 응답할 수 있다.
- Configuration query: 채널의 오더러 endpoint를 포함한 모든 org의 MSPConfig 값 반환.
- Peer membership query: 채널에 가입한 피어 반환.
- Endorsement query: 채널 내 특정 체인코드의 endorsement descriptor 반환.
- Local peer membership query: 쿼리에 응답하는 피어의 로컬 멤버 자격 반환.
  - 클라이언트가 Admin 권한일 경우에 피어에서 이 쿼리에 대해 응답 가능.

<br>

### Special requirements

피어가 TLS 기능을 사용하고 있다면, 클라이언트는 피어에 연결할 때 TLS 인증서를 제공해야만 한다. 
