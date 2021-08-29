---
title: Nhật ký xây dựng app Backup & Restore
date: 2020-12-28 00:39:26
updated: 2020-12-28 00:39:26
tags:
    - backup restore
category: 
    - stories
---

# Bài toán

- Xây dựng ứng dụng phục vụ việc sao lưu & khôi phục dữ liệu.
- Đối tượng cần sao lưu: dữ liệu của khách hàng được chứa trên hệ thống X. Việc lấy dữ liệu (backup) & chỉnh sửa dữ
  liệu (restore) được thực hiện qua Restful API
- Người thực hiện thao tác ứng dụng: khách hàng của hệ thống X
- Format dữ liệu khi lấy từ hệ thống X về: `json`
- Mỗi khách hàng chủ động lịch định kỳ `sao lưu ` và tự ` khôi phục ` khi khách hàng muốn

## Một số đặc thù kỹ thuật

- Authen/author tới hệ thống X là `oauth`. App sao lưu cần xin quyền trước.
- App tự động backup dữ liệu theo lịch cấu hình của từng khách hàng. Hoặc thực hiện backup dữ liệu ngay lập tức khi
  khách hàng request.

# Thiết kế

## 10/06/2020

- Sử dụng `OpenFeign` (FeignClient) để wrap việc call http api từ App tới hệ thống X. Vì api get data tới hệ thống X có
  giới hạn số record trả về trên 1 request. mình quyết định viết ra 1 method parallel gồm 2 bước chính:
    - call api lần thứ 1 để lấy ra total record => tính toán ra tổng số M request api cần call để có thể lấy được hết dữ
      liệu.
    - Sử dụng `CompletableFuture` cho chạy song song M request cùng lúc

```java
//code example
public ProductList getAllProduct(int storeId, String createdOnMax) throws ExecutionException, InterruptedException {
        final var totalProductResult = productClient.getTotalCount(storeId, createdOnMax, authen);
        final var totalProduct = totalProductResult.getCount();

        final int totalPage = (int) Math.ceil((double) totalProduct / Constants.BACKUP_CLIENT_LIMIT);

        List<CompletableFuture<ProductList>> listAsync = new ArrayList<>();
        for (int i = 1; i <= totalPage; i++) {
            listAsync.add(clientAsyncGetProduct(storeId, i, createdOnMax));
        }
        CompletableFuture<Void> allAsync = CompletableFuture
                .allOf(listAsync.toArray(new CompletableFuture[listAsync.size()]));

        CompletableFuture<List<ProductList>> allClientAsync = allAsync.thenApply(v -> {
            return listAsync.stream().map(CompletableFuture::join)
                    .collect(Collectors.toList());
        }).exceptionally(ex -> {
            try {
                throw new Exception(ex.getMessage());
            } catch (Exception e) {
                e.printStackTrace();
            }
            return null;
        });

        var resultList = allClientAsync.get();
        var result = new ProductList();
        resultList.forEach(result::addAll);
        return result;
    }
```

- Queue: sử dụng Kafka (sau này mình đã chuyển sang RabbitMQ). Lý do ban đầu chọn Kafka đơn giản chỉ vì t nghĩ cần 1 hệ
  thống message queue để chạy job backup/restore. Nên là thằng nào cũng được. Nhưng vì sau này hiểu sâu hơn về cơ chế
  hoạt động Kafka, mình nhận ra t việc lựa chọn nó là không phù hợp. Về cơ bản tư tưởng mình sử dụng 3 queue:
    - queue cho việc backup auto
    - queue cho việc backup manual
    - queue cho việc restore
- Backup mình tách ra làm 2 queue, đơn giản chỉ là muốn các queue mà người dùng request sẽ có 1 kênh riêng, có ưu tiên
  hơn. Sau này chuyển sang rabbitMQ thì rabbitmq có hỗ trợ priority, tuy nhiên do kiến trúc code cũ, nên mình vẫn giữ
  việc độc lập này.
