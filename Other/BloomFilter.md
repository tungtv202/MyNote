---
title: Bloom Filter
date: 2021-08-12 23:00:26
updated: 2021-08-12 23:00:26
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

- If it returns `false` => 100% believe
- If it returns `true` => Maybe it `really true` or `false` -> Then need using other way to check exactly the result.
- Get benefit when:
  - The entries are very big.
  - Want to decrease the request to "exactly checking"
  - The percent of probabilistic `false` is very bigger than `true`

- Use case in the world
  - Google using it to checking account_name is it exists or not when the user registers a new account.

## Understand via code sample

```java
import java.util.BitSet;

public interface BloomFilter {

  void add(Object object);

  boolean mightContain(Object object);
}

class MyBloomFilter implements BloomFilter {

  private static final int DEFAULT_SIZE = 1000;  // Default bit array size
  private static final int[] HASH_SEEDS = {7, 11, 13, 31, 37, 61};  // Seed values for multiple hash functions
  private final BitSet bitSet;  // Bit array to store hashed values
  private final int size;  // Size of the bit array

  MyBloomFilter() {
    this(DEFAULT_SIZE);  // Initialize with default size if no size is provided
  }

  MyBloomFilter(int size) {
    this.size = size;  // Set the bit array size
    this.bitSet = new BitSet(size);  // Initialize the bit array
  }

  @Override
  public void add(Object object) {
    for (int seed : HASH_SEEDS) {  // Apply each hash function
      int hashPosition = hashObject(object, seed);  // Get the bit position from the hash
      bitSet.set(hashPosition);  // Set the bit at the calculated position
    }
  }

  @Override
  public boolean mightContain(Object object) {
    for (int seed : HASH_SEEDS) {  // Check each hash function
      int hashPosition = hashObject(object, seed);  // Get the bit position from the hash
      if (!bitSet.get(hashPosition)) {  // If any bit is not set, the object is definitely not in the set
        return false;
      }
    }
    return true;  // If all bits are set, the object might be in the set
  }

  private int hashObject(Object object, int seed) {
    int result = object.hashCode() ^ seed;  // Combine the object's hash code with the seed
    result = (result & 0x7fffffff) % size;  // Ensure the hash is within bounds of the bit array
    return result;
  }

  public static void main(String[] args) {
    BloomFilter bloomFilter = new MyBloomFilter();

    bloomFilter.add("Hello");
    bloomFilter.add("World");

    System.out.println(bloomFilter.mightContain("Hello")); // true
    System.out.println(bloomFilter.mightContain("Java")); // false
  }
}
```

Summary:
- `DEFAULT_SIZE`: Controls the size of the bit array, affecting memory usage and false positive rate.
- `HASH_SEEDS`: Provides multiple seeds for hashing, simulating multiple hash functions.
- `bitSet`: Efficiently stores the set bits after hashing.
- `size`: Defines the length of the bit array, ensuring hash values are within bounds.

