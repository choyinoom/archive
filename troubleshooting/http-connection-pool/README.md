# Troubleshooting API Request Failures: Proper HttpClient Connection Management

## 부제: 공식 문서 확인의 중요성

서비스 A는 사내 많은 서비스들이 호출하는 공통 API를 갖고 있습니다. 근데 어느날 서비스 B에서 서비스 A의 API를 호출하면 30% 정도는 응답을 받지 못하고 있다는 것을 알게 되었다면😱? 서비스 B외에 다른 서비스들은 문제 없이 서비스 A의 API를 호출하고 있는 상황입니다. 여러분은 이 상황에서 아키텍처 어디를 의심하시겠습니까?

<br/>

### 1. 잠재적 원인의 후보 좁혀보기

* 서비스 B 이외에 다른 서비스들은 문제 없이 서비스 A의 API를 호출하고 있습니다.
* 서비스 B의 서버로부터 서비스 A의 서버로 방화벽은 확실히 해제되어 있습니다.
* 클라이언트 톰캣 로그에 찍히는 Exception

  org.apache.http.NoHttpResponseException: 10.0.0.1:8312 failed to respond

* 서비스 B가 A를 호출했다고 하는 그 시간에 서비스 A쪽에는 그 어떠한 access log나 exception도 남아있지 않았습니다.

<br/>

### 2. 에러 재현해보기

아무리 생각해도 서비스 A의 서버나 네트워크 구성에는 문제가 없는 것 같습니다. 그래서 감히 클라이언트쪽의 소스코드를 의심해보았습니다.
클라이언트의 소스를 보니 `BasicHttpClientConnectionManager`를 쓰고 있었습니다.

```java
// 주의: 예제 코드입니다. 운영용으로 사용하지 마십시오.
// WebConfiguration.java
@Bean
public RestTemplate restTemplate() {
 HttpComponentsClientHttpRequestFactory requestFactory = null;
 try {
  ...
  BasicHttpClientConnectionManager connectionManager = new BasicHttpClientConnectionManager(socketFactoryRegistry);

  CloseableHttpClient httpClient = HttpClients.custom()
    .setSSLSocketFactory((LayeredConnectionSocketFactory)sslsf)
    .setConnectionManager(connectionManager)
    .setMaxConnTotal(10)
    .setMaxConnPerRoute(5)
    .build();

  requestFactory = new HttpComponentsClientHttpRequestFactory((HttpClient) httpClient);
 } catch (Exception ex) {
  ...
 }
 return new RestTemplate((ClientHttpRequestFactory)requestFactory);
```

커넥션 매니저를 구성하고 HttpClient를 생성합니다. 이 설정이 전부이고, http요청을 처리하는 서비스 코드 쪽에서는 여기서 만든 restTemplate 빈을 주입받아서 사용합니다. (`RestTemplate`을 쓰면 http 요청을 쉽게 처리할 수 있죠.) 커넥션 풀을 만들어서 커넥션을 재사용하려는 의도 같습니다.

로컬 환경에서 테스트를 해보겠습니다. 위 코드를 바탕으로 스프링 mvc 프레임워크와 아파치 라이브러리를 활용하여 실제 서비스 B 환경을 최대한 비슷하게 구현해주겠습니다. 서비스 A의 api를 호출할 수 있도록 컨트롤러와 서비스 컴포넌트를 만들었습니다.

이제 애플리케이션을 시작한 후 브라우저를 띄워 api를 한 번씩 호출해봅니다. 아니 이럴수가! 아무 문제가 없군요. 한 번에 요청 한 개를 처리하는 데에는 문제가 없습니다.  

그럼 *같은 api로의 요청 여러 개가 한 꺼번에* 들어오면 어떨까요?  
JMeter를 사용하여 1초 안에 2개의 요청을 보내봅니다.

에러가 발생했습니다!! 두 개의 요청 중 한 개의 요청을 처리하지 못했는데요. Exception 로그는 아래와 같았습니다.

 java.lang.IllegalStateException: Connection is still allocated

`NoHttpResponseException`은 아니군요. 그렇지만 문제 해결의 실마리는 보이는 것 같습니다.

<br/>

### 3. 에러 분석하기

`httpClient`에 세팅한 설정값은 `maxConnectionTotal - 10, maxConnPerRoute - 5` 이었습니다. 분명 커넥션 풀을 만들었고, 동시에 같은 호스트로 5개의 요청까지는 문제 없어야 했는데요. 왜 제대로 동작하지 않았던걸까요?

`BasicHttpClientConnectionManager`를 구글에 검색해보니 제일 위에 클래스 문서 링크가 나옵니다. 문서를 열어 설명을 읽어봅니다.

```txt
A connection manager for a single connection. This connection manager maintains only one active connection. Even though this class is fully thread-safe it ought to be used by one execution thread only, as only one thread a time can lease the connection at a time.
This connection manager will make an effort to reuse the connection for subsequent requests with the same route. It will, however, close the existing connection and open it for the given route, if the route of the persistent connection does not match that of the connection request. If the connection has been already been allocated IllegalStateException is thrown.

This connection manager implementation should be used inside an EJB container instead of PoolingHttpClientConnectionManager.
```

왜 의도대로 커넥션 풀링이 되지 않았는지 알려주고 있습니다. `BasicHttpClientConnectionManager`는 한 개의 커넥션만 관리하는 커넥션 매니저입니다. 애초에 한 번에 한 개의 커넥션만 빌려줄 수 있죠.

그러면 이제 HttpClient를 생성하는 코드를 다시 보겠습니다.