- Nơi lưu trữ dữ liệu backup: AWS S3. Ban đầu mình có suy nghĩ tới việc backup dữ liệu sang 1 database rdbms khác. Tuy
  nhiên ban đầu bài toán là muốn dữ liệu được lưu trữ ở 1 nơi nào đó `an toàn ` hơn. Đã gọi là backup/restore thì nó
  được dùng cho case nguy hiểm rồi. Với cả mình cũng chưa thấy được lợi ích gì nổi bật hơn giữa việc lựa chọn S3 hay
  Rdbms. Mình dự định file backup sẽ là 1 file data gì đó (csv, excel, json...), nếu sau này kiểu khách hàng cần
  download file thì cũng tiện hơn. Cuối cùng mình chốt sử dụng file csv. Một phần cũng vì ban đầu tìm hiểu thấy S3 hỗ
  trợ query select trực tiếp từ file csv. (cho tới thời điểm hiện tại thì cũng chưa khai thác được tính năng này)
    - Khi sử dụng S3, mình cũng áp dụng parallel giống như `OpenFeign` bên trên.
    - S3 không hỗ trợ việc copy object 1 cách `bulk/batch`. Nên phải request từng object 1. Và thêm 1 cái dở là nếu
      request quá nhanh thì sẽ bị AWS chặn lại. => hơi tù.
- Quartz: để phục vụ cho mục đích là mỗi khách hàng tự cấu hình lịch backup data của họ, mình sử dụng Quartz. Nếu như mà
  tất cả khách hàng đều có lịch backup giống nhau, mình sẽ sử dụng Spring schedule, hoặc cronjob, nó sẽ đơn giản hơn rất
  nhiều. Để implement quartz phức tạp hơn, nó có database riêng. Thậm chí với bài toán hệ thống lớn, có thể sẽ phải
  thiết kế 1 cluster riêng cho nó với nhiều node. Quartz này mình sử dụng loại schedule là `cron Expression`.
- OpenCSV: mỗi file backup sẽ được lưu trữ trong file csv. Vì sợ dữ liệu sẽ bị lỗi unicode, nên mình quyết định encode
  base64 thông tin json, trước khi lưu vào csv.

```java
@Getter
@Setter
@AllArgsConstructor
public class BackupCsv {

    @CsvBindByName(column = "NO")
    public int rowNo;

    @CsvBindByName(column = "OBJECT_ID")
    public int objectId;

    @CsvBindByName(column = "DATA")
    public String data;

    public BackupCsv() {
    }
}
```

### Database

- `BackupLogs`
  ![BackupLogs](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/BackupLogs.png)
- `BackupLogDetails`
  ![BackupLogDetails](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/BackupLogDetails.JPG)
  Mình tách độc lập ra 2 bảng. BackupLogs lưu trữ thông tin tổng của 1 `request` backup. Nó chứa thông tin tên của bản
  backup, nguồn gốc, status tổng... Trong khi bảng `detail`, sẽ chứa chi tiết từng hạng mục backup riêng (product,
  collection, customer...vvv). Queue được thiết kế sử dụng cho layer detail này.(tới thời điểm hiện tại, mình nghĩ có
  thể queue thiết kế ở layer BackupLog cũng được)
- `Media`
  ![Media](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/Media.JPG)
- `MediaDependencyLogs`
  ![MediaDependencyLogs](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/MediaDependencyLogs.JPG)
  Có 1 vấn đề đặt ra là dữ liệu khi được lưu trữ trên CloudStorage, thì mình nên giảm tỉ lệ việc duplicated dữ liệu. Ví
  dụ khi backup data product, và product P111, có chứa thông tin link ảnh cdn media. Vậy ngày hôm nay khi backup dữ
  liệu, ngoài việc backup các thông tin cơ bản trong json, thì mình cũng cần backup thêm cả dữ liệu file media kia nữa.
  Vậy nếu ngày mai backup data tiếp, việc lại thực hiện backup file media 1 lần nữa là không cần thiết. Vì file cdn ảnh
  không hề thay đổi. Việc duplicated dữ liệu file media này sẽ tốn thêm rất nhiều cost storage. Vì thế nên 2 table:
  Media, MediaDependencyLogs ra đời, mục đích để lưu lại các metadata này.
- `RestoreLogs`
  ![RestoreLogs](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/RestoreLog.JPG)
- `RestoreLogDetails`
  ![RestoreLogDetails](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/RestoreLogDetails.JPG)
- `RestoreErrorLogs`
  ![RestoreErrorLogs](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/RestoreErrorLogs.JPG)
  Tương tự như chiều Backup, thì chiều Restore các table cũng được thiết kế tương ứng. Việc restore này tương đối nguy
  hiểm, vì có thể sẽ làm sai lệch dữ liệu của khách hàng không như ý muốn. Nên với mỗi lệnh Restore, sẽ cần thực hiện
  lệnh backup toàn bộ data trước đó. (column `BackupLogIdDisasterHelper`). Và có thêm table `RestoreErrorLogs` để rõ
  ràng hơn trong việc xác định lỗi.

## 16/06/2020

