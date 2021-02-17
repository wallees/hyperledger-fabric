# Configuring and operating a Raft ordering service

## Configuration

모든 Raft 노드를 시스템 채널에 추가해야 하지만, 응용프로그램 채널에는 모두 추가할 필요 없다.  
기존에 돌아가는 네트워크에서 다른 노드에 영향을 주지 않고도 노드를 동적으로 재구성(채널에서 추가 또는 삭제)할 수 있다.  
TLS 통신이 기본적으로 필요하다.  
Raft 클러스터는 두 가지로 구성된다.
  - Local configuration: TLS 통신, 복제, 파일 스토리지
  - Channel configuration: 해당 채널에 대한 raft 클러스터의 멤버 자격, 하트비트 주기, 리더 타임아웃 등  


configtx.yaml 파일에서 raft로 구성된 3개의 노드(consenter)는 다음과 같이 구성된다.
```yaml
       Consenters:
            - Host: raft0.example.com
              Port: 7050
              ClientTLSCert: path/to/ClientTLSCert0
              ServerTLSCert: path/to/ServerTLSCert0
            - Host: raft1.example.com
              Port: 7050
              ClientTLSCert: path/to/ClientTLSCert1
              ServerTLSCert: path/to/ServerTLSCert1
            - Host: raft2.example.com
              Port: 7050
              ClientTLSCert: path/to/ClientTLSCert2
              ServerTLSCert: path/to/ServerTLSCert2
```


### Local configuration

orderer.yaml 파일에 raft와 관련하여 Cluster, Consensus 두가지 섹션이 존재한다.
- Cluster: TLS 통신에 관여한다.
- Consensus: Write Ahead Logs와 Snapshots이 저장되는 위치를 지정한다.

각 파라미터에 대한 자세한 내용은 [하이퍼레저 패브릭 문서 - Local configuration](https://hyperledger-fabric.readthedocs.io/en/release-1.4/raft_configuration.html#local-configuration) 를 참조한다.

<br>

### Channel configuration

Raft가 이미 네트워크에서 동작하고 있는 경우, 동적으로 채널과 관련된 값을 변경할 수는 없으며 정지 후 재시작해야 한다.  
단, SnapshotIntervalSize(스냅샷 생성 바이트 수) 값은 동적으로 변경 가능하다.  
여기에 해당하는 값들은 매우 미세한 변화에도 민감하게 동작하므로, 별도의 지식이 없이 변경하는 것을 권장하지 않고 있다. 

각 파라미터에 대한 자세한 내용은 [하이퍼레저 패브릭 문서 - Channel configuration](https://hyperledger-fabric.readthedocs.io/en/release-1.4/raft_configuration.html#channel-configuration) 를 참조한다.

<br>

## Reconfiguration

Raft에서 오더러는 한번에 하나의 노드씩만 동적으로 추가 또는 삭제할 수 있는 기능을 지원한다. 클러스터는 Raft의 Quorum 법칙에 의거하여 노드가 재구성되어야 한다.  
예를 들어 3개의 노드가 있고 2개의 노드가 실패하면 해당 노드를 제거하도록 클러스터를 재구성 할 수 없다(Raft에서 오더러는 2n+1개, 홀수이어야 함).  

또한 특정 노드가 중지된 상태에서 남아있는 노드만 가지고 클러스터 구성을 시도하게 되면 문제가 발생할 확률이 매우 높다.  
예를 들어 consenter에 3개의 노드가 있고 그 중에서 1개가 작동 중지된 상태에서 클러스터를 4개로 확장하게 되면, 노드가 작동 중인 클러스터에만 Raft가 탑재(onboard)될 수 있기 때문에 새로운 노드가 추가되지 않게 되며 이는 quorum을 만족하지 못하므로 4개중 2개의 노드만 활성상태가 된다. 

따라서 위의 경우에는 오프라인(중지)된 노드가 다시 동작할 때까지 노드는 'effectively stuck'된 상태가 된다.

<br>

### Adding a new node to a Raft cluster

Raft에서 새로운 노드를 추가하는 과정은 다음의 순서로 진행된다.
1. 채널에 새로운 노드의 TLS 인증서 추가
2. 오더러 노드에서 최신의 config block 가져오기
3. 가져온 블록에 새로운 노드의 인증서가 포함되어 있는지 확인
4. 새로운 Raft 노드 시작
5. Raft 노드가 추가된 채널에서 블록이 복제
6. 새로 추가된 노드의 endpoint를 채널 구성에 추가

기본적으로 5분 마다 자동으로 노드가 새로운 채널에 추가되었음을 감지하지만, 재부팅해서 빠르게 적용할 수도 있다.

<br>

### Removing a node from a Raft cluster

Raft에서 특정 노드를 제거하는 과정은 다음의 순서로 진행된다.
1. 해당 노드의 endpoint 제거
2. 해당 노드의 항목(인증서를 포함한) 제거
3. 만약 다른 채널에서도 해당 노드를 사용하고 있지 않다면 노드 종료

<br>

### TLS certificate rotation for an orderer node

모든 TLS 인증서에는 발급자가 결정한 만료 날짜가 있기 때문에, 만료일 이전에 인증서를 교체해야한다.  
과정은 간단한데, 새로운 인증서를 발급받고, 노드의 인증서를 교체한 후 재시작하면 된다.  

