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


# Proxy Chain

## Use Case

- You have a proxy URL that requires authentication via username and password.
- Your tool needs to configure that proxy.
- Your tool would be easier to set up if it could use a proxy without authentication.

### Solution

- We need a "middle proxy server" that will be responsible for forwarding the traffic.

---

### Detailed Solution

- **Middle Proxy Server**: Set up a middle proxy server to forward all traffic from your tool, allowing it to use the proxy without the need for direct authentication.

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
        // Setup WebDriverManager to use ChromeDriver with a specific version
        WebDriverManager.chromedriver().driverVersion("96.0.4664.93").setup();

        // Create ChromeOptions object and configure user agent and ignore certificate errors
        ChromeOptions chromeOptions = new ChromeOptions();
        chromeOptions.addArguments("user-agent=Tung Agent", "--ignore-certificate-errors");

        // Setup the proxy chain
        BrowserMobProxy chainedProxy = new BrowserMobProxyServer();
        // Configure the chained proxy with IP address and port
        chainedProxy.setChainedProxy(new InetSocketAddress("182.54.239.111", 8160));
        // Set proxy authentication
        chainedProxy.chainedProxyAuthorization("user1", "pass2", AuthType.BASIC);
        // Allow trusting all servers
        chainedProxy.setTrustAllServers(true);
        // Start the proxy
        chainedProxy.start(0);

        // Create a Proxy object for Selenium and configure it as MANUAL
        Proxy seleniumProxy = new Proxy();
        seleniumProxy.setProxyType(Proxy.ProxyType.MANUAL);
        // Get the port of the chained proxy and configure it for Selenium Proxy
        String proxyStr = String.format("%s:%d", "localhost", chainedProxy.getPort());
        seleniumProxy.setHttpProxy(proxyStr);
        seleniumProxy.setSslProxy(proxyStr);

        // Add proxy to ChromeOptions
        chromeOptions.setCapability("proxy", seleniumProxy);

        // Create a ChromeBrowser object using ChromeDriver with the configured options
        ChromeBrowser chromeBrowser = new ChromeBrowser(new ChromeDriver(chromeOptions), "Chrome-Test1");
        WebDriver webDriver = chromeBrowser.getWebDriver();
        // Navigate to a website to check the IP address
        webDriver.get("https://checkip.org/");

        // Wait for a few seconds to observe the result, then close the browser
        TimeUnit.SECONDS.sleep(10);

        // Quit the WebDriver and stop the proxy
        webDriver.quit();
        chainedProxy.stop();
    }
}

```
