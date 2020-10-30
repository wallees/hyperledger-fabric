# Using Private Data in Fabric

본 문서에서는 BYFN(Build Your First Network)에서 [marbles private data samples](https://github.com/hyperledger/fabric-samples/tree/master/chaincode/marbles02_private)를 사용한다.

소스 코드로 직접 확인하고자 하면 [이곳](#start-the-network)으로 이동한다,.

<br>

## Build a collection definition JSON file

collections_config.json
~~~ json
[
 {
   "name": "collectionMarbles",
   "policy": "OR('Org1MSP.member', 'Org2MSP.member')",
   "requiredPeerCount": 0,
   "maxPeerCount": 3,
   "blockToLive":1000000,
   "memberOnlyRead": true
},
 {
   "name": "collectionMarblePrivateDetails",
   "policy": "OR('Org1MSP.member')",
   "requiredPeerCount": 0,
   "maxPeerCount": 3,
   "blockToLive":3,
   "memberOnlyRead": true
 }
]
~~~
- name: private data collection의 이름
- policy: collection 별 정책(하나의 체인코드는 다수의 collection 화 가능)
- requiredPeerCount: private data 배포에 필요한 피어 수
- maxPeerCount: 데이터의 redundancy를 위해, 현재 endorsing 피어가 데이터를 배포하고자 하는 최대 피어 갯수.
  - For data redundancy purposes, the number of other peers that the current endorsing peer will attempt to distribute the data to
- blockToLive: private data가 private database에 존재할 수 있는 기간을 지정된 블록 갯수로 표현한 값.   
  - To keep private data indefinitely, set the blockToLive property to 0.
- memberOnlyRead: true로 하면, collection member org에 포함된 클라이언트만 데이터 조회가 가능하게 적용.

<br>

## Read and Write private data using chaincode APIs

[marbles_chaincode_private.go](https://github.com/hyperledger/fabric-samples/blob/master/chaincode/marbles02_private/go/marbles_chaincode_private.go) 를 사용한다.

~~~ go
type marble struct {
	ObjectType string `json:"docType"` 
	Name       string `json:"name"`    
	Color      string `json:"color"`
	Size       int    `json:"size"`
	Owner      string `json:"owner"`
}

type marblePrivateDetails struct {
	ObjectType string `json:"docType"` 
	Name       string `json:"name"`   
	Price      int    `json:"price"`
}
~~~

위의 collection_config.json의 내용에 따르면 다음과 같다.
- name, color, size, owner: 채널의 org1, org2에서 확인 가능
- price: org1에서만 확인 가능

collection 정의를 통해 구성된 private data는 **GetPrivateData()** 또는 **PutPrivateData()** 를 사용하여 접근제어 할 수 있다.

<br>

### Reading collection data

~~~ go
// readMarble
// read a marble from chaincode state
func (t *SimpleChaincode) readMarble(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	...
    name = args[0]
    //get the marble from chaincode state
	valAsbytes, err := stub.GetPrivateData("collectionMarbles", name) 
	...
	return shim.Success(valAsbytes)
}

// readMarblereadMarblePrivateDetails
// read a marble private details from chaincode state
func (t *SimpleChaincode) readMarblePrivateDetails(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	...
    name = args[0]
    //get the marble private details from chaincode state
	valAsbytes, err := stub.GetPrivateData("collectionMarblePrivateDetails", name) 
	...
	return shim.Success(valAsbytes)
}
~~~

GetPrivateData() 함수를 사용하며, collection의 이름과 데이터 키 값을 파라미터로 받는다.  
- readMarble: 파라미터(collectionMarbles) -> org1, org2에서 조회 가능한 name, color, size, owner 반환
- readMarblePrivateDetails: 파라미터(collectionMarblePrivateDetails) -> org1에서만 조회 가능한 price 반환

<br>

### Writing private data

~~~ go
func (t *SimpleChaincode) initMarble(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	...
    // ==== Create marble object, marshal to JSON, and save to state ====
	marble := &marble{
		ObjectType: "marble",
		Name:       marbleInput.Name,
		Color:      marbleInput.Color,
		Size:       marbleInput.Size,
		Owner:      marbleInput.Owner,
	}
	marbleJSONasBytes, err := json.Marshal(marble)
	...
	// === Save marble to state ===
	err = stub.PutPrivateData("collectionMarbles", marbleInput.Name, marbleJSONasBytes)
	...

	// ==== Create marble private details object with price, marshal to JSON, and save to state ====
	marblePrivateDetails := &marblePrivateDetails{
		ObjectType: "marblePrivateDetails",
		Name:       marbleInput.Name,
		Price:      marbleInput.Price,
	}
	marblePrivateDetailsBytes, err := json.Marshal(marblePrivateDetails)
	...
	err = stub.PutPrivateData("collectionMarblePrivateDetails", marbleInput.Name, marblePrivateDetailsBytes)
    ...
}
~~~

PutPrivateData() 함수를 사용하며, collection의 이름과 데이터 키 값, 바이트 형태의 데이터 값이 들어간다.  
org1, org2는 name, color, size, owner 값을 저장하고 이를 사용할 수 있지만, price 항목은 org1에서만 저장하고 이를 사용할 수 있다.

<br>

## Start the network

1. BYFN(Build Your First Network)에서 네트워크를 구성한다.  
    ~~~bash
    ./byfn.sh up
    ~~~
2. cli 컨테이너로 접속한다.
    ~~~bash
    docker exec -it cli bash
    ~~~

<br>

## Install and instantiate chaincode with a collection

모든 피어에 marbles 체인코드를 설치한다.
    
~~~bash
# peer0.org1.example.com
peer chaincode install -n marblesp -v 1.0 -p github.com/chaincode/marbles02_private/go/

# peer1.org1.example.com
export CORE_PEER_ADDRESS=peer1.org1.example.com:8051
peer chaincode install -n marblesp -v 1.0 -p github.com/chaincode/marbles02_private/go/

# peer0.org2.example.com
export CORE_PEER_LOCALMSPID=Org2MSP
export PEER0_ORG2_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:9051
peer chaincode install -n marblesp -v 1.0 -p github.com/chaincode/marbles02_private/go/

# peer1.org2.example.com
export CORE_PEER_ADDRESS=peer1.org2.example.com:10051
peer chaincode install -n marblesp -v 1.0 -p github.com/chaincode/marbles02_private/go/
~~~

<br>

## Instantiate the chaincode on the channel

collection_config.json을 포함하고 체인코드를 인스턴스화 한다.

~~~bash
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile $ORDERER_CA -C mychannel -n marblesp -v 1.0 -c '{"Args":["init"]}' -P "OR('Org1MSP.member','Org2MSP.member')" --collections-config $GOPATH/src/github.com/chaincode/marbles02_private/collections_config.json
~~~
 
<br>

## Store private data

org1에서 private data를 저장해본다.

~~~bash
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export PEER0_ORG1_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

export MARBLE=$(echo -n "{\"name\":\"marble1\",\"color\":\"blue\",\"size\":35,\"owner\":\"tom\",\"price\":99}" | base64 | tr -d \\n)

peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n marblesp -c '{"Args":["initMarble"]}'  --transient "{\"marble\":\"$MARBLE\"}"
~~~

[marbles_chaincode_private.go](https://github.com/hyperledger/fabric-samples/blob/master/chaincode/marbles02_private/go/marbles_chaincode_private.go)의 initMarble 함수를 호출하게 되는데, initMarble 안에서 PutPrivateData()로 데이터를 분기하여 저장한다.

<br>

## Query the private data as an authorized peer

org1에서 collectionMarbles에 해당하는 값을 쿼리해본다.

~~~bash
peer chaincode query -C mychannel -n marblesp -c '{"Args":["readMarble","marble1"]}'
~~~
- 결과: {"docType":"marble","name":"marble1","color":"blue","size":35,"owner":"tom"}

org1에서 collectionMarblePrivateDetails에 해당하는 값을 쿼리해본다.

~~~bash
peer chaincode query -C mychannel -n marblesp -c '{"Args":["readMarblePrivateDetails","marble1"]}'
~~~
- 결과: {"docType":"marblePrivateDetails","name":"marble1","price":99}

<br>

## Query the private data as an unauthorized peer

org2에서 collectionMarbles에 해당하는 값을 쿼리해본다.

~~~bash
export CORE_PEER_LOCALMSPID=Org2MSP
export PEER0_ORG2_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp

peer chaincode query -C mychannel -n marblesp -c '{"Args":["readMarble","marble1"]}'
~~~
- 결과: {"docType":"marble","name":"marble1","color":"blue","size":35,"owner":"tom"}

org2에서 collectionMarblePrivateDetails에 해당하는 값을 쿼리해본다.

~~~bash
peer chaincode query -C mychannel -n marblesp -c '{"Args":["readMarblePrivateDetails","marble1"]}'
~~~
- 결과: Error: endorsement failure during query. response: status:500 message:"{\"Error\":\"Failed to get private details for marble1: GET_STATE failed: transaction ID: d9d7de5555069f64ad4bef4dfe140e1f275523234914b298fe81aa229e30f6b7: tx creator does not have read access permission on privatedata in chaincodeName:marblesp collectionName: collectionMarblePrivateDetails\"}"

동작하지 않음을 볼 수 있다.

<br>

## Purge Private Data

collection 정의 과정에서 blockToLive 값으로 데이터의 수명 주기를 결정할 수 있다.  
위의 collection_config.json의 collectionMarblePrivateDetails에서 **"blockToLive":3** 이 의미하는 내용은 3개의 블록이 추가로 쌓일 때 까지 side database에 값이 존재하며, 그 이후에 제거된다는 것을 말한다.  
그러므로 initMarble이 처음 실행되는 instantiate 과정 이후 3번의 invoke 과정이 진행되면, instantiate 과정에 등록된 price 값은 더이상 확인이 불가능할 것이다.

