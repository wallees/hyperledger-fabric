# Access Control Lists (ACL)

하이퍼레저 패브릭은 ACL(액세스 제어 목록)을 사용하여 **특정 리소스에 접근할 수 있는 정책(일련의 ID에 대한 true/false 값)을 부여**한다. 
> Fabric uses access control lists (ACLs) to manage access to resources by associating a policy — which specifies a rule that evaluates to true or false, given a set of identities — with the resource.

<br>

### Resource

사용자 또는 시스템 체인코드, 이벤트 스트림 소스 등을 의미한다.  
configtx.yaml ([샘플](https://github.com/hyperledger/fabric/blob/release-1.2/sampleconfig/configtx.yaml)) 파일에 작성되며, component/resource 형태로 구성되는데 예를 들어 cscc/GetConfigBlock는 cscc 구성요소의 GetConfigBlock를 호출하기 위한 리소스를 말한다.

<br>

### Policies

어떠한 요청을 이행하는데 필요한 자원과 요청에 대한 ID(또는 ID 세트)를 연결해주는 방식을 의미한다.  
(쉽게 말해, 특정 자원을 사용하기 위해 요구되는 정책을 말한다.)

- Signature
  - 정책을 만족시키기 위한 사용자를 명시할 때 사용
  - AND, OR, NOutOf을 사용할 수 있다.
  - 예시) 정책 'MyPolicy'는 "Org1의 피어" 또는 "Org2의 피어"의 서명이 필요하다.
    ```yaml
    Policies:
        MyPolicy:
            Type: Signature
            Rule: “Org1.Peer OR Org2.Peer”    
    ```

- ImplicitMeta
  - 간단하고 포괄적인 표현으로 정책을 설정할 수 있다. 
  - <ALL | ANY | MAJORITY> <sub_policy> 방식으로 작성된다.
  - sub_policy: Admin, Writer, Reader가 있다.
    - Admin: 운영 역할을 가지며, 체인코드의 인스턴스화 같은 중요한 측면을 주로 담당한다.
    - Writer: 트랜잭션, 원장 업데이트 등을 주로 담당하며 관리 역할은 없다.
    - Reader: 정보에 엑세스 할 수는 있지만, 원장 업데이트나 관리 역할은 주어지지 않는다.
  - *NodeOU가 활성화 되어 있으면 피어 또는 클라이언트에 의해 변경될 수 있다.*
  - 예시) 정책 'AnotherPolicy'는 MAJORITY한 Admin들의 서명이 필요하다.
    ```yaml
    Policies:
        AnotherPolicy:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
    ```

<br>

## How ACLs are formatted in configtx.yaml

ACL은 configtx.yaml에서 key-value 형태로 작성된다.  
key는 자원을, value는 해당 자원의 정식 경로를 나타낸다.

```yaml
# ACL policy for invoking chaincodes on peer
peer/Propose: /Channel/Application/Writers
# ACL policy for sending block events
event/Block: /Channel/Application/Readers
```

<br>

### Updating ACL defaults in configtx.yaml

네트워크가 부트스트랩 되기 전 직접 configtx.yaml 파일을 수정하는 방법이다.

만약 peer/Propose에 대한 value를 /Channel/Application/Writers 에서 MyPolicy로 변경한다고 하자.  
먼저 MyPolicy 정책을 configtx.yaml의 Application.Policies에 추가한다.

```yaml
Policies: &ApplicationDefaultPolicies
    Readers:
        Type: ImplicitMeta
        Rule: "ANY Readers"
    Writers:
        Type: ImplicitMeta
        Rule: "ANY Writers"
    Admins:
        Type: ImplicitMeta
        Rule: "MAJORITY Admins"
    MyPolicy:
        Type: Signature
        Rule: "OR('SampleOrg.admin')"
```
- 여기서는 SampleOrg의 Admin의 서명을 필요로 하도록 작성한다.

이후, Application: ACLs 섹션에서 peer/Propose 값을 다음과 같이 변경한다.
- peer/Propose: /Channel/Application/MyPolicy

<br>

### Updating ACL defaults in the channel config

변경하고자 하는 ACL을 사용하는 채널이 이미 생성된 경우(일반적으로 네트워크가 이미 부트스트랩 된 이후), 블록에 구성된 ACL 요소를 하나씩 변경하는 방법이다. 

configtx.yaml에 작성되어 있는 다양한 Policy 중 하나로 변경한다.  
(즉, 먼저 configtx.yaml 파일에 사용하고자 하는 정책을 작성해놓아야 한다)

다음 [소스](/doc/op_guides/updating_acl_defaults_in_the_channel_config.md)에서는 MyPolicy라는 정책을 추가하고, 네트워크에 채널이 생성된 이후 peer/Propose 정책의 경로를 MyPolicy로 변경하는 작업을 진행한다.
