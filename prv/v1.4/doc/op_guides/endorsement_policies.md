# Endorsement policies

체인코드의 유효성을 판단하기 위해 **채널에서 체인코드의 실행 결과를 승인해주는 피어를 지정하는 것**을 말하며, 일반적으로 승인하는 주체를 org 단위로 지정한다.

트랜잭션의 유효성을 검사하는(validate) 단계에서, 유효성 검사 피어들은 트랜잭션에 적절한 수의 보증(endorsement)이 포함되어 있는지, 예상된 소스에서부터 온 내용인지, 유효한 인증서의 서명이 담겨있는지 등을 확인한다. 

<br>

## Two ways to require endorsement

endorsement policy(보증 정책)은 상태 기반(state-based)으로 동작한다.  
일반적으로 체인코드의 인스턴스화(instantiate) 또는 업그레이드(upgrade) 과정에서 지정되지만, 특정 key-value 마다 보증 정책을 다르게 적용하기도 한다.

chaincode-level과 key-level 방법이 있다.

<br>

## Setting chaincode-level endorsement policies

```bash
peer chaincode instantiate -C mychannel -n mycc -P "AND('Org1.member', 'Org2.member')"
```
- 채널 'mychannel'에서 "AND('Org1.member', 'Org2.member')" 정책을 사용하여 채인코드 'mycc'를 배포한다.
- 이 과정에서 org1, org2가 트랜잭션에 서명해야 체인코드의 배포가 정상적으로 완료된다.

```bash
peer chaincode instantiate -C <channelid> -n mycc -P "AND('Org1.peer', 'Org2.peer')"
```
- 위와 비슷하지만, 승인 과정을 PEER로만 제한하여 체인코드를 배포한다. 

체인코드 인스턴스화 이후에 새로운 org가 추가되면, 채널 정책에 문제가 없는 한 체인코드를 쿼리(query)하는 것은 일반적으로 가능하나 블록의 생성에 관여하는 작업인 체인코드 실행(invoke) 또는 보증 과정은 진행할 수 없다. 그러므로 org 변경에 따른 체인코드의 인스턴스화(대부분 업그레이드)를 추가로 진행해주어야 한다.

> 별도의 보증정책을 부여하지 않으면(-P 옵션을 사용하지 않고 체인코드를 배포한다면), “OR('모든 org의 member')"가 기본 정책으로 부여된다. 

<br>

### Endorsement policy syntax

역할의 주체(principal)는 **'{MSP ID}.{role}'** 형식으로 표현한다.
- 'Org0.admin': any administrator of the Org0 MSP
- 'Org1.member': any member of the Org1 MSP
- 'Org1.client': any client of the Org1 MSP
- 'Org1.peer': any peer of the Org1 MSP

실제 보증 정책은 위의 주체를 포함한 **EXPR(E[, E...])** 형태가 되며, 여기서 EXPR은 AND, OR, OutOf 중 하나가 된다.
- AND('Org1.member', 'Org2.member', 'Org3.member'): org1, org2, org3 모두의 승인 필요
- OR('Org1.member', 'Org2.member'): org1, org2 중 적어도 1개
- OR('Org1.member', AND('Org2.member', 'Org3.member')): org2와 org3 모두의 승인 또는 org1의 승인 중 적어도 1개
- OutOf(1, 'Org1.member', 'Org2.member'): OR('Org1.member', 'Org2.member')과 같은 의미
- OutOf(2, 'Org1.member', 'Org2.member'): AND('Org1.member', 'Org2.member')과 같은 의미
- OutOf(2, 'Org1.member', 'Org2.member', 'Org3.member'): OR(AND('Org1.member', 'Org2.member'), AND('Org1.member', 'Org3.member'), AND('Org2.member', 'Org3.member'))과 같은 의미

<br>

## Setting key-level endorsement policies

chaincode-level에서의 보증 정책이 체인코드의 인스턴스화 또는 업그레이드 과정에서만 부여할 수 있다는 점과 다르게, key-level에서의 보증 정책은 체인코드 내에서 읽기/쓰기 과정에 적용될 수 있다.
- SetStateValidationParameter(key string, ep []byte) error
- GetStateValidationParameter(key string) ([]byte, error)

private data에 대한 체인코드의 경우 다음을 사용한다.
- SetPrivateDataValidationParameter(collection, key string, ep []byte) error
- GetPrivateDataValidationParameter(collection, key string) ([]byte, error)

```go
type KeyEndorsementPolicy interface {
    // Policy returns the endorsement policy as bytes
    Policy() ([]byte, error)

    // AddOrgs adds the specified orgs to the list of orgs that are required
    // to endorse
    AddOrgs(roleType RoleType, organizations ...string) error

    // DelOrgs delete the specified channel orgs from the existing key-level endorsement
    // policy for this KVS key. If any org is not present, an error will be returned.
    DelOrgs(organizations ...string) error

    // ListOrgs returns an array of channel orgs that are required to endorse changes
    ListOrgs() ([]string)
}
```
위와 같이 Go의 Shim 라이브러리에는 체인코드 개발자가 MSP에 대한 보증정책을 편리하게 적용할 수 있는 기능이 포함되어 있다. 예를 들어, 보증 정책에 특정 org를 추가하고자 하면 해당 org의 MSP ID를 AddOrgs()에 전달하고 Policy() 함수를 호출하여 이를 바이트 배열 형태로 구성하여 이를 SetStateValidationParameter() 함수로 전달한다.

<br>

## Validation

| Validation | no validation parameter set | validation parameter set |
| :--: | :-------: |  :-------: |
| modify value | check chaincode ep | check key-level ep |
| modify key-level ep | check chaincode ep | check key-level ep |
- ep: endorsement policy(보증 정책)
- 자세한 내용은 [하이퍼레저 패브릭 문서 - endorsement policy / validation](https://hyperledger-fabric.readthedocs.io/en/release-1.4/endorsement-policies.html#validation) 을 참조한다.
