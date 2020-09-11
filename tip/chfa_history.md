# CHFA 복기

## 1. 2020.09.11 06:00

### Summary
- Questions: 14

### Questions
1. 체인코드 install
    - Language : Node
    - 체인코드 이름, 경로 모두 제공
    - 피어와 Org 각각의 환경값이 제공되는 경우, 해당 체인코드를 모든 피어에 설치해야 하는 것으로 보임
    - peer chaincode install -n testcc -v 1.0.0 -l node -p /opt/gopath/src/github.com/chaincode/chaincode_example02/node

2. 체인코드 Instantiate
    - 인스톨과 비슷하게 모두 제공됨
    - Policy를 Default로 할지, 혹은 특정 값으로 할지 주어짐
    - peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT_PATH -C mychannel -n testcc -v 1.0.0 -c '{"Args":["init","a","100","b","200"]}'

3. Channel의 Writer 정책을 Majority of Admins로 변경
    - configtx.yaml > Channel > Writer 값을 변경
    - 변경 후 docker 컨테이너 재시작(스크립트 제공)

4. Updating a Channel Configuration
    - max_message_count 값을 10->20으로 변경 (readthedocs 예제와 동일)

5. 체인코드 업그레이드

6. Genesis block 생성
    - 특정 프로파일이름을 변경(Sample2OrdererGenesis)하고, 이를 이용하여 genesis 블록을 만들고(genesisA.block) 이에 대한 정보를 orderer.yaml에 등록
    - orderer.yaml에 등록하는 방법을 정확하게 알지 못함. 좀 찝찝함
        - orderer.yaml > GenesisProfile 값(Sample2OrdererGenesis)과 GenesisFile 값(genesisAblock)을 변경

7. Static leader 설정
    - 특정 Org에서 특정 Peer를 leader로 선출
    - docker-compose-cli.yaml 파일에서 해당하는 Peer에 environment를 부여하고, 해당 정책을 부여함
    - On the existing Fabric network on node fab-00-07 with configuration files located at /srv/fabric-samples/, which is comprised of two Organisations (Org1 & Org2) with 2 peers on each, configure to enable a static leader election policy for Organisation org2 and set peer1 as the leader. Restart the fabric network to reflect the changes.
        - peer0.org2
            - CORE_PEER_GOSSIP_USELEADERELECTION=false
            - CORE_PEER_GOSSIP_ORGLEADER=false
        - peer1.org2
            - CORE_PEER_GOSSIP_USELEADERELECTION=false
            - CORE_PEER_GOSSIP_ORGLEADER=true

8. Raft로 네트워크 구동
    - configtx.yaml에 해당 프로파일 적혀있음

9. Hyperledger Fabric CA has been installed in node fab-00-23. Create an identity with name userABC of type user, affiliation as org1.department1 and secret as passwd. + 권한(Registry = user, Revoke = true)
    - fabric-ca-client enroll -u http://admin:adminpw@localhost:7054
    - fabric-ca-client register --id.name userABC --id.type user --id.affiliation org1.department1 --id.secret passwd --id.attrs '"hf.Registrar.Roles=user",hf.Revoker=true'

10. Fabric-ca-server 구동 시 오류 확인 및 해결
    - Error: Incorrect format in file '/etc/fabric-ca-server/fabric-ca-server-config.yaml': 1 error(s) decoding:
    * 'Registry.Identities': source data must be an array or slice, got map
    - fabric-ca-server-config.yaml > registry > identities 에 name 주석처리 해제함

11. Fabric-ca-server에 HSM 설정
    - fabric-ca-server-config.yaml > bccsp에 HSM 정보 추가
    - __재기동을 해야하는데, 계속 오류가 발생함;; (확인 필요)__
        - FABRIC_CA_SERVER_BCCSP_DEFAULT=PKCS11
        - FABRIC_CA_SERVER_BCCSP_PKCS11_LIBRARY=/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so
        - FABRIC_CA_SERVER_BCCSP_PKCS11_PIN=93845132
        - FABRIC_CA_SERVER_BCCSP_PKCS11_LABEL=FabricToken

12. 체인코드 Instantiate 과정에서 발생항 오류 확인하고 이를 해결
    - 체인코드 install이 선행되지 않아서 발생하는 오류였음
