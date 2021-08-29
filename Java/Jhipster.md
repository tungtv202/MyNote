---
title: Java - Jhipster
date: 2020-04-25 18:00:26
updated: 2020-04-25 18:00:26
tags:
    - java
    - jhipster
    - auto tool
    - gen code
category: 
    - java
---

# JHipster

## 1. Mục đích

Tạo nhanh project java:

- build sẵn CRUD: service + repository + controller + entity
- Tự động generator database = jdl file
- cung cấp giao diện admin CRUD

// Có nét giống với Django Admin Module trong Python

## 2. Install

- Java
- Nodejs (nodejs + npm)
    - Lưu ý về version
    - Khi tạo jhipster project, khi thực hiện command `mvnw`, có thể jhipster sẽ install lại nodejs + npm với version
      khác.
- Install jhipster
    ```
    mkdir myapplication
    cd myapplication/
    jhipster
    # select and install
    ```
- `npm install`

https://www.jhipster.tech/installation/

## 3. Note

- Khi cài đặt jhipster, có thể chọn microservice, hoặc monothinic
- Support reactjs + angularjs
- Support deployment = docker
- Support deployment = kiểu truyền thống, chạy file .jar với profile
- Lưu ý, trong 1 số case, có thể phải tạo proxy, gateway để chạy frontend (reactjs/angularjs) riêng với backend (java)
- Tạo file jdl tại: https://start.jhipster.tech/jdl-studio/
- Run file jdl = command `jhipster import-jdl file.jdl`
- Có thể custom serviceImpl để khi install file `jdl` các code sẽ được tạo ra theo format đã config trước đó (chưa thử)
- Chạy frontend = `npm start`. (code frontend auto hotswap)
- Sử dụng liquibase để detect change database. (`src/main/resources/config/liquibase/master.xml`)
- Dữ liệu mẫu để fake, là file .csv tại: `src/main/resources/config/liquibase/fake-data`
- Cách khai báo file `jdl` quan hệ 1 - nhiều:
```
    entity Blog {
    name String required minlength(3),
    handle String required minlength(2)
    }

    entity Entry {
    title String required,
    content TextBlob required,
    date Instant required
    }

    entity Tag {
    name String required minlength(2)
    }

    relationship ManyToOne {
    Blog{user(login)} to User,
    Entry{blog(name)} to Blog
    }

    relationship ManyToMany {
    Entry{tag(name)} to Tag{entry}
    }

    paginate Entry, Tag with infinite-scroll
 ```
  https://github.com/mraible/jhipster6-demo

- Customize Repository  (Sử dụng trong trường hợp JPA không default sẵn)

```java
    @Query("select p from Product p where p.status =:status and p.fFirstId =:f1Id order by p.createdDate desc")
    Page<Product> findAllByStatusAndFFirstIdOrderByCreatedDateDesc(Pageable pageable, @Param("status") String status, @Param("f1Id") Long f1Id);
    //
    @Modifying(clearAutomatically = true)
    @Query("update Product p set p.fFirstId =:f1Id where p.fSecondId =:f2Id")
    void updateF2(@Param("f1Id") Long f1Id, @Param("f2Id") Long f2Id);
```

- Customize DAOImpl

```java
@Override
    public List<F2summaryDto> getF2SummaryList() {
        String sql = "select " +
            "       f2.id as f2Id,\n" +
            "       f2.name as f2Name,\n" +
            "       f2.url  as f2Url,\n" +
            "       case\n" +
            "           when p_count.counter is null then 0\n" +
            "           else p_count.counter\n" +
            "           end as counter,\n" +
            "       f1.id as f1Id,\n" +
            "       f1.name as f1Name,\n" +
            "       f1.url  as f1Url\n" +
            "from fsecond f2\n" +
            "         left join (select count(*) as counter, f_second_id from product " +
            "   where status = 'new' group by f_second_id) as p_count\n" +
            "                   on p_count.f_second_id = f2.id\n" +
            "         left join ffirst f1 on f2.ffirst_id = f1.id ";
        List<Object[]> queryResult = entityManager.createNativeQuery(sql).getResultList();
        List<F2summaryDto> result = new ArrayList<>();
        queryResult.stream().forEach((record) -> {
            Long f2Id = ((BigInteger) record[0]).longValue();
            String f2Name = (String) record[1];
            String f2Url = (String) record[2];
            int counter = ((BigInteger) record[3]).intValue();
            Long f1Id = ((BigInteger) record[4]).longValue();
            String f1Name = (String) record[5];
            String f1Url = (String) record[6];
            result.add(new F2summaryDto(f2Id, f2Name, f2Url, counter, f1Id, f1Name, f1Url));
        });
        return result;
    }
```

- Trong 1 số trường hợp không muốn chạy app qua proxy (ví dụ reactjs, proxy 9000, 9060). Muốn chạy trực tiếp trên port
  java, cần config security

```text
    // config/SecurityConfiguration.java
    Sửa format `default-src 'self'` thành `default-src *`
```

- Thêm script/css common tại: `src/main/webapp/index.html`
- Config accept Javascript trong reactjs .ts file `.eslintrc.json`

```json
    "rules": {
        "no-console": 0
    }
```