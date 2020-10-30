# Kafka-Zookeeper 기반의 오더링 서비스 적용하기
> Kafka-Zookeeper 기반으로 BYFN 환경을 구성한다.

> 하이퍼레저 공식 문서 : [hyperledger-fabric.readthedocs.io](https://hyperledger-fabric.readthedocs.io/en/release-1.4/kafka.html#bringing-up-a-kafka-based-ordering-service)

<br/>

## 구성 환경
- Fabric Version : 1.4.1
- Org
    - org1 : peer0, peer1
    - org2 : peer0, peer1
- Orderer: 3개
- Kafka: 4개
- zookeeper: 3개

<br/>

## 설정 파일 변경

### crypto-config.yaml 
```
OrdererOrgs:
    ...

    Specs:
      - Hostname: orderer
      - Hostname: orderer1  (추가)
      - Hostname: orderer2  (추가)    

    ...
```
<br/>

### configtx.yaml

```
Orderer: &OrdererDefaults

    # Orderer Type: The orderer implementation to start
    # Available types are "solo" and "kafka"
    #OrdererType: solo  (주석 처리)
    OrdererType: kafka  (변경)

    ...
```
- OrdererType을 변경한다.

```
Orderer: &OrdererDefaults
    ...

    Addresses:
        - orderer.example.com:7050
        - orderer1.example.com:7050 (추가)
        - orderer2.example.com:7050 (추가)
        # 하나의 VM에서 돌아가기 때문에, Docker 컨테이너 내부와 통신하는 포트가 일정합니다. 
        # 포트는 모두 7050으로 설정해줍니다.
        # 만약 각 오더러를 서로 다른 VM에서 돌아가게 한다면, 포트 번호를 다르게 해야 합니다.

    ...
```
- Orderer 2개를 추가한다.

```
Orderer: &OrdererDefaults
    ...

    Kafka:
        # Brokers: A list of Kafka brokers to which the orderer connects
        # NOTE: Use IP:port notation
        Brokers:
            # - 127.0.0.1:9092          (주석 처리)
            - kafka.example.com:9092    (추가)
            - kafka1.example.com:9092   (추가)
            - kafka2.example.com:9092   (추가)
            - kafka3.example.com:9092   (추가)
    
    ...
```
- Kafka 브로커(Broker)를 추가한다.

<br/>

### base/kafka-base.yaml 파일 생성
```
version: '2'

services:
  kafka-base:
    image: hyperledger/fabric-kafka:$IMAGE_TAG
    restart: always
    environment:         
      - KAFKA_MESSAGE_MAX_BYTES=103809024 # 99 * 1024 * 1024 B      
      - KAFKA_REPLICA_FETCH_MAX_BYTES=103809024 # 99 * 1024 * 1024 B     
      - KAFKA_UNCLEAN_LEADER_ELECTION_ENABLE=false
      - KAFKA_MIN_INSYNC_REPLICAS=2
      - KAFKA_DEFAULT_REPLICATION_FACTOR=3      
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper.example.com:2181,zookeeper1.example.com:2181,zookeeper2.example.com:2181
    networks: 
      - byfn
```
- KAFKA_ZOOKEEPER_CONNECT에 각 Kafka마다 연결할 Zookeeper를 등록한다.

<br/>

### base/zookeeper-base.yaml 파일 생성
```
version: '2'

services:
  zookeeper-base:
    image: hyperledger/fabric-zookeeper:$IMAGE_TAG
    environment:
      - ZOO_SERVERS=server.1=zookeeper0.example.com:2888:3888 server.2=zookeeper1.example.com:2888:3888 server.3=zookeeper2.example.com:2888:3888 
        # ZOO_SERVERS에 각 zookeeper 컨테이너 이름과 포트번호를 등록 (중요)

    restart: always
    networks:
      - byfn
```

<br/>

### base/docker-compose-base.yaml 파일 수정
```
version: '2'

services:

  orderer.example.com:
    ...
    ports:
      - 7050:7050

  # Orderer1 추가  
  orderer1.example.com:
    container_name: orderer1.example.com
    extends:
      file: orderer-base.yaml
      service: orderer-base
    volumes:
        - ../channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
        - ../crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/msp:/var/hyperledger/orderer/msp
        - ../crypto-config/ordererOrganizations/example.com/orderers/orderer1.example.com/tls/:/var/hyperledger/orderer/tls
        - orderer1.example.com:/var/hyperledger/production/orderer
    ports:
      - 8050:7050 
        # 포트는 8050:7050으로 하지만, 실제 Docker 컨테이너 통신에는 7050으로 진행

  # Orderer2 추가  
  orderer2.example.com:
    container_name: orderer2.example.com
    extends:
      file: orderer-base.yaml
      service: orderer-base
    volumes:
        - ../channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
        - ../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp:/var/hyperledger/orderer/msp
        - ../crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/:/var/hyperledger/orderer/tls
        - orderer2.example.com:/var/hyperledger/production/orderer
    ports:
      - 9050:7050
        # 포트는 9050:7050으로 하지만, 실제 Docker 컨테이너 통신에는 7050으로 진행

  ...   
```
- 오더러 2개를 추가한다.

```
  ...

  zookeeper.example.com:
    container_name: zookeeper.example.com
    extends:
      file: zookeeper-base.yaml
      service: zookeeper-base
    environment:
      - ZOO_MY_ID=1 
    ports:
      - 2181:2181
      - 2888:2888
      - 3888:3888

  zookeeper1.example.com:
    container_name: zookeeper1.example.com
    extends:
      file: zookeeper-base.yaml
      service: zookeeper-base
    environment:
      - ZOO_MY_ID=2
    ports:
      - 12181:2181
      - 12888:2888
      - 13888:3888

  zookeeper2.example.com:
    container_name: zookeeper2.example.com
    extends:
      file: zookeeper-base.yaml
      service: zookeeper-base
    environment:
      - ZOO_MY_ID=3
    ports:
      - 22181:2181
      - 22888:2888
      - 23888:3888

  ...    
```
- Zookeeper 3개를 추가한다.

```
  ...

  kafka.example.com:
    container_name: kafka.example.com
    extends:
      file: kafka-base.yaml
      service: kafka-base
    environment:
      - KAFKA_BROKER_ID=0
    ports:
      - 9092:9092
      - 9093:9093

  kafka1.example.com:
    container_name: kafka1.example.com
    extends:
      file: kafka-base.yaml
      service: kafka-base
    environment:
      - KAFKA_BROKER_ID=1
    ports:
      - 10092:9092
      - 10093:9093

  kafka2.example.com:
    container_name: kafka.example.com
    extends:
      file: kafka-base.yaml
      service: kafka-base
    environment:
      - KAFKA_BROKER_ID=2
    ports:
      - 11092:9092
      - 11093:9093

  kafka3.example.com:
    container_name: kafka3.example.com
    extends:
      file: kafka-base.yaml
      service: kafka-base
    environment:
      - KAFKA_BROKER_ID=3
    ports:
      - 12092:9092
      - 12093:9093  

  ...    
```
- Kafka 4개를 추가한다.

<br/>

### docker-compose-kafka.yaml 파일 수정

> 기존에 있는 내용을 모두 지우고 새로 작성한다.

```
version: '2'

networks:
  byfn:

services:
  zookeeper.example.com:
    container_name: zookeeper.example.com
    extends:
      file: base/docker-compose-base.yaml
      service: zookeeper.example.com
    networks:
      - byfn

  zookeeper1.example.com:
    container_name: zookeeper1.example.com
    extends:
      file: base/docker-compose-base.yaml
      service: zookeeper1.example.com
    networks:
      - byfn

  zookeeper2.example.com:
    container_name: zookeeper2.example.com
    extends:
      file: base/docker-compose-base.yaml
      service: zookeeper2.example.com
    networks:
      - byfn  

  kafka.example.com:
    container_name: kafka.example.com
    extends:
      file: base/docker-compose-base.yaml
      service: kafka.example.com
    networks:
      - byfn
    depends_on:
      - zookeeper.example.com
      - zookeeper1.example.com
      - zookeeper2.example.com  

  kafka1.example.com:
    container_name: kafka1.example.com
    extends:
      file: base/docker-compose-base.yaml
      service: kafka1.example.com
    networks:
      - byfn
    depends_on:
      - zookeeper.example.com
      - zookeeper1.example.com
      - zookeeper2.example.com

  kafka2.example.com:
    container_name: kafka2.example.com
    extends:
      file: base/docker-compose-base.yaml
      service: kafka2.example.com
    networks:
      - byfn
    depends_on:
      - zookeeper.example.com
      - zookeeper1.example.com
      - zookeeper2.example.com

  kafka3.example.com:
    container_name: kafka3.example.com
    extends:
      file: base/docker-compose-base.yaml
      service: kafka3.example.com
    networks:
      - byfn
    depends_on:
      - zookeeper.example.com
      - zookeeper1.example.com
      - zookeeper2.example.com  

  ...
```

<br/>

### docker-compose-cli.yaml 파일 수정
```
version: '2'

volumes:
  orderer.example.com:
  # Orderer 2개 추가  
  orderer1.example.com: 
  orderer2.example.com:     
  ...

networks:
  byfn:

services:
  ...
  # Orderer1 추가 (Kafka 설정)
  orderer1.example.com:
    extends:
      file:   base/docker-compose-base.yaml
      service: orderer1.example.com
    container_name: orderer1.example.com
    depends_on:
      - kafka.example.com
      - kafka1.example.com
      - kafka2.example.com
      - kafka3.example.com
    networks:
      - byfn    
  
  # Orderer2 추가 (Kafka 설정)
  orderer2.example.com:
    extends:
      file:   base/docker-compose-base.yaml
      service: orderer2.example.com
    container_name: orderer2.example.com
    depends_on:
      - kafka.example.com
      - kafka1.example.com
      - kafka2.example.com
      - kafka3.example.com
    networks:
      - byfn    
  ...
  cli:
    container_name: cli
    image: hyperledger/fabric-tools:$IMAGE_TAG
    ...
    depends_on:
      - orderer.example.com
      # Orderer 2개 추가
      - orderer1.example.com
      - orderer2.example.com
      ...
    networks:
      - byfn
  ...
```
- 오더러 2개에 대한 내용을 빠짐없이 추가해준다.

<br/>

## 실행
```
$ ./byfn.sh -m up -o kafka 
```
> 만약 실행이 되지 않을 경우 => ./byfn.sh -m up -o kafka -t 30 -d 10 

