---
title: Jackson - Deserialize Abstract class
date: 2019-12-21 18:00:26
updated: 2019-12-21 18:00:26
tags:
    - serialize
    - java
    - jackson
category: 
    - java
    - jackson
---

# Sử dụng Jackson để deserialize abstract class 
# Inheritance with Jackson
Tham khảo: https://www.baeldung.com/jackson-inheritance

## 1. Code mẫu
### Abtract class

```java
@Getter
@Setter
@JsonTypeInfo(
        use = JsonTypeInfo.Id.NAME,
        include = JsonTypeInfo.As.PROPERTY,
        property = "type2")
@JsonSubTypes({
        @JsonSubTypes.Type(value = Car.class, name = "car"),
        @JsonSubTypes.Type(value = Truck.class, name = "truck")
})
public abstract class Vehicle {
    private String make;
    private String model;

    protected Vehicle(String make, String model) {
        this.make = make;
        this.model = model;
    }

    public Vehicle() {
    }
}
```

### Child class

```java
@Getter
@Setter
public class Car extends Vehicle {
    private int seatingCapacity;
    private double topSpeed;

    public Car(String make, String model, int seatingCapacity, double topSpeed) {
        super(make, model);
        this.seatingCapacity = seatingCapacity;
        this.topSpeed = topSpeed;
    }

    public Car(String make, String model) {
        super(make, model);
    }

    public Car(){
    }
}
```

```java
@Getter
@Setter
public class Truck extends Vehicle {
    private double payloadCapacity;

    public Truck(String make, String model, double payloadCapacity) {
        super(make, model);
        this.payloadCapacity = payloadCapacity;
    }

    public Truck(){
    }
}
```
### using class

```java
@Getter
@Setter
public class Fleet {
    //    private List<Vehicle> vehicles;
    private Vehicle vehicle;
}
```
### demo

```java
public static void main(String[] args) throws IOException {
        ObjectMapper mapper = new ObjectMapper();
//        mapper.enableDefaultTyping();
        mapper.configure(SerializationFeature.INDENT_OUTPUT, true);

        Car car = new Car("Mercedes-Benz", "S500", 5, 250.0);
        Truck truck = new Truck("Isuzu", "NQR", 7500.0);

//        List<Vehicle> vehicles = new ArrayList<>();
//        vehicles.add(car);
//        vehicles.add(truck);

        Fleet serializedFleet = new Fleet();
        serializedFleet.setVehicle(car);

        String jsonDataString = mapper.writeValueAsString(serializedFleet);
        System.out.println(jsonDataString);

        Fleet fleet = mapper.readValue(jsonDataString, Fleet.class);
        System.out.println("Car ? " + (fleet.getVehicle() instanceof Car));
        System.out.println("Truck ? " + (fleet.getVehicle() instanceof Truck));
    }
```

output:

```json
{
  "vehicle" : {
    "type2" : "car",
    "make" : "Mercedes-Benz",
    "model" : "S500",
    "seatingCapacity" : 5,
    "topSpeed" : 250.0
  }
}
```

## 2. Lưu ý
- Trường hợp nếu CÓ khai báo `mapper.enableDefaultTyping();` thì class `Vehicle` không cần khai báo các `@JsonTypeInfo` và `@JsonSubTypes` 
- Lưu ý khai báo `property = "type2"` trường này sẽ quyết định xác định class con nào được deserialize
