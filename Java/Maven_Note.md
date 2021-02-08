---
title:  Maven build lib-common for other project  - DEMO
date: 2021-02-08 18:00:26
tags:
    - java
    - maven
    - lib-common
category: 
    - java
---


# Maven build lib-common for other project  - DEMO
Các bước để build lib common, để import vào dự án khác, sử dụng maven

## Repo: lib-common
- Chuẩn bị source code
### 1. file `pom.xml` 
- để ý tới 3 thông số sau:
```xml
   <groupId>vn.sapo.web</groupId>
    <artifactId>app-common</artifactId>
    <version>0.0.5</version>
```

- `version` có thể khai báo kiểu `<version>${buildNumber.version}</version>` để truyền vào dynamic lúc run command `mvn clean source:jar deploy --settings $SETTINGS -DbuildNumber.version=$version`
- lưu ý với `version` có giá trị ở đuôi là SNAPSHOT, thì sẽ được đẩy vào maven repo snapshot (nếu khai báo đủ), còn bình thường sẽ đẩy vào repo release.
- Khai báo 1 vài properties, nếu không có khai báo này, có thể mọi thứ vẫn oke, cho tới khi dự án import lib này vào, khi gọi các class từ lib-common báo lỗi là không tìm thấy.
```xml
    <properties>
        <java.version>11</java.version>
        <maven.javadoc.skip>false</maven.javadoc.skip>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <start-class>tung.explorer.appcommon.AppCommonApplication</start-class>
    </properties>
```
- Khai báo `maven repo` (nơi sẽ chứa lib code của mình)     

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
- Có thể không cần khai báo `snapshotRepository` cũng được. 
- Giá trị trong `id` sẽ phải được định danh ở trong file `settings.xml` 
- Có thể sử dụng dịch vụ cung cấp maven repo `on cloud` : https://packagecloud.io

- Có thể có hoặc không phải báo thêm extension để hỗ trợ việc upload code lên maven repo. Ví dụ như khi dùng `packagecloud` thì phải khai báo thêm extension này, nhưng khi dùng `nexus` thì không cần.
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

- Mẫu code `build`  
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

### 2. file `settings.xml`
- thường file này được đặt mặc định ở thư mục `./m2` , tuy nhiên có thể đặt ở bất kỳ đâu, nhưng lúc maven deploy, thì cần khai báo `path` tại `--settings`
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
- Lưu ý properties `id` sẽ được sử dụng ở trong file `pom.xml` 

### 3. Command  
```bash
mvn clean source:jar deploy --settings $SETTINGS -DbuildNumber.version=$version -Dmaven.install.skip=true
```

## Repo lib-common-dependencies
- sau khi có `lib-common`, để import vào repo khác, chỉ cần khai báo dependency như bình thường
```xml
        <dependency>
            <groupId>me.tungexplorer</groupId>
            <artifactId>app-common</artifactId>
            <version>0.0.5</version>
        </dependency>
```
- nhưng có 1 nhược điểm là các repo import để chạy được, thì phải khai báo lại thêm các `dependency` - cái đã được khai báo ở `lib-common` rồi. Có lẽ để fix cái này có thể dùng cách là lúc export ra file .jar thì `lib-common` ko chỉ export mỗi source code của nó, mà còn export nhúng kèm theo tất cả các thư viện mà nó sử dụng vào nữa, đi kèm. (như vậy file .jar sẽ có dung lượng cao hơn nhiều) 
- Cách thứ 2 là sử dụng `parent`. Tạo ra 1 `lib-common-dependencies`
```xml
    <parent>
        <groupId>me.tungexplorer</groupId>
        <artifactId>app-common-dependencies</artifactId>
        <version>0.1.3</version>
    </parent>
```
- `lib-common-dependencies` cũng sẽ được upload lên maven repo như `lib-common`, tuy nhiên khác là chỉ có file `pom.xml` mà ko có source code. Và trong file `pom.xml` đó sẽ có chứa khai báo các dependencies.
- file `pom.xml` sẽ có khác ở 1 điểm
```xml
   <packaging>pom</packaging>
```

## How to import?
- file `pom.xml`
```xml
    <repositories>
        <repository>
            <id>tungtv202-release</id>
            <url>https://packagecloud.io/priv/819e36c995b147d6355673c5c65fdcb70412f13fga78f96ab/tungtv202/release/maven2</url>
            <releases>
                <enabled>true</enabled>
            </releases>
            <snapshots>
                <enabled>true</enabled>
            </snapshots>
        </repository>
    </repositories>
```

.
