---
title: Java - Proxy chain
date: 2022-02-14 11:00:26
updated: 2022-02-14 11:00:26
tags:
    - java
    - selenium
    - proxy
    - proxy chained
category: 
    - java
---

# Proxy chain

## Use case

- You have a proxy url that need "authentication" by username/password.
- Your tool need config that proxy 
- Your tool will be easier to setup, if it using proxy WITHOUT "authentication"

* Solution?
- We need a "middle proxy server", that will has responsibility forward traffic

## Code example

- Maven: 

```xml
        <dependency>
            <groupId>net.lightbody.bmp</groupId>
            <artifactId>browsermob-core</artifactId>
            <version>2.1.5</version>
        </dependency>
```

- Sample code

```java

import java.net.InetSocketAddress;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.Test;
import org.openqa.selenium.Proxy;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;

import io.github.bonigarcia.wdm.WebDriverManager;
import me.tungexplorer.travian.service.crawl.browser.manager.ChromeBrowser;
import net.lightbody.bmp.BrowserMobProxy;
import net.lightbody.bmp.BrowserMobProxyServer;
import net.lightbody.bmp.proxy.auth.AuthType;

public class SeleniumChangeProxyAgentTest {

    @Test
    void test() throws InterruptedException {
        WebDriverManager.chromedriver().driverVersion("96.0.4664.93").setup();
        ChromeOptions chromeOptions = new ChromeOptions();
        chromeOptions.addArguments("user-agent=Tung Agent", "--ignore-certificate-errors");

        // proxy chained
        BrowserMobProxy chainedProxy = new BrowserMobProxyServer();
        chainedProxy.setChainedProxy(new InetSocketAddress("182.54.239.111", 8160));
        chainedProxy.chainedProxyAuthorization("user1", "pass2", AuthType.BASIC);
        chainedProxy.setTrustAllServers(true);
        chainedProxy.start(0);
        chainedProxy.stop();

        Proxy seleniumProxy = new Proxy();
        seleniumProxy.setProxyType(Proxy.ProxyType.MANUAL);
        String proxyStr = String.format("%s:%d", "localhost", chainedProxy.getPort());
        seleniumProxy.setHttpProxy(proxyStr);
        seleniumProxy.setSslProxy(proxyStr);

        chromeOptions.setCapability("proxy", seleniumProxy);

        ChromeBrowser chromeBrowser = new ChromeBrowser(new ChromeDriver(chromeOptions), "Chrome-Test1");
        WebDriver webDriver = chromeBrowser.getWebDriver();
        webDriver.get("https://checkip.org/");

        while (true) {
            TimeUnit.SECONDS.sleep(1);
        }
    }
}
```
