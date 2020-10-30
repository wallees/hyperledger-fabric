# Updating a Channel Configuration

채널에 속한 org가 누구인지, 채널 access 정책 또는 블록 배치사이즈 등 채널에 대한 모든 구성 정보를 말한다.  
**이 정보들은 원장에 블록(config 블록이라고 말함) 형태로 저장** 되기 떄문에, 첫번쨰로 만들어진 블록인 'genesis block'에는 채널의 부트스트랩에 필요한 초기 구성 내용이 들어있고 가장 최근에 만들어진 블록에는 가장 최신의 채널 구성 정보가 들어있게 된다. 

그렇기 때문에 구성 업데이트 과정은 일반적인 트랜잭션과 다르게 동작하며, 블록을 읽기 쉬운(human can read) 형태로 변경하고 이를 이용하여 값을 수정한 후에 다시 블록 형태로 변경시키는 작업을 진행한다.

<br>

> 소스를 직접 확인하고자 하면 [이곳](#source)을 참조한다.
 
<br>

## Editing a Config


변경 가능한 채널 구성 요소 값들은 다음과 같다.

- Batch Size: 블록의 트랜잭션 수 또는 크기
    ```json
    {
        "absolute_max_bytes": 102760448,    
        "max_message_count": 10,            
        "preferred_max_bytes": 524288       
    }
    ```
    - absolute_max_bytes: 블록의 최대 크기
    - max_message_count: 블록 내 최대 트랜잭션 수
    - preferred_max_bytes: 적정 블록 크기, 이보다 크면 블록을 나누어 저장

- Batch Timeout: 블록 생성 주기. 트랜잭션 저장 이후에 다음 트랜잭션을 기다리는 시간
    ```json
    { "timeout": "2s" }     # 너무 빠르면 블록이 자주 생성됨, 블록이 낭비되고 처리량은 감소함
    ```
- Channel Restrictions: 오더러에서 할당할 수 있는 총 채널 갯수
    ```json
    { "max_count":1000 }
    ```
- Channel Creation Policy: 새로운 채널의 응용프로그램 그룹 내에 정의된 mod_policy 값
    ```json
    {
        "type": 3,
        "value": {
            "rule": "ANY",
            "sub_policy": "Admins"
        }
    }
    ```
    - 오더러 시스템 채널에서만 설정 가능
- Kafka brokers: Kafka 환경에서의 broker 목록
    ```json
    {
        "brokers": [
            "kafka0:9092",
            "kafka1:9092",
            "kafka2:9092",
            "kafka3:9092"
        ]
    }
    ```
    - **Genesis 블록이 생성된 이후, 컨센서스(solo, kafka, raft)의 변경은 불가능하다.**
- Anchor Peers Definition: 각 org의 앵커피어 위치
    ```json
    {
        "host": "peer0.org2.example.com",
        "port": 9051
    }
    ```
- Hashing Structure: 블록 데이터의 해시값(머클 트리) 크기
    ```json
    { "width": 4294967295 } # 일반적으로 이 값은 고정되어 있음
    ```
- Hashing Algorithm: 블록으로 인코딩 된 해시 값 계산에 사용되는 알고리즘
    ```json
    { "name": "SHA256" }    # SHA256에서 변경 불가능
    ```
- Block Validation: 블록 유효성 검증 과정에 필요한 요구사항
    ```json
    {
        "type": 3,
        "value": { 
            "rule": "ANY",
            "sub_policy": "Writers"
        }
    }
    ```
- Orderer Address: 오더러의 주소 목록
    ```json
    {
        "addresses": [
            "orderer.example.com:7050"
        ]
    }
    ```
