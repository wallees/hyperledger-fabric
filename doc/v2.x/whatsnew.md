# What’s new in Hyperledger Fabric v2.x

**v2.2 is the first long-term support (LTS) release of Fabric v2.x.** Fixes will be provided on the v2.2.x release stream until after the next LTS release is announced.

> v2.2부터 Hyperledger fabric v2.x가 LTS 버전으로 배포된다.



## Big change components

- [Fabric chaincode lifecycle](https://hyperledger-fabric.readthedocs.io/en/release-2.2/chaincode_lifecycle.html)
- [Private Data](https://hyperledger-fabric.readthedocs.io/en/release-2.2/private-data-arch.html)
- [External Builders and Launchers](https://hyperledger-fabric.readthedocs.io/en/release-2.2/cc_launcher.html)
- CouchDB peer cache
- [Test network](https://hyperledger-fabric.readthedocs.io/en/release-2.2/test_network.html)



## Decentralized governance for smart contracts

Fabric v2.0 introduces decentralized governance for smart contracts, with a **new process for installing a chaincode on your peers and starting it on a channel.** 

> 체인코드 설치에 새로운 방법(lifecycle)이 추가되었다.

The new Fabric chaincode lifecycle allows multiple organizations to come to agreement on the parameters of a chaincode, such as the chaincode endorsement policy.

- **Multiple organizations must agree to the parameters of a chaincode**

- **More deliberate chaincode upgrade process** : The new model allows for a chaincode to be upgraded only after a sufficient number of organizations have approved the upgrade.

- **Simpler endorsement policy and private data collection updates** : Fabric lifecycle allows you to change an endorsement policy or private data collection configuration without having to repackage or reinstall the chaincode. Users can also take advantage of a new default endorsement policy that requires endorsement from a majority of organizations on the channel. This policy is updated automatically when organizations are added or removed from the channel.

  > Endorsement policy 재설정에 체인코드 재설치까지 할 필요가 없어졌다. 기본값(MAJORITY of organizations)도 주어지고 org의 추가/삭제 시  automatically한 변경도 제공한다.

- **Inspectable chaincode packages** 

  >  Readable한(?) tar 형식의 체인코드 방식 제공

- **Start multiple chaincodes on a channel using one package** : Use a single chaincode package and deploy it multiple times with different names on the same channel or on different channels. For example, if you’d like to track different types of assets in their own ‘copy’ of the chaincode.

  > 하나의 패키지에 여러 체인코드를 묶어서 다양한 채널에 설치할 수 있다.

- **Chaincode packages do not need to be identical across channel members** : Organizations can extend a chaincode for their own use case, for example to perform different validations in the interest of their organization. <u>As long as the required number of organizations endorse chaincode transactions with matching results, the transaction will be validated and committed to the ledger</u>. This also allows organizations to individually roll out minor fixes on their own schedules without requiring the entire network to proceed in lock-step.

  > Org별로 체인코드를 각자 관리하고 검증할 수 있다는 말 같은데, 확인해보아야 할 것 같다.



## New chaincode application patterns for collaboration and consensus

The same decentralized methods of coming to agreement that underpin the new chaincode lifecycle management can also be used in your own chaincode applications to ensure organizations consent to data transactions before they are committed to the ledger.

- **Automated checks** : As mentioned above, <u>organizations can add automated checks to chaincode functions to validate additional information before endorsing a transaction proposal</u>.

- **Decentralized agreement** Human decisions can be modeled into a chaincode process that spans multiple transactions. <u>The chaincode may require actors from various organizations to indicate their terms and conditions of agreement in a ledger transaction</u>. Then, a final chaincode proposal can verify that the conditions from all the individual transactors are met, and “settle” the business transaction with finality across all channel members.

  > 체인코드의 제안에 관여하는 org 구성원들의 합의가 이루어진 이후에 proposal이 진행된다. 이전의 방법이 특정 org의 주도로 진행되었다면, 변경된 방식은 org 각각의 의사결정권을 존중하고 해당 영향력을 키운 것으로 보인다.



## Private data enhancements

<u>Private data, without the requirement of creating private data collections for all combinations of channel members that may want to transact</u>. Specifically, instead of sharing private data within a collection of multiple members, you may want to share private data across collections, where each collection may include a single organization, or perhaps a single organization along with a regulator or auditor.

- **Sharing and verifying private data** : When private data is shared with a channel member who is not a member of a collection, or shared with another private data collection that contains one or more channel members (by writing a key to that collection), the receiving parties can utilize the GetPrivateDataHash() chaincode API to verify that the private data matches the on-chain hashes that were created from private data in previous transactions.

  > 컬렉션으로 구성되지 않은 채널 구성원과 데이터를 공유할 수 있도록 GetPrivateDataHash 함수를 제공한다.

- **Collection-level endorsement policies** : <u>Private data collections can now optionally be defined with an endorsement policy that overrides the chaincode-level endorsement policy for keys within the collection</u>. This feature can be used to restrict which organizations can write data to a collection, and is what enables the new chaincode lifecycle and chaincode application patterns mentioned earlier. For example, you may have a chaincode endorsement policy that requires a majority of organizations to endorse, but for any given transaction, you may need two transacting organizations to individually endorse their agreement in their own private data collections.

  > 체인코드 level에서 private data의 보증 정책을 설정할 수 있다.

- **Implicit per-organization collections** : Implicit organization-specific collections can be used without any upfront definition.



## External chaincode launcher

The external chaincode launcher feature empowers operators to build and launch chaincode with the technology of their choice. Use of external builders and launchers is not required as the default behavior builds and runs chaincode in the same manner as prior releases using the Docker API.

> 도커를 활용한 체인코드 실행 프로그램을 별도로 활용할 수 있다.

- **Eliminate Docker daemon dependency** : Prior releases of Fabric required peers to have access to a Docker daemon in order to build and launch chaincode - something that may not be desirable in production environments due to the privileges required by the peer process.

- **Alternatives to containers** : <u>Chaincode is no longer required to be run in Docker containers</u>, and may be executed in the operator’s choice of environment (including containers).

  > 체인코드가 컨테이너 형식으로 실행되지 않는다. 

- **External builder executables** : An operator can provide a set of external builder executables to override how the peer builds and launches chaincode.

- **Chaincode as an external service** : Traditionally, chaincodes are launched by the peer, and then connect back to the peer. It is now possible to run chaincode as an external service, for example in a Kubernetes pod, which a peer can connect to and utilize for chaincode execution. See [Chaincode as an external service](https://hyperledger-fabric.readthedocs.io/en/release-2.2/cc_service.html) for more information.

  > 컨테이너에 종속되지 않음으로써, k8s와 같은 도구를 이용하여 체인코드의 실행을 관리/제어할 수 있다.



## State database cache for improved performance on CouchDB

With Fabric v2.0, a new peer cache replaces many of these expensive lookups with fast local cache reads. 

The cache size can be configured by using the core.yaml property `cacheSize`.

> couchdb의 문제였던 승인 및 유효성 검사 과정에서의 읽기 지연 현상 해결을 위해, 새로운 피어 캐시를 도입하였다. (couchdb를 계속 가지고 가는 패브릭?)



## Alpine-based docker images

Starting with v2.0, <u>Hyperledger Fabric Docker images will use Alpine Linux, a security-oriented, lightweight Linux distribution</u>. 

> smaller, faster, less disk space



## Sample test network

The test network is built to be a modular and user friendly sample Fabric network that makes it easy to test your applications and smart contracts. 



## Upgrading to Fabric v2.x

A major new release brings some additional upgrade considerations. Rest assured though, that <u>rolling upgrades from v1.4.x to v2.0 are supported</u>, so that network components can be upgraded one at a time with no downtime.

