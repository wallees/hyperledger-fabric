

# 멀티노드 기반 test-network 구축

- Hyperledger fabric version: v2.2
- 구성
  - 네트워크: mynetwork
  - 도메인: mynetwork.com
    - orderer: orderer1.mynetwork.com, orderer2.mynetwork.com, orderer3.mynetwork.com
    - org1: peer1.org1.mynetwork.com
    - org2: peer1.org2.mynetwork.com. peer2.org2.mynetwork.com
  - VM: 총 3대
    - [instance0](instance0/docker/docker-compose-mynetwork.yaml): orderer1.mynetwork.com
    - [instance1](instance1/docker/docker-compose-mynetwork.yaml): orderer2.mynetwork.com, peer1.org1.mynetwork.com
    - [instance2](instance2/docker/docker-compose-mynetwork.yaml): orderer3.mynetwork.com, peer1.org2.mynetwork.com, peer2.org2.mynetwork.com
- 경로: /root/git/src/mynetwork/instance ...

<br>

## 진행 순서

1. 프로파일 생성 ([instance0](instance0/script/create_profile.sh))
2. 도커 실행 ([instance0](instance0/docker/docker-compose-mynetwork.yaml), [instance1](instance1/docker/docker-compose-mynetwork.yaml), [instance2](instance2/docker/docker-compose-mynetwork.yaml))
3. 채널 생성 ([instance0](instance0/script/create_channel.sh))
4. 체인코드 설치 및 배포 ([instance0](instance0/script/deploy_chaincode.sh))
5. 테스트 (instance0, instance1, instance2)

<br>

## 이슈사항



채널 생성 과정에서 '*error authorizing update: error validating DeltaSet: policy for [Group] /Channel/Application not satisfied: implicit policy evaluation failed - 0 sub-policies were satisfied, but this policy requires 1 of the 'Admins' sub-policies to be satisfied*' 오류 발생

- orderer의 cryptogen 과정에서 User를 추가함으로 발생하는 오류였음 

- [crypto-config-orderer.yaml](instance0/util/cryptogen/crypto-config-orderer.yaml) 

  ```
  OrdererOrgs:
    - Name: Orderer
      Domain: mynetwork.com
      EnableNodeOUs: true
      Template:
        Count: 3
        Start: 1
      # Users:
      #   Count: 3 <- 이부분을 추가하면서 발생하는 오류였음. configtx.yaml과 연관되어 권한의 오류가 생겼을 것이라 생각됨
  ```



**OrdererOrgs/Users 부분을 추가하더라도 오류가 나지 않도록 하는 방법은 없을까?**

- [configtx.yaml](instance0/util/configtx/configtx.yaml)

  - Orderer/Policies 부분을 전부 주석처리

    ```
    Orderer: &OrdererDefaults
        ....
        
        Policies:		# 해당 부분을 전부 주석처리한다면?
            Readers:
                Type: ImplicitMeta
                Rule: "ANY Readers"
            Writers:
                Type: ImplicitMeta
                Rule: "ANY Writers"
            Admins:
                Type: ImplicitMeta
                Rule: "MAJORITY Admins"
            BlockValidation:
                Type: ImplicitMeta
                Rule: "ANY Writers"
    ```

    - Genesis block 생성 과정에서 오류 발생

      > Error on outputBlock: could not create bootstrapper: could not create channel group: could not create orderer group: error adding policies to orderer group: no policies defined

  - 