# 체인코드 설치

<br/>

<pre><code>peer chaincode install -n mycc -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH}
</code></pre>
- -v : 체인코드 버전
- -l : 체인코드 언어(golang, java, node)
- -p : 체인코드 경로