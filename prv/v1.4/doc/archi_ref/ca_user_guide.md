# Hyperledger Fabric CA's User Guide

## Prerequisites

1. Hyperledger Fabric-CA의 설치는 [이곳](https://hyperledger-fabric-ca.readthedocs.io/en/latest/users-guide.html#install)을 확인한다.
2. Natively한 방식으로 진행하려 했으나, 최근 GLIBC-2.28 문제로 인하여 Ubuntu/CentOS에서 정상적인 CA 실행이 불가능하여 docker 이미지 기반으로 작성한다.
    - docker-compose-ca-server.yaml
    ``` yaml
    fabric-ca-server:
      image: hyperledger/fabric-ca:amd64-1.4.7
      container_name: fabric-ca-server
      ports:
        - "7054:7054"
      environment:
        - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      volumes:
        - "./fabric-ca-server:/etc/hyperledger/fabric-ca-server"
      command: sh -c 'fabric-ca-server start -b admin:adminpw'
    ```
3. Fabric-ca에서 사용할 환경변수는 다음과 같이 설정한다.
    - export FABRIC_CA_SERVER_HOME=$HOME/fabric-ca/server
    - export FABRIC_CA_CLIENT_HOME=$HOME/fabric-ca/client

<br>

## Fabric CA Server

### Initializing the server

docker exec -it fabric-ca-server /bin/bash

```sh
fabric-ca-server init -b admin:adminpw
```

- fabric-ca-server init은 자체 서명된 CA 인증서를 생성한다.  
- -u <부모 패브릭 ca 서버> 옵션이 있으면 부모 ca 서버가 서명한 인증서가 생성된다.   
- init은 서버의 홈 디렉토리(컨테이너 내부에서는 /etc/hyperledger/fabric-ca-server)에 fabric-ca-server-config.yaml(default config 파일)도 생성한다.

    ``` yaml
    # fabric-ca-server-config.yaml
    309	csr:
    310	   cn: fabric-ca-server
    311	   keyrequest:
    312	     algo: ecdsa
    313	     size: 256
    314	   names:
    315	      - C: US
    316	        ST: "North Carolina"
    317	        L:
    318	        O: Hyperledger
    319	        OU: Fabric
    320	   hosts:
    321	     - fe96108890d1
    322	     - localhost
    323	   ca:
    324	      expiry: 131400h
    325	      pathlength: 1
    ```

- fabric-ca-server-config.yaml에서 TLS 통신도 설정할 수 있다

    ```yaml
    67	tls:
    68	  # Enable TLS (default: false)
    69	  enabled: false
    70	  # TLS for the server's listening port
    71	  certfile:
    72	  keyfile:
    73	  clientauth:
    74	    type: noclientcert
    75	    certfiles:
    ```

<br>

## Fabric CA Client

###  Enrolling the bootstrap identity

```sh
fabric-ca-client enroll -u http://admin:adminpw@localhost:7054
```
- FABRIC_CA_CLIENT_HOME 내부에 fabric-ca-client-config.yaml 파일과 msp가 생성된다.

<br>

### Registering a new identity
```sh
fabric-ca-client register --id.name admin2 --id.affiliation org1.department1 --id.attrs 'hf.Revoker=true,admin=true:ecert'
```

- 아래와 같이 다수의 attr 적용이 가능하다(두가지 모두 같은 기능을 수행한다).
    ```sh
    fabric-ca-client register -d --id.name admin2 --id.affiliation org1.department1 --id.attrs '"hf.Registrar.Roles=peer,client",hf.Revoker=true'

    fabric-ca-client register -d --id.name admin2 --id.affiliation org1.department1 --id.attrs '"hf.Registrar.Roles=peer,client"' --id.attrs hf.Revoker=true
    ```

<br>

### Enrolling a peer identity
```sh
fabric-ca-client register --id.name peer1 --id.type peer --id.affiliation org1.department1 --id.secret peer1pw

fabric-ca-client enroll -u http://peer1:peer1pw@localhost:7054 -M $FABRIC_CA_CLIENT_HOME/msp
```

<br>

### Reenrolling an identity
```sh
fabric-ca-client reenroll
```

<br>

### Revoking a certificate or identity
```sh
# fabric-ca-client revoke -e <enrollment_id> -r <reason>
fabric-ca-client revoke -e peer1
```


