# Use your Database Connection Pool Wisely!

Database connection pools such as Apache DBCP2 and HikariCP offer essential benefits for Java developers. By efficiently managing database connections, connection pools improve resource utilization, enhance application performance, and enable scalability to handle varying loads. However, improper configuration can lead to performance bottlenecks and slowdowns. This article explores essential considerations for configuring connection pool libraries to ensure optimal database performance in your Java applications.

---

## The Pitfalls of Misconfiguration: A Real-World Example

I recently encountered a performance degradation issue in our critical customer service application. Initial investigations pointed towards database load, but further analysis revealed that our connection pool configuration was the problem. The `maxPoolSize` parameter, which defines the maximum number of connections the pool can maintain, was set too low. This resulted in a scenario where concurrent user requests overwhelmed the pool, leading to a queue for connections. Users experienced significant delays as they waited for available connections, impacting the overall responsiveness of the application.
<br/>
<br/>

## Lessons Learned: Key Considerations for Connection Pool Configuration

Here are crucial aspects to consider when configuring your connection pool library:

`maxPoolSize`:  This parameter directly impacts the number of concurrent connections your application can handle. Set it too low, and you'll encounter queuing and delays like in our example. Set it too high, and you risk exhausting database resources or creating unnecessary overhead. Finding the optimal value depends on your application's expected load and database capacity. Analyzing application access patterns and conducting load testing are essential for making informed decisions.

`minPoolSize`: This parameter defines the *minimum number of idle connections* the pool will maintain. A higher minPoolSize reduces the time spent acquiring connections, but keeping too many idle connections can consume resources. A balanced approach is key.

`Validation Strategies`: Connection pools can perform validation checks to ensure connections are still usable before handing them to your application. While validation adds a slight overhead, it helps prevent issues with stale or broken connections.  Consider the trade-off between performance and reliability when configuring validation options.

`Timeouts`: Configure connection timeouts to prevent threads from waiting indefinitely for connections. JDBC offers a layered approach to timeouts, providing control at different stages of database interaction: JDBC Driver SocketTimeout, StatementTimeout, TransactionTimeout.

`Monitoring and Tuning`:  Don't set it and forget it! Regularly monitor pool metrics (available connections, usage patterns, wait times) to identify potential bottlenecks and adjust configurations as needed.

By carefully considering these factors and following recommended practices, you can leverage connection pool libraries to achieve optimal database performance and a responsive user experience in your Java applications.
</br>
</br>

### *✔ Tips for you*

* Enable `testWhileIdle`: If you are using Commons DBCP, keep an eye on `testWhileIdle`. This helps prevents a risk of evicting connections that are still perfectly usable but have simply been idle for a while.

* Collaborate with your DBA👩‍💻: DBAs can analyze connection pool metrics and database logs to pinpoint the root cause of the issue, whether it's a connection pool misconfiguration, database load imbalance, or a combination of factor. They can help you find the optimal configuration for your specific application workload and database setup.

  ```sql
  --DBA (or even you) can check session information for each current session from V$SESSION. Query and check if a database connection pool is configured as your intention.
	SELECT 
		CLIENT_INFO,
		OSUSER,
		STATUS,
		A.*
	FROM GV$SESSION A
	WHERE OSUSER = 'yourosuser';
  ```

</br>

### *✔ Apache Tomcat | How to configure a resource for JNDI lookups*

* context.xml

    ``` xml
	<Resource  
		name="jdbc/TestDB" 
		driverClassName="oracle.jdbc.OracleDriver" 
		type="javax.sql.DataSource" 
		url="jdbc:oracle:thin:@localhost:5521:DEV" 
		username="dbuser" 
		password="dbpwd!$" 
		initialSize="5" 
		minIdle="5" 
		maxIdle="10" 
		maxWaitMillis="1000" 
		testOnBorrow="false" 
		testWhileIdle="true" 
		validationQuery="select 1 from dual" 
		minEvictableIdleTimeMillis="-1" 
		timeBetweenEvictionRunsMillis="600000" 
		numTestsPerEvictionRun="5"
	/> 
	```

<br>

* You can verify directly by checking the tomcat catalina logs

	```properties
	#logging.properties
	org.apache.catalina.core.NamingContextListener.level = ALL
	```


---
#### References

* [Commons DBCP 이해하기](https://d2.naver.com/helloworld/5102792)
* [JDBC Internal - 타임아웃의 이해](https://d2.naver.com/helloworld/1321)
* [JDBC커넥션 풀들의 리소스 관리 방식 이해하기](https://kakaocommerce.tistory.com/45)
* [Apache Commons DBCP - BasicDataSource Configuration Parameters](https://commons.apache.org/proper/commons-dbcp/configuration.html)
* [Apache Tomcat 9 - The Tomcat JDBC Connection Pool](https://tomcat.apache.org/tomcat-9.0-doc/jdbc-pool.html)