- App gồm 2 phần, frontend giao diện, và service. 2 phần này chạy độc lập với nhau. Cũng không có lý do gì đặc biệt cho
  lựa chọn này. Frontend sử dụng reactjs. Service dùng java. 2 thành phần này được container độc lập. Vậy nên bài toán
  cần 1 cơ chế authen từ reactjs (client) tới service. => Quyết định lựa chọn sử dụng JWT
- Vậy việc cấp token jwt diễn ra như thế nào?
    - Đầu tiên user cần login vào hệ thống X. Từ hệ thống X user truy cập vào app. Giữa hệ thống X và app có 1 cơ chế
      authen riêng. là `oauth`. 2 bên đã trao đổi vs nhau 1 secretkey trước đấy. Khi hệ thống X redirect về app sẽ
      truyền theo thông tin, kèm hmac. App sẽ dùng secretkey để validate thông tin. Và redirect về reactjs kèm theo
      token jwt.
    - Reacjts dùng jwt lưu vào session/local storage của browser, và sử dụng nó để call tới service lấy thông tin.

## 01/07/2020

- Bộ Garbage Cleaner ra đời. Lấy ý tưởng từ bộ GC của java. Mình đặt tên class cũng là `GarbageCleanerStrategy`. Bộ GC
  của mình này có nhiệm vụ là dọn dẹp dữ liệu trên hệ thống cloud storage (s3). Như đã đề cập, mình sử dụng 2
  table `Media` và `MediaDependencyLogs` để lưu metadata các dữ liệu file media trên json. Vậy bài toán là khi file
  media không còn được `reference` tới bất kỳ bản backupLog nào nữa. Thì mình cần phải xóa chúng đi trên S3.
    - Với các file backup với origin=AUTO, MANUAL sẽ có "chiến lược" khác với file backup có origin=BEFORE_RESTORE
    - cần đảm bảo transaction tuyệt đối ở đây. Chỉ khi nào file media trên cloudstorage bị xóa thành công, thì mới thực
      hiện update db tương ứng.
    - Bộ GC này chạy async, và độc lập. Được trigger khi có 1 backupLog bị xóa.

## 07/07/2020

- Vấn đề đặt ra khi user trên hệ thống X không còn `active` nữa. Nhưng job backup của user này theo quartz vẫn chạy định
  kỳ, dẫn tới việc backup dữ liệu là vô nghĩa. => cần có cơ chế để hủy job backup. Rất may là hệ thống X có hỗ trợ sẵn
  điều này. Chỉ cần đăng ký webhook với hệ thống X. và lắng nghe chúng. Khi có webhook từ hệ thống X gửi tới App và báo
  user đã bị inactive, thì cấu hình cron job trên quartz của user đó sẽ bị hủy bỏ.
    - Hiện tại thì chưa có cơ chế xóa toàn bộ dữ liệu liên quan nếu user inactive. (chưa xác định được thực sự khi nào
      cần xóa)
    - việc lắng nghe webhook này là 1 giải pháp mình thấy có độ tin tưởng không được tuyệt đối. Về lâu dài, sẽ dẫn tới
      sự thiếu nhất quán dữ liệu giữa App và X
    - bổ sung thêm việc handler lỗi khi app call API tới hệ thống X mà gặp lỗi. Ví dụ lỗi 401, thì cũng sẽ trigger việc
      hủy chạy quartz.

## 12/07/2020

- Implement Redis: phía client cần biết được progress (%) của tiến trình backup/restore. Mình quyết định tích hợp Redis
  cho feature này. Với mỗi task backup/restore dữ liệu. Mình tự đặt ra quy ước, khi hoàn thành xong 1 phần nào đó, thì
  sẽ append kết quả vào redis. Đồng thời viết ra 1 api controller, để client call vào đó lấy progress statistic. Khi
  client call vào api, thì tầng service sẽ get value từ redis và trả về cho client.
    - Client lấy thông tin progress này bằng cách interval call api. Điều này làm mình không hài lòng lắm. Mình muốn
      implement socket. Nhưng tới h vẫn chưa có effort làm.
    - Việc get value từ redis sẽ giúp giảm tải tới hệ thống hơn

## 13/07/2020

