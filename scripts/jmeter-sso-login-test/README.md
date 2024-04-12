# JMeter - How I wrote a Test Script for SSO Login

## Introduction

In this series of stories, I'll share my experience and insights gained while creating a JMeter script for testing the Single Sign-On (SSO) login feature of corporate website. From initial setup to handling authentication tokens, I'll cover various obstacles I met and how i resolved them.

## 1. Recording Test Scenarios

### Goal

- Record user interactions for login scenarios.

### Actions

1. Configure JMeter's HTTP(S) Test Script Recorder.
2. Set up browser proxy settings to capture requests.
3. Perform login actions on the website.
4. Stop recording and review generated requests.

### Insights

- Checking resource details in the browser's devtools network tab allows for a comprehensive understanding of the requests made during the login process
- Some seemingly unimportant JavaScript files may contain crucial functionality for the login process
- Utilize JMeter's "Requests Filtering" feature to focus on capturing only relevant requests

## 2. Correlating Requests and Extracting Parameters

### Goal

- Correlate each request with the necessary parameters for subsequent requests.

### Actions

1. Identify parameters required for subsequent requests.
   - Thoroughly examine parameters, headers, and body data  (ex. Referer, Authorization, Cookies... )
2. Determine which parameters from the previous request are used in the following request.
3. Extract parameters from the previous request's response body if needed.
4. **Add Cookie Manager:** Implement a Cookie Manager to handle session tokens for subsequent requests.
5. **Handling Front-end Encryption:** Implement front-end encryption to secure transmitted data during the login process. (This approach is specific to my scenario and might not be applicable universally.)
   - Upon communication with the SSO server, client public and private keys were generated.
   - JavaScript files such as "jsbn2.js", "ec.js", and "rng.js" were utilized for key generation.
   - Initially, attempted to load all external files from the "JSR223 Sampler." However, encountered errors due to the usage of the Navigator object, which is read-only.
   - Downloaded relevant JavaScript files related to encryption and commented out sections utilizing the Navigator object. It was confirmed that these sections were mostly within conditional statements and were skipped during the login processes.

### Insights

- Correlating requests involves identifying which parameters from one request are needed for subsequent requests, ensuring the flow of data between interactions.
- Extracting parameters from the response body of the previous request allows for dynamic handling of data, adapting to changes in the application's behavior. You can use something like 'CSS Selector Extractor Post Processor'.

## 3. Validating Responses and Reusability Consideration

### Goal

- Validate login responses for correctness.

### Actions

1. Add assertion elements to verify response status codes and content.
2. Extract access token as a parameter for subsequent requests.
3. Parameterize user credentials using CSV data set config.

### Insights

- Assertions ensure the expected behavior of the application under test.
- Parameterization allows for the variation of user data, enhancing test realism.
- **Consider Reusability:** Extract access token as a parameter from the login response.
	- Recognize that all API requests require access tokens obtained during the login process.
   - The login process can be reused as an "Once Only Controller", and it will reduce redundancy in token retrieval across multiple scripts.


## Conclusion
Creating a JMeter script for testing SSO login was a rewarding experience. By following these stories, I gained valuable insights into preparing scripts for load testing.

However, it's important to note that during the testing process, I encountered challenges with memory consumption when using GUI features of JMeter, such as Selenium for opening browsers in the background. This resulted in the virtual machine hanging up shortly after the performance test began. Therefore, I strongly recommend avoiding the use of GUI features during load tests to prevent such issues and ensure smooth test execution.

---

### References
[1] [How to load external JavaScript file in JMeter](https://www.linkedin.com/pulse/how-load-external-javascript-file-jmeter-jithin-somaraj/)  
[2] [CSS Selector Extractor Post Processor in JMeter](https://www.linkedin.com/pulse/css-selector-extractor-post-processor-jmeter-reetha-vadakkekkara-q1s0c/)  
[3] [Elliptic Curve Diffie Hellman with JavaScript](https://asecuritysite.com/javascript/js08)