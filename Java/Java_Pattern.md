---
title: Java Design Pattern
date: 2021-08-04 00:05:26
tags:
    - java
    - pattern
    - design pattern
    - proxy
    - decorator
    - bridge
    - adapter
category: 
    - java
---

## Proxy vs Decorator pattern
### Similarities
- Structure - both patterns forms a wrapper over real object
- Syntax - in both patterns, a wrappers entity class is created that implements the same interface as that of the real entity class 

### Differences
1. Intention 
- Decorator Pattern - wraps entity and adds new functionality to it
- Proxy Pattern - wrap entity and r estricts direct access to that entity, for security or performance or remote access 

2. Usability
- Decorator pattern allows to consume both decorator and original entity whereas Proxy pattern allows to consume only proxy class and must completely restrict the direct access to original entity.

3. Instantiation Technique
- Decorator Pattern - can instantiate the original object or can accept the instance to decorate from consumer (via consutrctor)
- Proxy Pattern - can not accept original instance from consumer since original object is abstraction for a consumer via Proxy. Hence, proxy internally instantiates the original object.

4. The delegate’s lifecycle     
- Some `keyword context`: 
    - `Aggregation`: when the child class `CAN` exist independently of the parent class. Example: (Car vs Wheel, When there is no car object, the wheels can still exist (maybe for truck))
    - `Composition`: when the child class `CANNOT` exist independtly of the parent class. Example: A Library class has a set of Accounts. When remove A Library, the Accounts cannot stand on their own.
- Decorator: The delegate is not owned by the decorator and thus it is an `aggregate`.
- Proxy: The delegate does not exist without the proxy, it is a `composite` of the proxy.

## Adapter Pattern

### Code Example

```java
interface WebDriver {
    void getElement();

    void selectElement();
}

class ChromeDriver implements WebDriver {
    @Override
    public void getElement() {
        System.out.println("Get element from ChromeDriver");
    }

    @Override
    public void selectElement() {
        System.out.println("Select element from ChromeDriver");
    }
}

class IEDriver {
    public void findElement() {
        System.out.println("Find element from IEDriver");
    }

    public void clickElement() {
        System.out.println("Click element from IEDriver");
    }
}

class IEWebDriverAdapter implements WebDriver {
    final IEDriver ieDriver;

    IEWebDriverAdapter(IEDriver ieDriver) {
        this.ieDriver = ieDriver;
    }

    @Override
    public void getElement() {
        ieDriver.findElement();
    }

    @Override
    public void selectElement() {
        ieDriver.clickElement();
    }
}

public class AdapterPatternExample {
    public static void main(String[] args) {
        IEDriver ieDriver = new IEDriver();
        WebDriver webDriverViaAdapter = new IEWebDriverAdapter(ieDriver);
        WebDriver webDriverViaChromeDriver = new ChromeDriver();
    }
}
```

## Bridge Pattern 

### Code Example
![BridgePattern](https://refactoring.guru/images/patterns/diagrams/bridge/example-en.png)

- Device

```java
abstract class EntertainmentDevice {
    public int deviceState;
    public int maxSetting;
    public int volumeLevel = 0;

    public abstract void buttonFivePressed();

    public abstract void buttonSixPressed();

    public void deviceFeedback() {
        if (deviceState > maxSetting || deviceState < 0) {
            deviceState = 0;
        }
        System.out.println("On " + deviceState);
    }

    public void buttonSevenPressed() {
        volumeLevel++;
        System.out.println("Volume at: " + volumeLevel);
    }

    public void buttonEightPressed() {
        volumeLevel--;
        System.out.println("Volume at: " + volumeLevel);
    }
}

class TVDevice extends EntertainmentDevice {

    public TVDevice(int newDeviceState, int newMaxSetting) {
        deviceState = newDeviceState;
        maxSetting = newMaxSetting;
    }

    @Override
    public void buttonFivePressed() {
        System.out.println("Channel Down");
        deviceState--;
    }

    @Override
    public void buttonSixPressed() {
        System.out.println("Channel Up");
        deviceState++;
    }
}

class DVDDevice extends EntertainmentDevice {

    @Override
    public void buttonFivePressed() {
        //todo
    }

    @Override
    public void buttonSixPressed() {
        //todo
    }
}
```

- Button

```java
abstract class RemoteButton {
    private final EntertainmentDevice theDevice;

    public RemoteButton(EntertainmentDevice device) {
        theDevice = device;
    }

    public void buttonFivePressed() {
        theDevice.buttonFivePressed();
    }

    public void buttonSixPressed() {
        theDevice.buttonSixPressed();
    }

    public void deviceFeedback() {
        theDevice.deviceFeedback();
    }

    public abstract void buttonNinePressed();

}

class TVRemoteMute extends RemoteButton {

    public TVRemoteMute(EntertainmentDevice device) {
        super(device);
    }

    @Override
    public void buttonNinePressed() {
        System.out.println("TV was Muted");
    }
}

class TVRemotePause extends RemoteButton {

    public TVRemotePause(EntertainmentDevice device) {
        super(device);
    }

    @Override
    public void buttonNinePressed() {
        System.out.println("TV was Paused");
    }
}
```

- Test

```java
public class Test {
    public static void main(String[] args) {
        RemoteButton theTV = new TVRemoteMute(new TVDevice(1, 200));
        RemoteButton theTV2 = new TVRemotePause(new TVDevice(1, 200));
//        RemoteButton theDVD = new DEVRemote(new DVDDevice(1,14));

        System.out.println("Test TV with Mute");
        theTV.buttonFivePressed();
        theTV.buttonSixPressed();
        theTV.buttonNinePressed();

        System.out.println("\nTest TV with Pause");
        theTV2.buttonFivePressed();
        theTV2.buttonSixPressed();
        theTV2.buttonSixPressed();
        theTV2.buttonSixPressed();
        theTV2.buttonSixPressed();
        theTV2.buttonNinePressed();
        theTV2.deviceFeedback();
    }
}
```

Output

```
Test TV with Mute
Channel Down
Channel Up
TV was Muted

Test TV with Pause
Channel Down
Channel Up
Channel Up
Channel Up
Channel Up
TV was Paused
On 4
```


