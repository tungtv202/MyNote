---
title: Gatling maven sample
date: 2022-05-13 21:00:26
updated: 2022-05-13 18:00:26
tags:
    - gatling
    - maven
    - performance test
category: 
    - other
---

# Gatling maven sample

## Maven

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>me.tungexplorer</groupId>
    <artifactId>gatling-maven-sample</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <scala-maven-plugin.version>4.6.0</scala-maven-plugin.version>
        <gatling-maven-plugin.version>4.1.5</gatling-maven-plugin.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>io.gatling.highcharts</groupId>
            <artifactId>gatling-charts-highcharts</artifactId>
            <version>3.7.6</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <testSourceDirectory>src/test/scala</testSourceDirectory>
        <plugins>
            <plugin>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.2.0</version>
            </plugin>
            <plugin>
                <groupId>net.alchim31.maven</groupId>
                <artifactId>scala-maven-plugin</artifactId>
                <version>${scala-maven-plugin.version}</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>testCompile</goal>
                        </goals>
                        <configuration>
                            <args>
                                <arg>-target:jvm-11</arg>
                                <arg>-deprecation</arg>
                                <arg>-feature</arg>
                                <arg>-unchecked</arg>
                                <arg>-language:implicitConversions</arg>
                                <arg>-language:postfixOps</arg>
                                <arg>-Xlog-implicits</arg>
                                <arg>-explaintypes</arg>
                            </args>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>io.gatling</groupId>
                <artifactId>gatling-maven-plugin</artifactId>
                <version>${gatling-maven-plugin.version}</version>
            </plugin>
        </plugins>
    </build>

</project>
```

## Simulation

```java
import io.gatling.core.Predef._
import io.gatling.core.scenario.Simulation
import io.gatling.core.structure.ScenarioBuilder
import io.gatling.http.Predef._
import io.gatling.http.protocol.HttpProtocolBuilder
import io.gatling.http.request.builder.HttpRequestBuilder

import scala.concurrent.duration._
import scala.language.postfixOps
import scala.util.Random

class SampleSimulation extends Simulation {

  def httpCall(): HttpRequestBuilder = http("Request to endpoint /test")
    .get("/test")
    .queryParam("greetingEmail", "${email}")
    .queryParam("secondParam", StringBody(session => s"""{ "orderReference": "${generateSecondParam()}" }"""))

  def generateSecondParam(): String = Random.alphanumeric.take(20).mkString

  val feeder: Iterator[Map[String, String]] = Iterator.continually {
    Map("email" -> s"${Random.alphanumeric.take(20).mkString}@foo.com")
  }

  def generate(): ScenarioBuilder =
    scenario("Call http test")
      .exec(feed(feeder)
        .exec(httpCall()
          .check(status.is(200))))

  def httpProtocol: HttpProtocolBuilder = http
    .baseUrl("https://webhook.site/456eed1d-a188-407d-a0d7-38d820366234")
    .acceptHeader("application/json")
    .contentTypeHeader("application/json; charset=UTF-8")

  setUp(generate()
    .inject((rampUsersPerSec(1).to(2) during (2 minutes)).randomized)
    .protocols(httpProtocol)
  )
}
```


## Runner

```java
import io.gatling.app.Gatling
import io.gatling.core.config.GatlingPropertiesBuilder

object GatlingRunnerSample extends App {
  val simulationClass: String = "me.tungexplorer.SampleSimulation"

  val props: GatlingPropertiesBuilder = new GatlingPropertiesBuilder
  props.resourcesDirectory("src/main/scala")
  props.binariesDirectory("target/scala/classes")
  props.resultsDirectory("/tmp/gatling-result")
  props.simulationClass(simulationClass)

  Gatling.fromMap(props.build)
}
```

## Git project
- https://github.com/tungtv202/gatling-maven-sample