- Big refactor: chuyển từ Kafka sang RabbitMQ. Sau quá trình tìm hiểu và thực tế sử dụng, nhận thấy kafka không hợp với
  case của mình.
    - Khi các job chạy bị lâu tốn nhiều thời gian, kafka client bắt đầu throw ra lỗi, hoặc log báo là message được
      rebalance sang consumer khác. Điều này thực sự không phải là vấn đề chính của quyết định chuyển sang RabbitMQ.
      Nhưng để handler nó, mình thấy tốn nhiều công sức tìm hiểu, và cuối cùng vẫn không tự tin rằng đã control được nó.
      Nhưng về lý thuyết thì mình chỉ cần commit msg cho kafka ngay khi nhận được msg thôi. Chứ không cần phải đợi chạy
      xong job mới commit msg. Mình không có ý định sử dụng queue retry gì nhiều hơn ở đây. Đã thất bại việc chạy job là
      thất bại, Muốn retry thì con người phải manual lại nó. Mình cũng đã có các table để log lại các job rồi. Nên không
      mong đợi gì nhiều hơn ở Kafka nữa
    - Khi chạy job, việc sử dụng kafka bị hạn chế việc scale. Giả sử mình sử dụng 10 partition cho 1 topic. Vậy thì mình
      chỉ có thể scale tối đa 10 consumer cùng lúc. Đây là lý do chính

## 03/08/2020

- Leaky Bucket: việc call api từ App tới hệ thống X bị hạn chế. Hệ thống X chỉ cho phép call N api trong khoảng X giây.
  => Nếu việc backup/restore mà mình cho call api paralell quá nhanh, thì sẽ gặp lỗi ở đây.
    - Sử dụng thư việc Xsync để intercepter và synchonize việc sleep request.
    ```xml
            <dependency>
                <groupId>com.antkorwin</groupId>
                <artifactId>xsync</artifactId>
                <version>1.1</version>
            </dependency>
    ```
    - Đây là 1 giải pháp không triệt để. Hiện tại app chỉ chạy vs 1 instance. Nhưng nếu scale lên, thì cần có 1 middle
      trung gian cho việc này. Ví dụ 1 proxy riêng. Hoặc là dùng redis để counter.
    - Cũng may do việc sử dụng OpenFeign, nên interceptor tương đối nhẹ nhàng hơn.
    ```java
     public void timeWaitLimit(String storeAlias) {
        xSync.execute(storeAlias, () -> {
            LeakyBucketModel model = BucketLeakyStatic.get(storeAlias);
            if (model == null) {
                BucketLeakyStatic.put(storeAlias, new LeakyBucketModel(bucketSize));
            } else {
                if (model.getAllowCounter() <= 0) {
                    try {
                        TimeUnit.MILLISECONDS.sleep(1200);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    int diffSecond = (int) TimeUnit.SECONDS.convert(Util.getUTC().getTime() - model.getModifiedTime(), TimeUnit.MILLISECONDS);
                    int reNewCounter = Math.min(diffSecond * drainRate, bucketSize);
                    model.reInitCounter(reNewCounter);
                }
                model.decrementCounter();
            }
        });
    }
    ```

## 31/08/2020 - Diff

- Check Diff: Một nghiệp vụ lớn có sự thay đổi. Trước đây thì khi restore, flow là chỉ cần user lựa chọn bản backup và
  submit. Hệ thống sẽ tự động restore. Và báo kết quả cuối cho user. Giờ thay đổi, sẽ cần thêm 1 bước user confirm nữa.
  User lựa chọn bản backuplog -> app tính toán ra dữ liệu hiện tại có thay đổi gì so với dữ liệu từ bản backup log, hiên
  thị sự thay đổi cho user => user tích chọn từng đối tượng có sự thay đổi và submit chỉ restore chúng => app thực hiện
  restore và trả về kết quả
- Thiết kế lại database
    - `DiffRequests`
      ![DiffRequests](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/DiffRequests.JPG)
    - `DiffRequestDetails`
      ![DiffRequestDetails](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/DiffRequestDetails.JPG)
      Tương tự như Backup và Restore, Diff Request cũng được thiết kế tương ứng.
    - `Diffs`
      ![Diffs](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/stories/backup_restore/Diff.JPG)
      Bảng Diffs log lại chi tiết sự thay đổi của bản backup với dữ liệu hiện tại. Chi tiết tới từng đối tượng backup.
- Check Diff cũng có queue riêng để thực hiện
- Bắt đầu xuất hiện sự phức tạp trong follow. Các job đều được trigger bởi queue. Nhưng lại cần đảm bảo sao cho thứ tự
  backup-diff-restore được đúng follow.
    - Với case trước khi restore lại cần backup trước 1 bản, lại càng phức tạp
    - Một sự phối hợp giữa publisher/subscriber và thông tin trong column database để giải quyết việc trigger mọi thứ
      được đúng flow
- Sử dụng `org.javers.core.diff` để check

## 14/09/2020

