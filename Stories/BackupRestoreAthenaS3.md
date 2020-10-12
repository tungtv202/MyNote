---
title: Stories - Query SQL on S3
date: 2020-04-20 18:00:26
tags:
    - s3
    - query sql
category: 
    - stories
---

# Nhật ký tìm giải pháp "query sql" trên object storage.
Tôi đang xây dựng 1 feature, cho phép user có thể backup/restore dữ liệu của họ. 
Trong đó dữ liệu của họ là RDBMS SQL.
Giải pháp sẽ là query sql theo userId, sau đó export ra 1 file data. (.csv chẳng hạn) rồi upload nó lên S3. 
Sẽ có 1 db log lại ví trí của object file trên S3, hoặc là đường dẫn được tạo theo 1 công thức nào đó. Và khi nào restore thì sẽ get data xuống. Để thực thi nghiệp vụ business.

Vấn đề duy nhất làm tôi hứng thú với bài toán này, đó là tôi cần 1 cái gì đó "understand" được data mà tôi lưu trên S3. 
Ban đầu tôi nghĩ ngay tới AWS Athena. Vì tôi đã từng đọc đâu đó, Athena cho phép query sql trực tiếp trên S3 luôn. 
Tôi trông đợi rằng sẽ có 1 cơ chế hay ho nào đó giữa Athena và S3. Và application của tôi, sẽ gọi tới các API của Athena.
Tôi không muốn application của mình phải xử lý việc File IO. Và nhất là tôi không muốn việc sẽ phải download file trên S3 về. (file csv chẳng hạn), rồi sau đó parse nó ra để lấy list object. 
tôi muốn lấy ra list object qua api luôn. Tôi muốn stream nó.

Thật đáng tiếc, sau khi tìm hiểu về AWS Athena, thì tôi thấy nó không phù hợp cho case của tôi. Athena hợp để analysic cho các file data lớn thôi. Tuy nhiên, lúc đó, tôi vẫn muốn cố đấm ăn xôi. Tôi lăn tăn suy nghĩ. Liệu dùng dao mổ trâu, để mổ chim sẻ có nên không?
Suy nghĩ cuối cùng dập tắt. Khi phát hiện ra rằng, Athena chỉ cho phép tạo max 100 database / account. Và với ý đồ của tôi từ đầu, thì nó đã fail. Không thể mỗi 1 file csv tạo ra, lại có 1 database được. Ngoài ra còn các hạn chế khác như: chỉ 5 query được chạy concurrent time. :(

Tôi tìm thấy rất nhiều keyword trên mạng về Apache Drill. Nhưng nó thì không phải là serverless, nên nó đã bị loại. Trong quá trình tìm hiểu, thì tôi phát hiện ra, có 1 mảng keyword trong lĩnh vực này. Người ta cần 1 cái enginer để có thể query được các object storage. 
PrestoDB, AVRO, Parquet...
Đây là 1 vấn đề lớn, các ông lớn Facebook, google, aws đều đang sử dụng 1 cái "nhân" nào đó cho cái vấn đề này.
Có lẽ tương lai, nếu có duyên, tôi sẽ quay lại tìm hiểu nó.

Cuối cùng thì tôi tìm ra S3 Select, nó khá phù hợp với cái tôi cần. Có điều S3 select nó không thể query lấy data tại vị trí offset chỉ định được. 
Ví dụ như: file csv của tôi có 1000 row. Tôi muốn lấy 500 row cho mỗi request API. Và S3 Select không hỗ trợ việc chỉ định offset cho query. 

Tuy nhiên, có thể customize lại 1 tý, bằng cách khi tạo ra file csv, tôi sẽ tạo thêm 1 column là NumberSequence. Và khi api query get list object. tôi sẽ thêm điều kiện như `WHERE 501 < NumberSequence  <1000`

S3 select có những limit về dung lượng của input, output. Nếu tính toán 1 cách chi li, 1 row có bao nhiêu column, mỗi column max bao nhiêu byte. Chắc sẽ ra. 
Nhưng nó sẽ không chắc chắn tuyệt đối. Nên thôi, sẽ xử lý logic ở code, mỗi query lấy N row cho nhanh.