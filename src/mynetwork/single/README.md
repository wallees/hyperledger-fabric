

# 싱글노드 기반 test-network 구축

- Hyperledger fabric version: v2.2
- 구성
  - 네트워크: mynetwork
  - 도메인: mynetwork.com
    - orderer: orderer1.mynetwork.com, orderer2.mynetwork.com, orderer3.mynetwork.com
    - org1: peer1.org1.mynetwork.com
    - org2: peer1.org2.mynetwork.com
  - VM: 총 1대
- 경로: /root/git/src/mynetwork/single

<br>

## 진행 순서

1. 프로파일 생성
2. 도커 실행
3. 채널 생성
4. 체인코드 설치 및 배포 
5. 테스트

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

      - 기존의 v1.4.4까지는 해당 정책을 주석처리 해도 문제없이 genesis block을 생성할 수 있었다.

  - 확인하던 중, Organizations/&Org 부분에 처음보는 정책을 확인(v1.4.4 까지는 sample config.yaml에서 확인 못했음)

    ```
    - &Org1        
            Name: Org1MSP
            ID: Org1MSP
            MSPDir: /root/git/src/mynetwork/single/data/cryptofile/peerOrganizations/org1.mynetwork.com/msp
            Policies:
                Readers:
                    Type: Signature
                    Rule: "OR('Org1MSP.admin', 'Org1MSP.peer', 'Org1MSP.client')"
                Writers:
                    Type: Signature
                    Rule: "OR('Org1MSP.admin', 'Org1MSP.client')"
                Admins:
                    Type: Signature
                    Rule: "OR('Org1MSP.admin')"
                Endorsement: #<- 기존에는 Endorsement 정책이 없었다. 내가 못찾았던 것일까?
                    Type: Signature
                    Rule: "OR('Org1MSP.peer')"
    ```

  - Policies의 Rule 부분을 변경해보기로 함(Org1만)

    ```
     - &Org1
            Name: Org1MSP
            ID: Org1MSP
            MSPDir: /root/git/src/mynetwork/single/data/cryptofile/peerOrganizations/org1.mynetwork.com/msp
            Policies:
                Readers:
                    Type: Signature
                    # Rule: "OR('Org1MSP.admin', 'Org1MSP.peer', 'Org1MSP.client')"
                    Rule: "OR('Org1MSP.member')" #<- 변경
                Writers:
                    Type: Signature
                    # Rule: "OR('Org1MSP.admin', 'Org1MSP.client')"
                    Rule: "OR('Org1MSP.member')" #<- 변경
                Admins:
                    Type: Signature
                    Rule: "OR('Org1MSP.admin')"
                Endorsement:
                    Type: Signature
                    Rule: "OR('Org1MSP.peer')"
            AnchorPeers:
                - Host: peer1.org1.mynetwork.com
                  Port: 7051
    ```

- **결과: 정상적으로 채널이 생성됨. 오류 메시지와는 조금 맞지 않아서 재확인이 필요함**





