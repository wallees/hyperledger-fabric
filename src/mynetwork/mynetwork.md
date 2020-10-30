

# 멀티노드 기반 test-network 구축

- Hyperledger fabric version: v2.2
- 구성
  - 네트워크: mynetwork
  - 도메인: mynetwork.com
    - orderer: orderer1.mynetwork.com, orderer2.mynetwork.com, orderer3.mynetwork.com
    - org1: peer1.org1.mynetwork.com
    - org2: peer1.org2.mynetwork.com. peer2.org2.mynetwork.com
  - VM: 총 3대
    - [instance0](/instance0/docker/docker-compose-mynetwork.yaml): orderer1.mynetwork.com
    - [instance1](/instance1/docker/docker-compose-mynetwork.yaml): orderer2.mynetwork.com, peer1.org1.mynetwork.com
    - [instacne2](/instance2/docker/docker-compose-mynetwork.yaml): orderer3.mynetwork.com, peer1.org2.mynetwork.com, peer2.org2.mynetwork.com
- 경로: /root/git/src/mynetwork/instance ...



## 진행 순서

1. 프로파일 생성 ([instance0](instance0/script/create_profile.sh))
2. 도커 실행 ([instance0](instance0/docker/docker-compose-mynetwork.yaml), [instance1](instance1/docker/docker-compose-mynetwork.yaml), [instance2](instance2/docker/docker-compose-mynetwork.yaml))
3. 채널 생성 ([instance0](instance0/script/create_channel.sh))
4. 체인코드 설치 및 배포 (instance0)
5. 테스트 (instance0, instance1, instance2)

