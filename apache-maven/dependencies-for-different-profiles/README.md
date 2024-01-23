# Profile-Based Dependency Configuration

## Use Different Dependencies for Different Profiles

* For `dev` profile:

  ```bash
  mvn clean package -Pdev
  ```

* For `prod` profile:

  ```bash
  mvn clean package -Pprod
  ```

## How to use maven-install-plugin

The maven-install-plugin is commonly used when dealing with third-party libraries or custom-built artifacts that are not available in the online Maven repositories, and you want to make it accessible for your project.

**Configuration in pom.xml:**

  Typically, the configuration for this plugin is added in the `<build>` section of the pom.xml file. It includes details such as the file path, artifact coordinates (groupId, artifactId, version), and packaging type.

**Execution During Maven Phases:**

  The installation is triggered during a specific Maven phase. In my pom.xml, the installation is set to occur during the <u>validate</u> phase.

  To install custom libraries into your local repository without executing the entire Maven build lifecycle, you can use the following command:

  ```bash
  mvn validate -Pdev
  ```
