# Gateway

> [hyperledger-fabric-docs](https://hyperledger-fabric.readthedocs.io/en/release-2.2/developapps/gateway.html?highlight=gateway#gateway)

A **gateway** manages the network interactions on behalf of an application, allowing it to focus on business logic. Applications connect to a gateway and then all subsequent interactions are managed using that gateway’s configuration.

> 어플리케이션에서 담당하던 네트워크 설정 값 관리를 대신 담당한다.
>
> - 변경이 빈번하게 발생하는 네트워크의 경우, 변경이 될 때마다 어플리케이션에서 orderer, peer, ca 등의 설정 값을 변경하는 것이 불편하다.
> - Gateway와 다수의 어플리케이션이 연결되어 있다면, 모든 어플리케이션을 수정할 필요 없이 gateway에서만 네트워크 값을 관리하면 된다.
> - [Connection profile](connection_profile.md), [connection option](connection_option.md) 값으로 관리된다.



#### Static 

- The gateway configuration is **completely defined** in a connection profile.
- 어플리케이션에서 사용하는 모든 피어, 오더러, CA의 내용들이 connection profile에 정적으로 정의된다.
- SDK의 경우 gateway connection option을 통해 트랜잭션에 대한 제출 및 알림 프로세스를 관리한다.

#### Dynamic

- The gateway configuration is **minimally defined** in a connection profile.
- 1-2개의 피어를 중심으로 Service discovery를 통해 사용 가능한 네트워크 토폴로지를 검색한다.
  - Production 환경에서는 가용성을 위해 gateway 내부에 2개 이상의 피어를 작성하도록 권장한다.

#### Consideration

- Predictability vs Responsiveness : 예측 가능성 vs 응답성
  - Static: 네트워크의 변동성이 없음, 예측 가능함
  - Dynamic: 네트워크의 변동성이 존재함, 확장성 제공, <u>일반적으로 많이 사용됨</u>



## Application(SDK)에서의 적용

#### Connect

```js
await gateway.connect(connectionProfile, connectionOptions);
```

- connectionProfile

  - SDK에서 트랜잭션 처리에 사용될 gateway의 구성 파일. 

  - YAML, JSON으로 작성할 수 있으나, gateway로 전달할 때에는 JSON 객체로 변환해야 한다.

    ```
    let connectionProfile = yaml.safeLoad(fs.readFileSync('../gateway/paperNet.yaml', 'utf8'));
    ```

- connectionOptions

  - 네트워크 구성 요소와의 상호 작용 패턴(연결할 ID 또는 event 알림에 사용할 피어 선택 등)을 제어하는 부분.

#### Static

- gateway.connect ( connectionProfile, **discovery: { enabled:false } **)
  - 환경변수 설정 FABRIC_SDK_DISCOVERY = false 으로도 가능하다.
- 변경 사항은 gateway 파일이 로드되는 시점에서만 적용된다.

#### Dynamic

- gateway.connect ( connectionProfile, **discovery: { enabled:true } **)
  - 환경변수 설정 FABRIC_SDK_DISCOVERY = true 로도 가능하다.
- Service discovery가 변경 사항을 지속적으로 확인하므로, gateway 파일을 다시 로드할 필요없다.

#### Multiple gateways

- 다수의 user로부터 오는 요청 처리에 유용함
- 다수의 네트워크로 연결해야 하는 상황에 유용함
  - 다수의 네트워크 간 구성 방식의 차이에 따른 테스트를 진행해야 할 경우 유용함





