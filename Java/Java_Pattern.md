---
title: Java - Design Pattern
date: 2021-08-04 00:05:26
updated: 2022-03-06 02:38:26
tags:
    - java
    - pattern
    - design pattern
    - proxy
    - decorator
    - bridge
    - adapter
    - command
    - observer
category: 
    - java
---

## Proxy vs Decorator pattern

### Similarities

- Structure - both patterns forms a wrapper over real object
- Syntax - in both patterns, a wrappers' entity class is created that implements the same interface as that of the real
  entity class

### Differences

1. Intention

- Decorator Pattern - wraps entity and adds new functionality to it
- Proxy Pattern - wrap entity and restricts direct access to that entity, for security or performance or remote access

2. Usability

- Decorator pattern allows to consume both decorator and original entity whereas Proxy pattern allows consuming only
  proxy class and must completely restrict the direct access to original entity.

3. Instantiation Technique

- Decorator Pattern - can instantiate the original object or can accept the instance to decorate from consumer (via
  constructor)
- Proxy Pattern - can not accept original instance from consumer since original object is abstraction for a consumer via
  Proxy. Hence, proxy internally instantiates the original object.

4. The delegate’s lifecycle

- Some `keyword context`:
    - `Aggregation`: when the child class `CAN` exist independently of the parent class. Example: (Car vs Wheel, When
      there is no car object, the wheels can still exist (maybe for truck))
    - `Composition`: when the child class `CANNOT` exist independently of the parent class. Example: A Library class has a
      set of Accounts. When remove A Library, the Accounts cannot stand on their own.
- Decorator: The delegate is not owned by the decorator, and thus it is an `aggregate`.
- Proxy: The delegate does not exist without the proxy, it is a `composite` of the proxy.

## Adapter Pattern

- Decrease the dependency between abstraction vs implementation
- Decrease the child class

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


## Template method

### Code example

```java
abstract public class AbstractQuery {
    static int id = 0;

    public Result getResult() {
        // todo some thing
        return new Result(id++, generateName());
    }

    abstract protected String generateName();
}

@AllArgsConstructor
class Result {
    long id;
    String name;
}

class EmployeeQuery extends AbstractQuery {

    @Override
    protected String generateName() {
        return "employee 1";
    }
}

class ManagerQuery extends AbstractQuery {
    @Override
    protected String generateName() {
        return "manager 2";
    }
}
```

## Strategy
## Command