```java
CloseableHttpClient httpClient = HttpClients.custom()
 .setSSLSocketFactory((LayeredConnectionSocketFactory)sslsf)
 .setConnectionManager(connectionManager)
 .setMaxConnTotal(10)
 .setMaxConnPerRoute(5)
 .build();
```

setMaxConnTotal과 setMaxConnPerRoute를 세팅한 건 의미가 없는걸까요?

네!! 의미가 없습니다.

```java
// HttpClientBuilder.cjava
/**
* Assigns maximum total connection value.
* <p>
* Please note this value can be overridden by the {@link #setConnectionManager(
*   org.apache.http.conn.HttpClientConnectionManager)} method.
* </p>
*/
public final HttpClientBuilder setMaxConnTotal(final int maxConnTotal) {
 this.maxConnTotal = maxConnTotal;
 return this;
}

/**
* Assigns maximum connection per route value.
* <p>
* Please note this value can be overridden by the {@link #setConnectionManager(
*   org.apache.http.conn.HttpClientConnectionManager)} method.
* </p>
*/
public final HttpClientBuilder setMaxConnPerRoute(final int maxConnPerRoute) {
 this.maxConnPerRoute = maxConnPerRoute;
 return this;
}

```

주석을 보면 이 두 설정은 `setConnectionManager()`에 의해 오버라이드 될 수 있다고 나와있습니다. `BasicHttpClientConnectionManager`는 애초에 한 개의 커넥션만 관리하므로 위 두 설정값이 아무런 의미가 없게 되는 것이죠. 맨 처음 들어온 요청을 처리하기 위해 커넥션을 사용 중인데, 바로 뒤따라 들어온 두 번째 요청이 아직 반납되지 않은 커넥션을 달라고 요청하는 경우 `Connection is still allocated`라는 에러메시지를 보게됩니다. 응답을 받기까지 시간이 소요되는 api이거나 별도의 Keep-Alive 설정이 없다면 쓰레드는 커넥션 사용을 완료했어도 바로 반납하지 않고 대기하므로 유휴 커넥션이 없어 다음 요청이 처리될 수 없는 로직입니다.

```java
// BasicHttpClientConnectionManager.java
@Override
public final ConnectionRequest requestConnection(
  final HttpRoute route,
  final Object state) {
 Args.notNull(route, "Route");
 return new ConnectionRequest() {

  @Override
  public boolean cancel() {
   // Nothing to abort, since requests are immediate.
   return false;
  }

  @Override
  public HttpClientConnection get(final long timeout, final TimeUnit timeUnit) {
   return BasicHttpClientConnectionManager.this.getConnection(
     route, state);
  }

 };
}

synchronized HttpClientConnection getConnection(final HttpRoute route, final Object state) {
 Asserts.check(!this.isShutdown.get(), "Connection manager has been shut down");
 if (this.log.isDebugEnabled()) {
  this.log.debug("Get connection for route " + route);
 }
 Asserts.check(!this.leased, "Connection is still allocated");
 if (!LangUtils.equals(this.route, route) || !LangUtils.equals(this.state, state)) {
  closeConnection();
 }
 this.route = route;
 this.state = state;
 checkExpiry();
 if (this.conn == null) {
  this.conn = this.connFactory.create(route, this.connConfig);
 }
 this.conn.setSocketTimeout(this.socketConfig.getSoTimeout());
 this.leased = true;
 return this.conn;
}
```

### 4. 에러 수정하기

여러 개의 요청이 한꺼번에 몰려 들어와도 문제없이 처리할 수 있는 커넥션 풀을 구성하려면 `PoolingHttpClientConnectionManager`를 사용해야 합니다.

```java
//PoolingHttpClientConnectionManager
@Override
public ConnectionRequest requestConnection(
  final HttpRoute route,
  final Object state) {
 Args.notNull(route, "HTTP route");
 if (this.log.isDebugEnabled()) {
  this.log.debug("Connection request: " + format(route, state) + formatStats(route));
 }
 Asserts.check(!this.isShutDown.get(), "Connection pool shut down");
 final Future<CPoolEntry> future = this.pool.lease(route, state, null); // pool에서 가져온다.
 return new ConnectionRequest() {...  };
}
    
```

`PoolingHttpClientConnectionManager`를 커넥션 매니저로 사용합니다.

```java
@Bean
 public RestTemplate restTemplate() {
  HttpComponentsClientHttpRequestFactory requestFactory = null;
  try {
   ...
   PoolingHttpClientConnectionManager connectionManager = new PoolingHttpClientConnectionManager(socketFactoryRegistry);
   connectionManager.setMaxTotal(10);
   connectionManager.setDefaultMaxPerRoute(5);
   
   CloseableHttpClient httpClient = HttpClients.custom()
     .setSSLSocketFactory((LayeredConnectionSocketFactory)sslsf)
     .setConnectionManager(connectionManager)
     .build();
        
   requestFactory = new HttpComponentsClientHttpRequestFactory((HttpClient) httpClient);
  } catch (Exception ex) {
   ...
  }
  return new RestTemplate((ClientHttpRequestFactory)requestFactory);
```

---

### Reference

[1] [Baeldung - Apache HttpClient Connection Management](https://www.baeldung.com/httpclient-connection-management)  
[2] [BasicHttpClientConnectionManager](https://hc.apache.org/httpcomponents-client-4.5.x/current/httpclient/apidocs/org/apache/http/impl/conn/BasicHttpClientConnectionManager.html)  
[3] [PoolingHttpClientConnectionManager](https://hc.apache.org/httpcomponents-client-4.5.x/current/httpclient/apidocs/org/apache/http/impl/conn/PoolingHttpClientConnectionManager.html)