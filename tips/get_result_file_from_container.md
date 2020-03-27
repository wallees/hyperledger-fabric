# 컨테이너에서 실행한 결과 파일에 작성하기
> 실행 명령 뒤에 >&파일명 을 적어주면 된다. (&을 적어주는 것이 중요함)

<br/>

<pre><code>peer chaincode install -n mycc -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} > &{file}</code></pre>

<br/>

> 예시)
><pre><code>peer chaincode install -n mycc -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} > &log.txt</code></pre>