- Compress data: dữ liệu được backup trong file csv và upload lên S3. Ban đầu được đánh giá là dữ liệu này chiếm ít tài
  nguyên. Vì chủ yếu là plaintext. Dữ liệu tốn chủ yếu ở media file. Nhưng khi test với data trên live production, 1
  file backup có thể hơn 100MB. Nhu cầu nén file ra đời.
    - File sau khi được call api collect về, sẽ được nén gzip lại.
    - Toàn bộ việc nén file này thực hiện trên local mem, mà không đẩy ra hard disk. Vì sau khi test và đánh giá thấy
      việc đẩy ra hard disk là không cần thiết. Việc thực hiện trực tiếp trên local memory vẫn đáp ứng được.
    - Kết quả việc nén gzip thực sự hiệu quả, file 100MB được nén xuống chỉ còn ~7MB.
    - Vì compress/decompress đều được thực hiện trên local memmory, nên không có sự chênh lệch tốc độ cho phần này
      nhiều. Thậm chí còn nhanh hơn, do time cho việc upload/download file nhanh hơn.

```java
public static byte[] gzipCompress(byte[] input) {
        try {
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            InputStream inputStream = new ByteArrayInputStream(input);
            GZIPOutputStream gzipOS = new GZIPOutputStream(outputStream);
            byte[] buffer = new byte[1024];
            int len;
            while ((len = inputStream.read(buffer)) != -1) {
                gzipOS.write(buffer, 0, len);
            }
            gzipOS.close();
            inputStream.close();
            outputStream.close();
            return outputStream.toByteArray();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    public static byte[] gzipDecompress(byte[] input) {
        try {
            GZIPInputStream gis = new GZIPInputStream(new ByteArrayInputStream(input));
            ByteArrayOutputStream fos = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int len;
            while ((len = gis.read(buffer)) != -1) {
                fos.write(buffer, 0, len);
            }
            //close resources
            fos.close();
            gis.close();
            return fos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public static byte[] convertS3ObjectToBytes(S3Object s3Object) {
        byte[] data = null;
        try {
            S3ObjectInputStream stream = s3Object.getObjectContent();
            BufferedInputStream bis = new BufferedInputStream(stream);

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            while (true) {
                int r = bis.read(buffer);
                if (r == -1) break;
                out.write(buffer, 0, r);
            }
            out.flush();
            return out.toByteArray();
        } catch (AmazonS3Exception ex) {
            if (!StringUtils.equals("NoSuchKey", ex.getErrorCode())) {
                ex.printStackTrace();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return data;
    }
```

## 08/10/2020

- Confirm when remove backup: Thêm nghiệp vụ mới. Vì hệ thống X không control được user có thể truy cập được vào app.
  Nguy cơ việc 2 user cùng có thể xem được bản backup, nhưng chỉ user owner mới có thể thực hiện xóa. Còn user được ủy
  quyền kia chỉ có thể xem. => phát triển thêm cơ chế khi user thực hiện xóa bản backup, thì service của app sẽ gửi 1
  email chứa link xóa tới owner. Owner click vào link confirm thì bản backup đó mới được xóa
    - Link xóa thực chất chỉ là 1 api remove, có thêm parameter là token.
    - Token sử dụng jwt
    ```java
    @Override
    public String genTokenRemoveBackup(int storeId, List<Integer> backupLogIds) {
        final Date createdDate = clock.now();
        final Date expirationDate = new Date(createdDate.getTime() + 86400000);  // 24h
        Map<String, Object> claims = new HashMap<>();
        claims.put("storeId", storeId);
        claims.put("backupLogIds", backupLogIds);
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(String.valueOf(storeId))
                .setIssuedAt(createdDate)
                .setExpiration(expirationDate)
                .signWith(SignatureAlgorithm.HS256, jwtProperty.getSecret())
                .compact();
    }

    @Override
    public boolean validTokenRemoveBackup(int storeId, List<Integer> backupLogIds, String token) {
        try {
            var claims = Jwts.parser()
                    .setSigningKey(jwtProperty.getSecret())
                    .parseClaimsJws(token)
                    .getBody();
            final Date expirationClaim = claims.getExpiration();
            if (expirationClaim.before(clock.now())) return false;

            int storeIdClaim = (Integer) claims.get("storeId");
            List<Integer> backupLogIdsClaim = (List<Integer>) claims.get("backupLogIds");
            if (!backupLogIds.containsAll(backupLogIdsClaim) || storeIdClaim != storeId) return false;
            return true;
        } catch (Exception ex) {
            return false;
        }
    }
    ```
- Việc gửi email sử dụng AWS SES. (việc tích hợp này tương đối đơn giản)