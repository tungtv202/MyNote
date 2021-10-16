---
title: Web Game Supervisor
date: 2021-10-16 12:44:26
updated: 2021-10-16 12:44:26
tags:
    - crawl
    - travian
    - superviosr
    - selenium
    - chromedriver
    - chartjs
category: 
    - stories
---

# Web Game Supervisor

## Context
- We have a web game (that already)
- We want to follow some game accounts, we want to know which time of the day that account is active/inactive. We want to monitor some info from that account every hour (ex: account's score)
- We want to visualize all activity about target accounts on a chart. (maybe this will support competitor for some tactic in-game)

## Technicals stack
- Selenium: for crawl data from the web game. 
    - login game with a setup account
    - access to the target account profile
    - detect HTML element - that has target info

- Spring: backend 
    - Spring Scheduler: cron trigger crawl task every hour
- Reactjs: frontend
- Docker: deployment
- Chartjs: library for the chart - that will visualize crawled data
- Database: persistent data. 
    - H2 for dev, MySQL for prod.
- Jhipster: generate base code. 
- AWS Lightsail: hosting web app


Note: this is a simple app for some users (CCU is very low). We don't need cache or advanced technical

## Database diagram

![Database Diagram](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/crawl_travian/db_diagram.png)

## Jhipster JDL Note

- We can use `@readOnly` before the `entity` - that we want to is will only reducer/api/web-ui for reading data
- We can use `filter` tag for want to generate advance search query support. 
    - Example: `filter UserFollowLog`

## Backend hightlight
### Selenium
- We can use `io.github.bonigarcia:webdrivermanager` for "binary chrome", It will help we needn't download `chromedriver` from somewhere on the internet, and import it to the source app, with manual config absolute-path.

```xml
        <dependency>
            <groupId>io.github.bonigarcia</groupId>
            <artifactId>webdrivermanager</artifactId>
            <version>5.0.3</version>
        </dependency>
```

### ChromeBrowserManagement
- Config something related to selenium/ chrome driver
- In order to crawling parallel in multiple chrome window. 
    - Example: Target User A -> Chrome1, Target User B -> Chrome2

- `ChromeBrowserManagement.class` :

```java
import com.google.common.base.Preconditions;
import io.github.bonigarcia.wdm.WebDriverManager;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import lombok.extern.slf4j.Slf4j;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class ChromeBrowserManagement {
    public static final int MAX_BROWSER_NUMBER = 5;
    private static boolean isInitConfig = false;
    private static final ChromeOptions chromeOptions = new ChromeOptions();
    private static final boolean isHeadLessMode = true;
    private static final AtomicInteger TOTAL_BROWSER_OPENED = new AtomicInteger(0);
    private final Map<String, ChromeBrowser> mapChromeBrowser = new ConcurrentHashMap<>();

    public ChromeBrowser getFreeChromeBrowser(String loginUser) {
        ChromeBrowser chromeBrowser = null;
        for (Map.Entry<String, ChromeBrowser> stringChromeBrowserEntry : mapChromeBrowser.entrySet()) {
            if (stringChromeBrowserEntry.getKey().startsWith(loginUser) && !stringChromeBrowserEntry.getValue().isBusy()) {
                chromeBrowser = stringChromeBrowserEntry.getValue();
                break;
            }
        }

        if (chromeBrowser == null) {
            try {
                chromeBrowser = createNewBrowser(loginUser);
            } catch (IllegalArgumentException exception) {
                log.warn(exception.getMessage());
            }
        }
        if (chromeBrowser == null) {
            for (Map.Entry<String, ChromeBrowser> stringChromeBrowserEntry : mapChromeBrowser.entrySet()) {
                if (!stringChromeBrowserEntry.getValue().isBusy()) {
                    chromeBrowser = stringChromeBrowserEntry.getValue();
                    break;
                }
            }
        }
        if (chromeBrowser == null) {
            throw new RuntimeException("Have not any free chrome right now");
        }
        return chromeBrowser;
    }

    private ChromeBrowser createNewBrowser(String loginUser) {
        Preconditions.checkArgument(TOTAL_BROWSER_OPENED.get() < MAX_BROWSER_NUMBER, "Can't create more chrome window");
        ChromeBrowser chromeBrowser = new ChromeBrowser(new ChromeDriver(chromeOptions), "Chrome-" + (mapChromeBrowser.size() + 1));
        mapChromeBrowser.put(loginUser + "_" + TOTAL_BROWSER_OPENED.get(), chromeBrowser);
        TOTAL_BROWSER_OPENED.incrementAndGet();
        return chromeBrowser;
    }

    public static void configChromeDriver() {
        if (!isInitConfig) {
            WebDriverManager.chromedriver().driverVersion("94.0.4606.41").setup();
            chromeOptions.setHeadless(isHeadLessMode);
            chromeOptions.addArguments("--disable-dev-shm-usage", "--disable-gpu");
            isInitConfig = true;
        }
    }
}
```

- `chromeOptions.addArguments("--disable-dev-shm-usage", "--disable-gpu")`: It will help us when running the app in docker with non-gui mode.
- `ChromeBrowser.class` is a class has `org.openqa.selenium.WebDriver` and other special info

```java
    public ChromeBrowser(WebDriver webDriver, String name) {
        this.createdTime = MyHelper.getNow();
        this.webDriver = webDriver;
        this.name = name;
    }
```

## Frontend
### Chartjs
- [https://www.chartjs.org](https://www.chartjs.org/)
- Expected looks like:

![Chart expected](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/crawl_travian/expected_chart.png)

- `Chart.tsx`

```js
import React from 'react';
import { Bubble } from 'react-chartjs-2';
import ChartDataLabels from 'chartjs-plugin-datalabels';

export const Chart = prop1 => {
  const option: any = {
    pointStyle: 'circle',
    title: {
      display: true,
    },
    plugins: {
      datalabels: {
        color: 'blue',
        display: true,
        formatter: function (value, context) {
          if (value.changepoc === 0) {
            return '';
          }
          return value.changepoc;
        },
      },
    },
    scales: {
      x: {
        type: 'category',
        labels: [
          '.',
          '00AM',
          '01AM',
          '02AM',
          '03AM',
          '04AM',
          '05AM',
          '06AM',
          '07AM',
          '08AM',
          '09AM',
          '10AM',
          '11AM',
          '12PM',
          '13PM',
          '14PM',
          '15PM',
          '16PM',
          '17PM',
          '18PM',
          '19PM',
          '20PM',
          '21PM',
          '22PM',
          '23PM',
          '.',
        ],
      },
      y: {
        type: 'category',
        labels: prop1.yLabels,
      },
    },
  };

  const plugins: any = [ChartDataLabels];
  return (
    <div>
      <Bubble data={prop1.chartData} options={option} plugins={plugins} height={150} />
    </div>
  );
};

```

- `ChartDemo.tsx`

```js
import React, { useEffect } from 'react';
import { Chart } from './Chart';
import { useAppDispatch, useAppSelector } from 'app/config/store';
import { getEntity } from '../user-chart-data/user-chart-data.reducer';
import { IChartPoint } from 'app/shared/model/user-chart-data.model';

export default function ChartDemo(props1) {
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(getEntity(props1.userId));
  }, []);

  const userChartDataEntity = useAppSelector(state => state.userChartData.entity);

  const allChartPoints: IChartPoint[] = userChartDataEntity.chartPoints;
  const bubbleIncrease = [];
  const bubbleDecrease = [];
  const bubbleConstant = [];
  const bubbleUnknown = [];
  const pocRate = userChartDataEntity.indexRate;
  const getR = pocValue => {
    if (pocValue === null) {
      return 15;
    }
    const r = pocRate === 0 ? pocValue : pocValue / pocRate;
    return Math.max(r, 15);
  };

  allChartPoints.map((value, index) => {
    if (value.activity === 'INCREASE') {
      bubbleDecrease.push({
        x: value.hour,
        y: value.date,
        r: getR(value.poc),
        poc: value.poc,
        changepoc: value.changepoc,
      });
    } else if (value.activity === 'DECREASE') {
      bubbleIncrease.push({
        x: value.hour,
        y: value.date,
        r: getR(value.poc),
        poc: value.poc,
        changepoc: value.changepoc,
      });
    } else if (value.activity === 'CONSTANT') {
      bubbleConstant.push({
        x: value.hour,
        y: value.date,
        r: getR(value.poc),
        poc: value.poc,
        changepoc: value.changepoc,
      });
    } else {
      bubbleUnknown.push({
        x: value.hour,
        y: value.date,
        r: getR(value.poc),
        poc: value.poc,
        changepoc: value.changepoc,
      });
    }
  });

  const data1 = {
    datasets: [
      {
        title: 'dataTitle1',
        label: 'Increase',
        data: bubbleDecrease,
        backgroundColor: 'rgb(124,252,0)',
        radius: 10000,
      },
      {
        label: 'Decrease',
        title: 'dataTitle2',
        data: bubbleIncrease,
        backgroundColor: 'rgb(215,86,112)',
      },
      {
        label: 'Constant',
        title: 'dataTitle3',
        data: bubbleConstant,
        backgroundColor: 'rgb(84,110,196)',
      },
      {
        label: 'Unknown',
        title: 'dataTitle4',
        data: bubbleUnknown,
        backgroundColor: 'rgb(129,111,116)',
      },
    ],
  };

  return (
    <div className="App">
      <Chart chartData={data1} pocRate={userChartDataEntity.indexRate} yLabels={userChartDataEntity.ylabels} />
    </div>
  );
}

```

### Add missing Awesome Icon 

```js
import { faSync } from '@fortawesome/free-solid-svg-icons';
library.add(faSync);
<FontAwesomeIcon icon="sync" spin={loading} />{' '}
```

## Deployment

### Package the source code - Shell script

```bash
echo "BIG STEP 1: Build jar file"
mvn -Pprod package -DskipTests

echo "BIG STEP 2: Build Dockerfile"
docker build -t crawl_travian .

echo "BIG STEP 3: Upload to AWS ECR"
docker tag crawl_travian:latest 168146697673.dkr.ecr.ap-southeast-1.amazonaws.com/crawl_travian:$1
docker push 168146697673.dkr.ecr.ap-southeast-1.amazonaws.com/crawl_travian:$1
```

### Dockerfile

```Dockerfile
FROM maven:3.8.2-jdk-11

RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y wget \
    zip \
    unzip

ARG CHROME_VERSION=94.0.4606.81-1
ARG CHROME_DRIVER_VERSION=94.0.4606.41

#Step 2: Install Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
	&& echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
	&& apt-get update -qqy \
	&& apt-get -qqy install google-chrome-stable=$CHROME_VERSION \
	&& rm /etc/apt/sources.list.d/google-chrome.list \
	&& rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
	&& sed -i 's/"$HERE\/chrome"/"$HERE\/chrome" --no-sandbox/g' /opt/google/chrome/google-chrome

#Step 3: Install chromedriver for Selenium
RUN wget -q -O /tmp/chromedriver.zip https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \
	&& unzip /tmp/chromedriver.zip -d /opt \
	&& rm /tmp/chromedriver.zip \
	&& mv /opt/chromedriver /opt/chromedriver-$CHROME_DRIVER_VERSION \
	&& chmod 755 /opt/chromedriver-$CHROME_DRIVER_VERSION \
	&& ln -s /opt/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

COPY target/crawl-travian-1.jar crawl-travian.jar
RUN chmod 777 crawl-travian.jar
ENTRYPOINT ["java","-jar","/crawl-travian.jar"]
```

### Docker-compose

```yml
version: '3.8'
services:
  crawl-app:
    image: 168146697673.dkr.ecr.ap-southeast-1.amazonaws.com/crawl_travian:latest
    environment:
      - _JAVA_OPTIONS=-Xmx1800m -Xms256m
      - SPRING_PROFILES_ACTIVE=prod
      - MANAGEMENT_METRICS_EXPORT_PROMETHEUS_ENABLED=true
      - SPRING_DATASOURCE_URL=jdbc:mysql://crawl-mysql:3306/crawl_travian?useUnicode=true&characterEncoding=utf8&useSSL=false&useLegacyDatetimeCode=false&serverTimezone=UTC&createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true
      - SPRING_LIQUIBASE_URL=jdbc:mysql://crawl-mysql:3306/crawl_travian?useUnicode=true&characterEncoding=utf8&useSSL=false&useLegacyDatetimeCode=false&serverTimezone=UTC&createDatabaseIfNotExist=true&allowPublicKeyRetrieval=true
    ports:
      - 8080:8080
  crawl-mysql:
    image: mysql:8.0.26
    volumes:
      - /home/tungtv/workplace/volume/crawl_travian_local/:/var/lib/mysql/
    environment:
      - MYSQL_ROOT_PASSWORD=tung2021@
      - MYSQL_DATABASE=crawl_travian
    ports:
      - 3306:3306
    command: mysqld --lower_case_table_names=1 --skip-ssl --character_set_server=utf8mb4 --explicit_defaults_for_timestamp
```

## DEMO
- [SourceCode](https://github.com/tungtv202/crawl-travian)
![HomePage](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/crawl_travian/home_page.png)
![Chart page](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/crawl_travian/user_follow_detail.png)
![Crawl Log](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/crawl_travian/crawl_log.png)

