---
title: Functional Pattern
date: 2021-04-25 18:00:26
tags:
    - java
    - functional
    - pattern
category: 
    - other
---
# Functional Pattern
Groups:
    - Behavioral patterns: strategy, visitor, chain of responsibility, the template method, observer, iterator...
    - Creational patterns:  factory, builder, prototype, the factory method...
    - Structural patterns: adapter, bridge, proxy, decorator...
## The Factory Method Pattern
->  to create an instance of the object
1. We has:
```java
    enum VehicleColor {
            RED,
            BLUE,
            BLACK,
            WHITE
        }
    enum VehicleType {
            CAR,
            BUS,
            TRUCK;
    }

    interface Vehicle {
    }

    @Getter
    @RequiredArgsConstructor
    static class Car implements Vehicle {
        private final VehicleColor color;
    }

    @Getter
    @RequiredArgsConstructor
    static class Bus implements Vehicle {
        private final VehicleColor color;
    }

    @Getter
    @RequiredArgsConstructor
    static class Truck implements Vehicle {
        private final VehicleColor color;
    }
```

2. Legacy 
```java
    public static Vehicle instanceOfType(VehicleType type, VehicleColor color) {
        if (type.equals(VehicleType.CAR)) {
            return new Car(color);
        } else if (type.equals(VehicleType.BUS)) {
            return new Bus(color);
        } else if (type.equals(VehicleType.TRUCK)) {
            return new Truck(color);
        }
        throw new IllegalArgumentException("No support for type " + type);
    }
```
-> 
```java
Vehicle vehicle = instanceOfType(VehicleType.BUS, VehicleColor.BLUE);
```

3. Functional
```java
    enum VehicleType {
        CAR(Car::new),
        BUS(Bus::new),
        TRUCK(Truck::new);

        public final Function<VehicleColor, Vehicle> factory;

        VehicleType(Function<VehicleColor, Vehicle> factory) {
            this.factory = factory;
        }
    }
``` 

->
```java
 Vehicle vehicle = VehicleType.BUS.factory.apply(VehicleColor.RED);
 ```

// The purpose of creating `Function` in enum to avoid forgetting to declare a new case. That maybe get `IllegalArgumentException` if use `legacy` way.

## The Template Method Pattern
->  allows us to define some common steps for an algorithm. Then, the subclasses override some of these steps with their specific behaviors for a particular step

1. We have:
```java
    interface Vehicle {
    }

    static class Bus implements Vehicle {
    }
```

2. Legacy
```java
    abstract class AbstractVehicleLegacy implements Vehicle {
        public void start() {
            preStartCheck();
            System.out.printf("Start AbstractVehicleLegacy %s \n", this.getClass().getSimpleName());
        }

        abstract void preStartCheck();
    }

    public class BusImpl extends AbstractVehicleLegacy {

        @Override
        void preStartCheck() {
            System.out.printf("Start %s \n", this.getClass().getSimpleName());
        }
    }
```
->
```java
        var busImpl = new BusImpl();
        busImpl.start();
```

3. Functional
```java
    interface Vehicle {
        default void start(Consumer<Void> preStartCheck) {
            preStartCheck.accept(null);
            System.out.printf("Start %s \n", this.getClass().getSimpleName());
        }
    }
```
->
```java
        Bus bus = new Bus();
        bus.start(t -> System.out.printf("Start Bus modern \n"));
```

## The Builder Pattern
-> to provide a way of constructing an object in steps, separating the construction logic from its representation.
// Can use `Lombok` to create `Builder` 

## The Strategy Pattern
-> is probably one of the most widely used design patterns; it’s normally used in every situation where we have to choose a different behavior based on some property or input

1. We have
```java
    interface DeliveryCalculator {
        BigDecimal priceFor(Item item);
    }

    @RequiredArgsConstructor
    @Getter
    static class Item {
        private final Integer id;
        private final BigDecimal price;
    }
```

2. Legacy
```java
    class BasicDeliveryCalculator implements DeliveryCalculator {

        @Override
        public BigDecimal priceFor(Item item) {
            return new BigDecimal(1);
        }
    }

    class PremiumDeliveryCalculator implements DeliveryCalculator {

        @Override
        public BigDecimal priceFor(Item item) {
            return new BigDecimal(0.9);
        }
    }
```
->
```java
        DeliveryCalculator factory = new PremiumDeliveryCalculator();
        var price = factory.priceFor(new Item(1, new BigDecimal("9.9")));
```

3. Functional
```java
    enum PLAN_MODERN {
        BASIC(deliveryPriceWithPercentageSurplus("0.025")),
        PREMIUM(deliveryPriceWithPercentageSurplus("0.015")),
        BUSINESS(deliveryPriceWithPercentageSurplus("0.0"));

        public final Function<Item, BigDecimal> deliveryPrice;

        PLAN_MODERN(Function<Item, BigDecimal> deliveryPrice) {
            this.deliveryPrice = deliveryPrice;
        }

        private static Function<Item, BigDecimal> deliveryPriceWithPercentageSurplus(String percentageSurplus) {
            return item -> item.getPrice().multiply(new BigDecimal(percentageSurplus)).add(new BigDecimal("1.0"));
        }
    }
```
-> 
```java
        BigDecimal price = PLAN_MODERN.BASIC.deliveryPrice.apply( new Item(1, new BigDecimal("12.99")));
```
// Is this very similar to `factory method pattern`?

## The Chain-of-Responsibility Pattern


1. We have
```java

    enum WashState {
        INITIAL,
        INITIAL_WASH,
        SOAP,
        POLISHED,
        DRIED
    }

    static class Car {
        private WashState washState;

        public Car() {
            this.washState = WashState.INITIAL;
            System.out.println("Car state transitioned to " + washState);
        }

        public Car updateState(WashState state) {
            System.out.println("Car state transitioned to " + state);
            this.washState = state;
            return this;
        }

        public WashState washState() {
            return washState;
        }
    }

    static abstract class CarWashStep {
        protected CarWashStep nextStep;

        public CarWashStep andThen(CarWashStep nextStep) {
            this.nextStep = nextStep;
            return nextStep;
        }

        abstract Car applyTo(Car car);
    }
```

2. Legacy
```java
    @Test
    public void legacyTest() {
        final Car car = new Car();

        final CarWashStep initialStep = new CarWashStep() {
            @Override
            Car applyTo(Car car) {
                car.updateState(WashState.INITIAL_WASH);
                if (nextStep != null) {
                    return nextStep.applyTo(car);
                }
                return car;
            }
        };

        final CarWashStep dryStep = new CarWashStep() {
            @Override
            Car applyTo(Car car) {
                car.updateState(WashState.DRIED);
                if (nextStep != null) {
                    return nextStep.applyTo(car);
                }
                return car;
            }
        };

        final CarWashStep polishStep = new CarWashStep() {
            @Override
            Car applyTo(Car car) {
                car.updateState(WashState.POLISHED);
                if (nextStep != null) {
                    return nextStep.applyTo(car);
                }
                return car;
            }
        };
        initialStep.andThen(polishStep)
            .andThen(dryStep);

        final Car finalCar = initialStep.applyTo(car);

        System.out.println("Final car state is " + finalCar.washState());
    }
```

3. Functional
```java
    @Test
    public void modernTest() {
        final Car car = new Car();
        Function<Car, Car> initial = c -> new Car();
        final Function<Car, Car> chain = initial
            .andThen(c -> c.updateState(WashState.INITIAL_WASH))
            .andThen(c -> c.updateState(WashState.POLISHED))
            .andThen(c -> c.updateState(WashState.DRIED));
        chain.apply(car);
    }
```