![Command pattern](https://gpcoder.com/wp-content/uploads/2018/12/design-patterns-command-diagram.png)

Code example: Undo Redo Document

```java

import java.util.Stack;

// Receiver class - is an object that performs a set of cohesive actions.
class Document {
    private final Stack<String> lines = new Stack<>();

    public void write(String text) {
        lines.push(text);
    }

    public void eraseLast() {
        if (!lines.isEmpty()) {
            lines.pop();
        }
    }

    public void readDocument() {
        System.out.println("---Start reading document");
        lines.forEach(System.out::println);
        System.out.println("---Finish reading document");
    }
}

// Command class - o store all the information required for executing an action
interface Command {
    void undo();

    void redo();
}

class DocumentEditorCommand implements Command {
    private final Document document;
    private final String text;

    public DocumentEditorCommand(Document document, String text) {
        this.document = document;
        this.text = text;
        this.document.write(text);
    }

    @Override
    public void undo() {
        document.eraseLast();
    }

    @Override
    public void redo() {
        document.write(text);
    }
}

// Invoker class - knows how to execute a given command but doesn't know how the command has been implemented
class DocumentInvoker {
    private final Stack<Command> undoCommands = new Stack<>();
    private final Stack<Command> redoCommands = new Stack<>();
    private final Document document = new Document();

    public void undo() {
        if (!undoCommands.isEmpty()) {
            Command cmd = undoCommands.pop();
            cmd.undo();
            redoCommands.push(cmd);
        } else {
            System.out.println("Nothing to undo");
        }
    }

    public void redo() {
        if (!redoCommands.isEmpty()) {
            Command cmd = redoCommands.pop();
            cmd.redo();
            undoCommands.push(cmd);
        } else {
            System.out.println("Nothing to redo");
        }
    }

    public void write(String text) {
        Command cmd = new DocumentEditorCommand(document, text);
        undoCommands.push(cmd);
        redoCommands.clear();
    }

    public void read() {
        document.readDocument();
    }
}

// Client class -  controls the command execution process
public class UndoRedoExample {
    public static void main(String[] args) {
        DocumentInvoker instance = new DocumentInvoker();
        instance.write("The 1st text. ");
        instance.undo();
        instance.read(); // EMPTY

        instance.redo();
        instance.read(); // The 1st text.

        instance.write("The 2nd text. ");
        instance.write("The 3rd text. ");
        instance.read(); // The 1st text. The 2nd text. The 3rd text.
        instance.undo(); // The 1st text. The 2nd text.
        instance.undo(); // The 1st text.
        instance.undo(); // EMPTY
        instance.undo(); // Nothing to undo
    }
}
```

Output 
```
---Start reading document
---Finish reading document
---Start reading document
The 1st text. 
---Finish reading document
---Start reading document
The 1st text. 
The 2nd text. 
The 3rd text. 
---Finish reading document
Nothing to undo
```

## Observer
![Observer Pattern](https://dz2cdn1.dzone.com/storage/temp/14009476-observerdesignpattern.png)

Code example: (keyword: observer weather data)
```java

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.concurrent.TimeUnit;

import lombok.SneakyThrows;

public interface Subject {

    void register(Observer o);

    void remove(Observer o);

    void notifyObservers();
}

interface Observer {
    void update(int temp, int humidity);
}

class WeatherStation implements Subject {
    private final List<Observer> observers;
    private int temp;
    private int humidity;

    public WeatherStation() {
        this.observers = new ArrayList<>();
    }

    @Override
    public void register(Observer o) {
        observers.add(o);
    }

    @Override
    public void remove(Observer o) {
        int observerIndex = observers.indexOf(o);
        if (observerIndex >= 0) {
            observers.remove(o);
        }
    }

    @Override
    public void notifyObservers() {
        observers.forEach(o -> o.update(temp, humidity));
    }

    public void measurementsChanged(int temp, int humidity) {
        this.temp = temp;
        this.humidity = humidity;
        notifyObservers();
    }
}

class CurrentConditionsDisplay implements Observer {

    private int temp;
    private int humidity;

    public CurrentConditionsDisplay(Subject weatherStation) {
        weatherStation.register(this);
    }

    @Override
    public void update(int temp, int humidity) {
        this.temp = temp;
        this.humidity = humidity;
        displayCurrent();
    }

    private void displayCurrent() {
        System.out.println("Current temperature: " + temp);
        System.out.println("Current humidity: " + humidity);
    }
}

class ForecastDisplay implements Observer {
    private final List<Integer> tempHistory;
    private final List<Integer> humidityHistory;

    public ForecastDisplay(Subject weatherStation) {
        tempHistory = new ArrayList<>();
        humidityHistory = new ArrayList<>();
        weatherStation.register(this);
    }

    @Override
    public void update(int temp, int humidity) {
        this.tempHistory.add(temp);
        this.humidityHistory.add(humidity);
        display7DayHistory();
    }

    private void display7DayHistory() {
        System.out.println("Temperature History: " + tempHistory.subList(Math.max(tempHistory.size() - 7, 0), tempHistory.size()));
        System.out.println("Humidity History: " + humidityHistory.subList(Math.max(humidityHistory.size() - 7, 0), humidityHistory.size()));
    }
}

class ObserverDemoMain {
    @SneakyThrows
    public static void main(String[] args) {
        WeatherStation weatherStation = new WeatherStation();
        CurrentConditionsDisplay currentConditionsDisplay = new CurrentConditionsDisplay(weatherStation);
        ForecastDisplay forecastDisplay = new ForecastDisplay(weatherStation);

        // simulate update
        for (int i = 0; i < 5; i++) {
            System.out.println("\n --- Update " + i + " ---");
            int randomTemp = getRandomInt(-50, 40);
            int randomHumidity = getRandomInt(0, 100);
            weatherStation.measurementsChanged(randomTemp, randomHumidity);
            TimeUnit.SECONDS.sleep(1);
        }
    }

    private static int getRandomInt(int min, int max) {
        Random rand = new Random();
        return rand.nextInt(max + 1 - min) + min;
    }
}
```

Output

```
 --- Update 0 ---
Current temperature: 28
Current humidity: 60
Temperature History: [28]
Humidity History: [60]

 --- Update 1 ---
Current temperature: -33
Current humidity: 82
Temperature History: [28, -33]
Humidity History: [60, 82]

 --- Update 2 ---
Current temperature: -39
Current humidity: 9
Temperature History: [28, -33, -39]
Humidity History: [60, 82, 9]

 --- Update 3 ---
Current temperature: 22
Current humidity: 82
Temperature History: [28, -33, -39, 22]
Humidity History: [60, 82, 9, 82]

 --- Update 4 ---
Current temperature: 19
Current humidity: 46
Temperature History: [28, -33, -39, 22, 19]
Humidity History: [60, 82, 9, 82, 46]

Process finished with exit code 0
```
