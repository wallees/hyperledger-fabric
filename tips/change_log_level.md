# LOG LEVEL 변경하기
>docker-compose 파일에서 변경한다.

<br/>

예시) [docker-compose-cli.yaml](https://github.com/hyperledger/fabric-samples/blob/release-1.4/first-network/docker-compose-cli.yaml)

<pre><code>cli:
    container_name: cli
    ...
    environment:
      ...
      - FABRIC_LOGGING_SPEC=DEBUG
      #- FABRIC_LOGGING_SPEC=INFO
      ...
</code></pre>
