# 자바 웹 어플리케이션에서 xml 설정파일을 마주쳐도 당황하지 말자

## 들어가며

자바로 동적 웹 어플리케이션을 개발해보려는 초심자라면 프로젝트 디렉토리 구조나 xml 파일때문에 고통 받은 적이 한 번쯤은 있을 것이라 생각한다. 대체 WEB-INF 디렉토리는 무엇이며 암호같은 xml 파일들의 내용은 무엇이길래 날 이렇게 괴롭게 하는지! 왜 하필 이 xml 파일명은 이렇게 지은거고, 이 디렉토리에 있어야 하는건지! 그동안 삽질하며 조각조각 모아온 정보들을 한 곳에 정리해보려 한다.

## 0. Servlet(서블릿)

서블릿은 컨테이너에 의해 관리되며, 동적 콘텐츠를 제공한다. 서블릿 컨테이너는 서블릿 엔진이라고도 불리며 서블릿의 기능을 제공한다. 서블릿은 컨테이너가 스펙 문서에서 정의된 기능을 구현한`(implemented)` 요청/응답의 방식에 따라 웹 클라이언트과 상호작용한다.

## 1. WEB-INF

WEB-INF에 대한 설명은 자바 서블릿 스펙 `10.5 Directory Structure` [[1]] 부분을 보면 잘 나와있다. 보통 WEB-INF 폴더 아래에 있는 파일들의 내용은 정적 리소스들처럼 직접적으로 볼 수 없으며, 반드시 서블릿 코드를 거쳐서 제공되게 되어있다. WEB-INF 아래에는 보통 web.xml, classes 디렉토리, lib 디렉토리 등이 있다. 어플리케이션의 클래스 로더는 이 classes 디렉토리에 있는 클래스들을 가장 먼저 로드하며, 이후 lib 디렉토리 아래에 있는 library JAR들을 로드한다는 규칙 등이 궁금한 사람들은 원문을 찾아가보자.

[1]: https://javaee.github.io/servlet-spec/downloads/servlet-4.0/servlet-4_0_FINAL.pdf

## 2. DispatcherServlet

Spring Web MVC Framework를 사용하면 다양한 형태의 요청과 응답을 수월하게 처리하고 관리할 수 있다. 개발자는 정해진 가이드라인에 맞추어 요청과 응답을 처리하는 코드를 작성하기만 하면 되고 그 이외의 것은 신경쓰지 않아도 되기 때문이다. `DispatcherServlet`은 Spring Web MVC Framework의 핵심으로, 클라이언트로부터 요청을 짝이 맞는 컨트롤러에게 전달해주어 결국 클라이언트가 적절한 응답을 받을 수 있도록 한다.

### **요청 매핑**

 '/example 로 시작하는 모든 요청은 example이라는 이름을 가진 `DispatcherServlet` 인스턴스로 처리하고 싶다'는 매핑 작업을 `web.xml` 파일에 할 수 있다

```xml
<!-- web.xml--> 
<web-app>

    <servlet>
        <servlet-name>example</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <load-on-startup>1</load-on-startup>
    </servlet>

    <servlet-mapping>
        <servlet-name>example</servlet-name>
        <url-pattern>/example/*</url-pattern>
    </servlet-mapping>

</web-app>
```

### **특정 서블릿에서만 유효한 빈(bean) 정의**

Web MVC framework에서 각 `DispatcherServlet`는 자신만의 `WebApplicationContext`를 가지게 되는데,이 때 root `WebApplicationContext`에 정의된 빈들을 상속받는다. 이렇게 상속받은 빈이라도 특정 서블릿 인스턴스 안에서만 유효하도록 override할 수 있으며, Spring MVC는 이 설정을 WEB-INF 아래에 있는 `[servlet-name]-servlet.xml` 파일로부터 가져오도록 설계되어있다.

```xml
<!-- 어플리케이션 전체에서 유효한 Context Configuration  (e.g., applicationContext.xml) -->
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- Parent Bean Definition -->
    <bean id="messageService" class="com.example.MessageServiceImpl">
        <property name="message" value="Hello from Application Context!"/>
    </bean>
</beans>
```

```xml
<!-- 특정 서블릿에서만 유효한  Configuration (e.g., myapp-servlet.xml) -->
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
                           http://www.springframework.org/schema/beans/spring-beans.xsd">


    <!-- Override Bean Definition in Servlet Scope 
	messageService빈은 override되어 이 서블릿에서 처리하는 request 한 개마다 새로운 빈을 생성하게 된다.
	-->
    <bean id="messageService" class="com.example.MessageServiceImpl" scope="request">
        <property name="message" value="Hello from Servlet Scope!"/>
    </bean>
</beans>
```

#### 참조

* [spring doc 3.2.x](https://docs.spring.io/spring-framework/docs/3.2.x/spring-framework-reference/html/mvc.html#mvc-servlet)
* [applicationContext.xml vs spring-servlet.xml](https://www.baeldung.com/spring-applicationcontext-vs-spring-servlet-xml)
