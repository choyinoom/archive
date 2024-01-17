# How to Deploy your war file using Jenkins

This repository provides an example Jenkins Pipeline for deploying a Java web application using Jenkinsfile and shell scripts. The pipeline deploys the application to remote servers, and it includes backup and rollback functionality.

---

## Jenkinsfile

The Jenkinsfile is written in Groovy and defines the entire pipeline. It uses various stages to perform tasks such as building, deploying, and health checking.

### Variables and User of deployment.yml

Make sure to update the variables in the Jenkinsfile to match your project and server configurations.

- `REMOTE_USER`: The username for the remote server.
- `REMOTE_HOST`: The IP address or hostname of the remote server.
- `DEPLOY_DIR`: The directory on the remote server where the application will be deployed.
- ... (add other variables as needed)

The `deployment.yml` file is used to store information about the target remote servers. The Jenkinsfile reads this file to obtain details such as the remote user, host, deploy directory, etc.

``` yml
dev:  
  - host: 10.1.1.124
    user: myservice
    remote_dir: "$HOME/jenkins"
    backup_dir: "$HOME/backup"
    java_home: "$HOME/jdk17.0.6"
    service_name: springboot-app11
    catalina_base: "$HOME/tomcat8/instances/springboot-app11"
    webapps: "$HOME/webapps"
  - host: 10.1.1.125
    user: myservice
    remote_dir: "$HOME/jenkins"
    backup_dir: "$HOME/backup"
    java_home: "$HOME/jdk17.0.6"
    service_name: springboot-app21
    catalina_base: "$HOME/tomcat8/instances/springboot-app21"
    webapps: "$HOME/webapps"
```

### Pipeline Stages

- **Build:** Compiles the Java web application.
- **Deploy:** Copies the application to the remote server, creates the deployment directory if it doesn't exist, and executes deployment scripts.
- **Health Check:** Performs a health check on the deployed application.

---

## Shell Scripts

Shell scripts (`backup.sh`, `deploy.sh`, `rollback.sh`, etc.) contain specific deployment logic. They are executed by the Jenkins pipeline. 

I came to write these shell scripts because, at times, I've encountered issues with Tomcat servers due to not checking whether the process was properly terminated before starting it up again. Let's make sure our Tomcat operations are more robust by ensuring the server is completely stopped before starting it up.

### Important Notes

- Ensure that your Jenkins environment has the necessary credentials configured (e.g., SSH key for authentication).
- Make sure to grant the required permissions on the remote server for the deployment user.

### Remote server structure

```txt
─ /home/myservice
└ ─ backup
    └ ─ 240117
        └ ─ springboot-app11.war.145218
└ ─ jdk17.0.6
└ ─ jenkins
└ ─ LOGS
    └ ─ springboot-app11
        └ ─ catalina.out
└ ─ webapps
    └ ─ ROOT.war
└ ─ tomcat8 # catalina_home
    └ ─ bin
    └ ─ conf
    └ ─ instances
        └ ─ springboot-app11 # catalina_base
            └ ─ conf
            └ ─ env.sh
            └ ─ start.sh
            └ ─ stop.sh
        └ ─ springboot-app12
    └ ─ ...
```

---

## Troubleshooting

If you encounter issues related to Groovy string interpolation or remote command execution, consider the following tips:

- Use single quotes (`'`) to prevent premature variable interpolation in remote commands.
- Use double quotes (`"`) within single-quoted remote commands to allow variable interpolation.

## Contributing

Feel free to contribute, report issues, or suggest improvements.

Happy coding!





