# Hyperledger Fabric

> 하이퍼레저 패브릭에 대한 내용을 적어두는 리포지토리

<br>

# 구성

| 이름 | 설명 | 
|:--- |:-------- |
| [src](#src) | 하이퍼레저 패브릭 테스트 소스코드 및 내용 정리 |
| [doc](#doc) | Hyperledger Fabric doc 내용 번역 또는 개인 정리 |
| [tip](#tip) | 하이퍼레저 패브릭 외에 관련된 내용 정리 |

<br>
<br>
<br>
<br>

# src

|| 프로젝트 | 구성 | 버전 | 
| :--: |:------- | :---- | :---- | 
| 1 | [Raft 기반의 시스템 구축하기]() | Orderer(3), Org(4), Peer(5) | v1.4 |  

<br>
<br>


# doc 

#### Key Concepts
|| 주제 |
|:--: |:------- | :---- | 
| 1 | [The Ordering Service - Raft](/doc/key_concept/raft.md) |

#### Tutorials
|| 주제 |
|:--: |:------- | :---- | 
| 1 | [Build Your First Network](/doc/tutorials/build_your_first_network.md) |
| 2 | [Adding an Org to a Channel](/doc/tutorials/add_org_to_channel.md) | 


#### Operation Guides
|| 주제 |
|:--: |:------- | :---- | 
| 1 | [Updating ACL defaults in the channel config](/doc/op_guides/update_acl.md) | Operations Guides |
| 2 | [Updating a Channel Configuration](/doc/op_guides/update_channel_configuration.md) | Operations Guides |
| 3 | [Bringing up a Kafka-based Ordering Service](/doc/op_guides/kafka_service.md) | Operations Guides |
| 4 | [Configuring and operating a Raft ordering service](/doc/op_guides/raft_service.md) | Operations Guides |


<br>
<br>

# tip

|| 주제 | 작성일 |
| :--: |:------- | :---: |
| 1 | [하이퍼레저 네트워크에 생성된 블록 확인하기](/tip/block_physical_path.md) |2019.11.20|
| 2 | [log 레벨 변경하기](/tip/change_log_level.md) |2019.11.23| 
| 3 | [컨테이너에서 실행한 결과 파일에 작성하기](/tip/get_result_file_from_container.md) |2019.11.23|

<br>

