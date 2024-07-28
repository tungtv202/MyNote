---
title: Understanding Fuzz Testing
date: 2024-07-28 12:00:26
updated: 2024-07-28 12:00:26
tags:
    - java
    - fuzz
    - testing
category: 
    - java
---


## Understanding Fuzz Testing

Recently, I learned about a new concept - **Fuzz Testing**. The main idea of fuzzing is to create unexpected inputs to check if the program handles exception cases correctly.

### Why did I learn about this keyword?

This stems from a situation where I had a piece of code attempting to pass an input (a string) to create an object:

```java
new javax.mail.internet.InternetAddress(str)
```

and it threw an error with the message "Domain contains illegal character".

The problem is that before I passed the value `str`, there were basic validation logics already in place. Basic cases would definitely be filtered out and fail before being passed to `InternetAddress`. However, on production, I still encountered this error. The task now is to find out what value of `str` caused this error.

### The tool I used

I used the following tool: [jazzer](https://github.com/CodeIntelligenceTesting/jazzer)

In my opinion, this tool takes some time for the first experience. The way to run it is simple, but understanding how to run it is complicated.

### How to run

#### 1. Declare Maven dependency

```xml
<dependency>
    <groupId>com.code-intelligence</groupId>
    <artifactId>jazzer-junit</artifactId>
    <version>0.22.1</version>
</dependency>
```

#### 2. Write the test code

```java
import jakarta.mail.internet.AddressException;
import jakarta.mail.internet.InternetAddress;
import com.code_intelligence.jazzer.api.FuzzedDataProvider;

public class MyFuzzTest {
    public static void fuzzerTestOneInput(FuzzedDataProvider data) {
        String input = data.consumeRemainingAsString();
        if (input == null || input.isEmpty()) {
            return;
        }
        MailAddress m;
        try {
            m = new MailAddress(input);
        } catch (AddressException e) {
            return;
        }

        try {
            new InternetAddress(input);
        } catch (Exception e) {
            if (e.getMessage().contains("Domain contains illegal character")) {
                System.out.println("====");
                System.out.println(input);
                System.out.println("====");
                throw new RuntimeException(e);
            }
        }
    }
}
```

#### 3. Download Jazzer

First, download Jazzer from: [jazzer releases](https://github.com/CodeIntelligenceTesting/jazzer/releases)

For example:

```sh
wget https://github.com/CodeIntelligenceTesting/jazzer/releases/download/v0.22.1/jazzer-macos.tar.gz
tar -zxvf jazzer-macos.tar.gz
chmod +x jazzer-macos.tar.gz
```

#### 4. Run Fuzz Test

Use one of the following commands to run:

```sh
./jazzer --cp=$(cat classpath.txt):target/classes:target/test-classes --target_class=org.apache.james.core.MyFuzzTest

./jazzer --cp=target/classes:target/test-classes --target_class=org.apache.james.core.MyFuzzTest
```

### Experience with other tools

Before successfully experiencing jazzer, I used another tool called Berkeley CS JQF. I thought that the tools would be similar and there wouldn't be much difference. However, when running with the JQF Maven plugin, I spent many days and my code still didn't produce any result, even when I left it running on a server.

But with Jazzer, it really surprised me. It only took about ten minutes to produce the first result.