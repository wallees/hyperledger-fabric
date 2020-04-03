# Raft 기반의 시스템 구축하기 

> Raft 기반의 시스템을 멀티노드환경에서 구축하고, 이를 테스트해본다.

<br>

## 시스템 구성
| Orderer/Org | 갯수 | 피어 | 
|:--- |:---: | :------ |
| Orderer | 3 | orderer1.rm.com, orderer2.rm.com, orderer3.rm.com |
| AdminOrg | 2 | peer1.admorg.rm.com, peer2.admorg.rm.com |
| Org1 | 1 | peer1.org1.rm.com |
| Org2 | 1 | peer1.org2.rm.com |

<br>

## VM 구성
| VM | 컨테이너 | 
|:--- |:--- | 
| admnode1  | orderer1.rm.com, orderer2.rm.com, peer1.adminorg.rm.com |
| admnode2 | orderer3.rm.com, peer2.adminorg.rm.com |
| node1 | peer1.org1.rm.com |
| node2 | peer1.org2.rm.com |

<br>

## 채널 구성

| 채널 | 속성 | 
|:--- |:--- | 
| allch  | AdminOrg, Org1, Org2 |
| admch | AdminOrg |
| org12ch | Org1, Org2 |

<br>

