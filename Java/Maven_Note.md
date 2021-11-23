---
title:  Maven Note
date: 2021-02-08 18:00:26
updated: 2021-02-08 18:00:26
tags:
    - java
    - maven
    - lib-common
category: 
    - java
---

# Maven Note

## Maven build lib-common for another project - Tutorial

This is a tutorial for build a common library that can import for another project.

### Repo: lib-common side

#### 1. `pom.xml`file

- Should attention to three parameters

```xml

<groupId>me.tungexplorer</groupId>
<artifactId>app-common</artifactId>
<version>0.0.5</version>
```

- `version`: We can use the format `<version>${buildNumber.version}</version>`, that will help we set version as
  dynamic when run command `mvn clean source:jar deploy --settings $SETTINGS -DbuildNumber.version=$version`
- NOTICE: `version` has suffixed is "SNAPSHOT" will push to snapshot maven repo (if define). Otherwise, it will push to
  release-repo.
- Declare some properties. If not, it may do not happen anything, but when another project import it, it will throw not
  found exception

```xml

<properties>
    <java.version>11</java.version>
    <maven.javadoc.skip>false</maven.javadoc.skip>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
    <start-class>tung.explorer.appcommon.AppCommonApplication</start-class>
</properties>
```

- Declare `maven repo` (where to store this source code - that has been compiled to `jar` file)

```xml

<distributionManagement>
    <repository>
        <id>packagecloud-tungtv202</id>
        <url>packagecloud+https://packagecloud.io/tungtv202/release</url>
    </repository>
    <snapshotRepository>
        <id>packagecloud-tungtv202-snapshot</id>
        <url>packagecloud+https://packagecloud.io/tungtv202/snaphot</url>
    </snapshotRepository>
</distributionManagement>
```

-`snapshotRepository` is optional

- `id` MUST BE define in `settings.xml` file (.m2 directory)
- https://packagecloud.io : cloud repo service

- `extensions` require or not with a different repository. Example: `packagecloud` is required, `nexus` is not

```xml

<build>
    <extensions>
        <extension>
            <groupId>io.packagecloud.maven.wagon</groupId>
            <artifactId>maven-packagecloud-wagon</artifactId>
            <version>0.0.4</version>
        </extension>
    </extensions>
</build>
```

- Example `build`

```xml

<build>
    <extensions>
        <extension>
            <groupId>io.packagecloud.maven.wagon</groupId>
            <artifactId>maven-packagecloud-wagon</artifactId>
            <version>0.0.4</version>
        </extension>
    </extensions>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <executions>
                <execution>
                    <id>repackage</id>
                    <goals>
                        <goal>repackage</goal>
                    </goals>
                    <configuration>
                        <attach>false</attach>
                        <classifier>exec</classifier>
                    </configuration>
                </execution>
            </executions>
        </plugin>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            <configuration>
                <archive>
                    <manifest>
                        <addClasspath>true</addClasspath>
                        <classpathPrefix>lib/</classpathPrefix>
                        <mainClass>${start-class}</mainClass>
                    </manifest>
                </archive>
            </configuration>
        </plugin>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-dependency-plugin</artifactId>
            <executions>
                <execution>
                    <id>copy-dependencies</id>
                    <phase>package</phase>
                    <goals>
                        <goal>copy-dependencies</goal>
                    </goals>
                    <configuration>
                        <outputDirectory>${project.build.directory}/lib</outputDirectory>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

#### 2. file `settings.xml`

- Default storage in `./m2` directory, We can use absolute path with `--settings` parameter
- Example:

```xml

<servers>
    <server>
        <id>tungexplorer-maven</id>
        <username>AKIASOJSS7XE5EHSQY6C</username>
        <password>nh7kQ84k5cyNvcEcapRo+e4gzo5OwYaYVaoS7vMQZ</password>
        <configuration>
            <wagonProvider>s3</wagonProvider>
        </configuration>
    </server>
    <server>
        <id>packagecloud-tungtv202</id>
        <password>a5ebcbe4709a89e5ae59a98d0052acd4f0035c3b908cecd7e</password>
    </server>
</servers>
```

- `id` will be using in `pom.xml`

#### 3. Command

```bash
mvn clean source:jar deploy --settings $SETTINGS -DbuildNumber.version=$version -Dmaven.install.skip=true
```

### Repo lib-common-dependencies

- import owns dependency like as any other dependencies

```xml

<dependency>
    <groupId>me.tungexplorer</groupId>
    <artifactId>app-common</artifactId>
    <version>0.0.5</version>

</dependency>
```

- Cons: we need import all `dependency` - that used in `lib-common`. Solution: when combine to jar file, we should
  combine all dependencies (more size). Other is created a `lib-common-dependencies`

```xml

<parent>
    <groupId>me.tungexplorer</groupId>
    <artifactId>app-common-dependencies</artifactId>
    <version>0.1.3</version>
</parent>
```

- `lib-common-dependencies` will be upload to maven repo (like as `lib-common`), But it will only file `pom.xml` (
  without source code). In `pom.xml` file has defined all dependencies

- NOTICE:

```xml

<packaging>pom</packaging>
```

### How to import?

- `pom.xml`

```xml

<repositories>
    <repository>
        <id>tungtv202-release</id>
        <url>https://packagecloud.io/priv/819e36c995b147d6355673c5c65fdcb70412f13fga78f96ab/tungtv202/release/maven2
        </url>
        <releases>
            <enabled>true</enabled>
        </releases>
        <snapshots>
            <enabled>true</enabled>
        </snapshots>
    </repository>
</repositories>
```

## What is different between `dependencyManagement` and `dependencies`

- Example: pom parent

```xml

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

- pom child

```xml

<dependencies>
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
    </dependency>
</dependencies>
 ```

- Artifacts specified in the <dependencies> section will ALWAYS be included as a dependency of the child module(s).
- Artifacts specified in the <dependencyManagement> section will only be included in the child module if they were also
  specified in the <dependencies> section of the child module itself. Why is it good, you ask? Because you specify the
  version and/or scope in the parent, and you can leave them out when specifying the dependencies in the child POM. This
  can help you use unified versions for dependencies for child modules without specifying the version in each child
  module.

## Goal vs. phase

- Example: We want to plugin will run at `test-compile` phase

```xml
<plugin>
    <groupId>io.github.evis</groupId>
    <artifactId>scalafix-maven-plugin</artifactId>
    <version>0.1.6_0.9.29</version>
    <executions>
        <execution>
            <id>scala-check-style</id>
            <goals>
                <goal>scalafix</goal>
            </goals>
            <phase>process-test-classes</phase>
        </execution>
    </executions>
</plugin>
```

- `id` is unique. If we don't define it, maven auto-create id has the format: `default-abcxyz`
- If we don't define exactly `goal`, maven will auto using `goal`
  default (https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#built-in-lifecycle-bindings)
- If a plugin doesn't have `goal` default, this plugin will not run
- Previous example: plugin scalafix has `scalafix` default goal. When maven is running to `process-test-classes` phase,
  it will execute scalafix plugin.
- [`phase list`](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#lifecycle-reference)

## Force a dependency cleanup on the build phase 

`mvn dependency:purge-local-repository ... ` 
