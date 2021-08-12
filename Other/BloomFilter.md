---
title: Bloom Filter
date: 2021-08-12 23:00:26
tags:
    - bloom filter
    - algorithm
    - false positive
    - bf
category: 
    - other
---

# Bloom Filter

## False positive

- If it return `false` => 100% believe
- If it return `true` => Maybe it `really true` or `false` -> Then need using other way to check exactly the result.
- Get benefit when:
    - The entries are very big. 
    - Want to decrease the request to "exactly checking"
    - The percent of probabilistic `false` is very bigger than `true` 

- Use case in the world
    - Google using it to checking account_name is it exists or not when the user registers a new account.


## Understand via code sample

```java

public interface BloomFilter {

    void add(Object object);

    boolean mightContain(Object object);
}

class MyBloomFilter implements BloomFilter {

    private final int[] array;

    MyBloomFilter(int size) {
        this.array = new int[size];
    }

    @Override
    public void add(Object object) {
        int hashPosition = hashObjectAsInt(object);
        array[hashPosition] = 1;
    }

    @Override
    public boolean mightContain(Object object) {
        int hashPosition = hashObjectAsInt(object);
        return array[hashPosition] == 1;
    }

    private int hashObjectAsInt(Object object) {
        int result = object.hashCode();
        // todo. result = Hash object with something algorithm
        Preconditions.checkArgument(0 <= result && result < array.length - 1);
        return result;
    }
}

```

