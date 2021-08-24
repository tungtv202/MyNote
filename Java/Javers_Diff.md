---
title: Java - Javers Diff
date: 2020-01-13 18:00:26
updated: 2020-01-13 18:00:26
tags:
    - java
    - javers
    - diff
category: 
    - java
---

# Javers  - Object auditing and diff framework for Java     
Ref:    
- https://www.baeldung.com/javers     
- https://javers.org/   

Source Code : https://github.com/tungtv202/javerdiff

## 1. Maven

```xml
<dependencies>
        <dependency>
            <groupId>org.javers</groupId>
            <artifactId>javers-core</artifactId>
            <version>3.1.0</version>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <version>1.18.8</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.assertj</groupId>
            <artifactId>assertj-core</artifactId>
            <version>3.13.2</version>
            <scope>compile</scope>
        </dependency>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.13</version>
            <scope>compile</scope>
        </dependency>
    </dependencies>
```

## 2. Code demo

```java
public class JaverDiffTest {

    @Test
    public void givenPersonObject_whenApplyModificationOnIt_thenShouldDetectChange() {
        // given
        Javers javers = JaversBuilder.javers().build();

        Person person = new Person(1, "Michael Program");
        Person personAfterModification = new Person(1, "Michael Java");

        // when
        Diff diff = javers.compare(person, personAfterModification);
        System.out.println(javers.getJsonConverter().toJson(diff));
        // then
        ValueChange change = diff.getChangesByType(ValueChange.class).get(0);

        assertThat(diff.getChanges()).hasSize(1);
        assertThat(change.getPropertyName()).isEqualTo("name");
        assertThat(change.getLeft()).isEqualTo("Michael Program");
        assertThat(change.getRight()).isEqualTo("Michael Java");
    }

    @Test
    public void givenListOfPersons_whenCompare_ThenShouldDetectChanges() {
        // given
        Javers javers = JaversBuilder.javers().build();
        Person personThatWillBeRemoved = new Person(2, "Thomas Link");
        List<Person> oldList =
                Lists.asList(new Person(1, "Michael Program"));
        List<Person> newList =
                Lists.asList(new Person(1, "Michael Not Program"), new Person(3, "new object"));

        // when
        Diff diff = javers.compareCollections(oldList, newList, Person.class);

        // then
        assertThat(diff.getChanges()).hasSize(3);

        ValueChange valueChange = diff.getChangesByType(ValueChange.class).get(0);

        assertThat(valueChange.getPropertyName()).isEqualTo("name");
        assertThat(valueChange.getLeft()).isEqualTo("Michael Program");
        assertThat(valueChange.getRight()).isEqualTo("Michael Not Program");

        ObjectRemoved objectRemoved = diff.getChangesByType(ObjectRemoved.class).get(0);
        assertThat(objectRemoved.getAffectedObject().get().equals(personThatWillBeRemoved))
                .isTrue();

        ListChange listChange = diff.getChangesByType(ListChange.class).get(0);
        assertThat(listChange.getValueRemovedChanges().size()).isEqualTo(1);
    }

    @Test
    public void givenListOfPerson_whenPersonHasNewAddress_thenDetectThatChange() {
        // given
        Javers javers = JaversBuilder.javers().build();

        PersonWithAddress person =
                new PersonWithAddress(1, "Tom", Arrays.asList(new Address("England")));

        PersonWithAddress personWithNewAddress =
                new PersonWithAddress(1, "Tom",
                        Arrays.asList(new Address("England"), new Address("USA")));
        // when
        Diff diff = javers.compare(person, personWithNewAddress);
        List objectsByChangeType = diff.getObjectsByChangeType(NewObject.class);

        // then
        assertThat(objectsByChangeType).hasSize(1);
        assertThat(objectsByChangeType.get(0).equals(new Address("USA")));
    }

}
```

