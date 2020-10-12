---
title: Java - Annotation @GeneratedValue trong JPA  
date: 2018-10-12 18:00:26
tags:
    - java
    - GeneratedValue
    - jpa
category: 
    - java
---


# Annotation @GeneratedValue trong JPA  
## 1. @GeneratedValue là gì?
Là 1 annotation của JPA, được sử dụng để đánh dấu cơ chế (cách thức) sinh ra ID trong database. 
## 2. Vậy có bao nhiêu cơ chế (các thức)?   
Có 4 cơ chế:    
- TABLE
- SEQUENCE
- IDENTITY
- AUTO  

Trong đó:
- TABLE: sử dụng 1 table mặc định, hoặc developer tạo ra để làm cơ chế sinh ra giá trị ID. Hiện tại cơ chế này được khuyến cáo là không nên sử dụng, vì cơ chế này đã cũ, và nó sẽ làm giảm performance của ứng dụng. 
- SEQUENCE: sử dụng 1 sequence mặc định, hoặc developer tạo ra 1 sequence trong database và khai báo, cho columnd ID trong Entity. Từ sequence, developer có thể define được pool ID mà JPA có thể sinh ra, khi insert record vào db.
- IDENTITY: đơn giản, dễ sử dụng nhất, và là cách nhanh nhất để developer tập chung cho business của ứng dụng, mà không cần quan tâm nhiều. Tuy nhiên cơ chế này khuyến cáo là performance chưa thực sự hiệu quả. Khi sử dụng cơ chế IDENTITY, thì giá trị của ID sẽ tự động tăng lên 1 đơn vị cho mỗi lần insert.
- AUTO: tự động lựa chọn 1 trong 3 cơ chế bên trên. 

## 3. Cú pháp, và một số đặc điểm của từng cơ chế   
### 3.1 IDENTITY    
Đơn giản, dễ sử dụng nhất, chỉ cần khai báo 
```java
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;
```
Mặc định giá trị ID của Entity được save vào DB, sẽ là giá trị ID lớn nhất đang có trong database cộng thêm một.    
Có thể để ý query của IDE sinh ra khi chạy với IDENTITY, đó là query insert không truyền vào giá trị ID.    

### 3.2 SEQUENCE
Thường thì khi sử dụng cơ chế SEQUENCE, sẽ phải sử dụng kèm với 1 Anotation khác là @SequenceGenerator.     
Tất nhiên không bắt buộc phải sử dụng kèm anotation này, khi đó JPA sẽ tự động sử dụng 1 sequence default của db. (cái này là mặc định, hoặc developer có thể khai báo).    
Khi sử dụng anotation @SequenceGenerator, sẽ phải quan tâm tới 6 thành phần sau:    
- name
- catalog
- schema
- sequenceName
- initialValue
- allocationSize    


Trong đó: 
- initialValue: là giá trị khởi tạo ban đầu của sequence. Ví dụ có thể khai báo là 10001. Trong khi đó với IDENTITY thì default giá trị khởi tạo ban đầu là 1.  
- allocationSize: là bước nhảy ID cho mỗi lần insert liền kề nhau.  

Cú pháp example:
 
```java
@Id
@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "sequence_gen")
@SequenceGenerator(name = "sequence_gen", sequenceName = "sequence", allocationSize = 2)
private Long id;
```
- sequenceName: tên của table muốn sử dụng. 

### 3.3 TABLE 
- Tương tự như với SEQUENCE, thường đi kèm với anotation @TableGenerator. Vì cơ chế này khuyến cáo không nên sử dụng, nên bài viết sẽ không đi chi tiết.  

### 3.4 AUTO
Đơn giản nhất, không phải khai báo gì

```java
    @Id
    @GeneratedValue
    private Long id;
```
