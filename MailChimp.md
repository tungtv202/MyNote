# MailChimp - 1 service cho bài toán email marketing
## 1. Giới thiệu
MailChimp là dịch vụ Email Marketing rất nổi tiếng. Ngoài ý nghĩa marketing chính ra thì MailChimp còn có thể sử dụng cho nhiều mục đích khác nữa. Ví dụ có thể phát triển làm hệ thống mail thông báo khi có event từ user…

Việc sử dụng MailChimp cơ bản gồm các bước sau:
### Step 1.	Tạo LIST
Tạo danh sách chứa các email người nhận. Ví dụ:
- List SinhVien, chứa thông tin 1000 email của sinh viên
- List ITCustomer, chứa thông tin 5000 email của người công tác, làm việc trong lĩnh vực CNTT.


### Step 2. Tạo Campaign
Tạo chiến dịch marketting Bao gồm:
- Chọn LIST
- Setup title, subject email, email ngườ i gửi
- Setup template, nội dung email
- Setup lịch chạy

### Step 3. Send Campaign
### Step 4. Xem thống kê report
- Số lượt open mail
- Số lượt click
- Số lượt unsubscribe   

Các bước trên được thực hiện thông qua 2 cách:  

- Thực hiện qua giao diện website https://mailchimp.com
- Thực hiện thông qua MailChimp API (link https://developer.mailchimp.com ).    

Hiện tại MailChimp API cung cấp các API chuẩn Restful cho developer thao tác với hệ thống của họ, gần như toàn bộ thao tác user có thể làm trên web đều có thể được thực hiện thông qua API. MailChimp API mới nhất đang là version 3.0
Với Java để thao tác với Restful này có thể sử dụng Jersey Client (link tham khảo https://o7planning.org/vi/11217/tao-ung-dung-java-restful-client-voi-jersey-client)
Tuy nhiên cũng có thể sử dụng cách khác, đó là dùng các thư viện java do người khác đã dựng sẵn. Ví dụ như 1 thư viện google ra rất nhiều kết quả là:
Ecwid/maleorang: MailChimp API 3.0 wrapper for Java

## 2. Thư viện Ecwid/maleorang
Link ref: https://github.com/Ecwid/maleorang    
Java doc: http://www.javadoc.io/doc/com.ecwid/maleorang/3.0-0.9.6   

List package
```
•	com.ecwid.maleorang
•	com.ecwid.maleorang.annotation
•	com.ecwid.maleorang.connector   - kết nối API thôi, cũng không có gì
•	com.ecwid.maleorang.method.v3_0.batches – chưa ví dụ được demo, nên cũng chưa hiểu
•	com.ecwid.maleorang.method.v3_0.campaigns  - thêm, sửa, xóa, lấy thông tin của Campaign
•	com.ecwid.maleorang.method.v3_0.campaigns.content  - thao tác với content của Campaign, ví dụ template email, nội dung email, set sequence…
•	com.ecwid.maleorang.method.v3_0.lists – 3 cái lists này để thao tác thêm, sửa, xóa, lấy thông tin của List
•	com.ecwid.maleorang.method.v3_0.lists.members
•	com.ecwid.maleorang.method.v3_0.lists.merge_fields 
•	com.ecwid.maleorang.method.v3_0.reports.email_activity  - thống kê hoạt động các email nằm trong list, đã làm gì với email marketing được gửi từ campaign, ví dụ: tỉ lệ open, tỉ lệ click, info…
•	com.ecwid.maleorang.method.v3_0.reports.unsubscribed – tương tự như email_activity nhưng là các report về người đánh dấu email là spam…
```

## 3. Demo
Đoạn code java demo dưới đây thực hiện + mô phỏng lại các bước cơ bản sử dụng MailChimp.    
Recommend là nên xem các video hướng dẫn sử dụng Mailchimp thông qua web user trên youtube, google trước => để hiểu được dễ dàng hơn về ý nghĩa của các đoạn code.

### Step 1. Import thư viện
Sử dụng maven để import
```xml
<dependency>
    <groupId>com.ecwid</groupId>
    <artifactId>maleorang</artifactId>
    <version>3.0-0.9.6</version>
</dependency>
```
### Step 2. Lấy API Key
Để thao tác với MailChimp API, bạn cần phải có APIKey (1 đoạn mã hash, thay cho username + pass).   
Để có APIKey bạn bắt buộc phải có account ở https://mailchimp.com.  
Việc tạo account và lấy API có thể tham khảo tại đây:   
https://wiki.chili.vn/huong-dan/huong-dan-lay-ma-api-mailchimp/
### Step 3. Tạo một LIST mới, Có tên là SinhVien
```java
import com.ecwid.maleorang.MailchimpClient;
import com.ecwid.maleorang.method.v3_0.lists.*;

public class CreateList {

    public static void main(String[] args) throws Exception {
        String apiKey = "60205bb15d24ac4769dedd6e68d0dd77-us18";
        MailchimpClient client = new MailchimpClient(apiKey);

        // create new CreateList
        EditListMethod.Create editListMethod = new EditListMethod.Create();
        editListMethod.name = "SinhVien";
        editListMethod.permission_reminder = "Ban nhan duoc email nay vi ban la Sinh Vien gioi, co tai nang";
        editListMethod.email_type_option = false;
        editListMethod.visibility = "pub";

        // Create contactInfo
        ContactInfo contactInfo = new ContactInfo();
        contactInfo.company = "Freelancer";
        contactInfo.city = "Ha Noi";
        contactInfo.address1 = "18 Pham Hung, Q. Nam Tu Liem";
        contactInfo.country = "VietNam";
        contactInfo.zip = "100000";
        contactInfo.state = "Ha Noi";

        // CampaignDefaultInfo
        CampaignDefaultsInfo campaignDefaultsInfo = new CampaignDefaultsInfo();
        campaignDefaultsInfo.from_name = "Tran Van Tung Sender";
        campaignDefaultsInfo.from_email = "tungtv202@gmail.com";
        campaignDefaultsInfo.language = "en";
        campaignDefaultsInfo.subject = "";

        // Implement
        editListMethod.contact = contactInfo;
        editListMethod.campaign_defaults = campaignDefaultsInfo;

        // Run
        ListInfo listInfo = client.execute(editListMethod);
        System.out.println(listInfo.id);
    }
}
```
->	List ID = a1417c3117    
Vào website F5 xem có gì HOT ?
![MailChimp](https://images.viblo.asia/96d8ad72-3395-4feb-aefe-ec7567f56195.jpg)

### Step 4. Thêm danh sách email người nhận vào List SinhVien
```java
      import com.ecwid.maleorang.MailchimpClient;
        import com.ecwid.maleorang.MailchimpObject;
        import com.ecwid.maleorang.method.v3_0.lists.members.EditMemberMethod;

public class AddReceiverToList {
    public static void main(String[] args) throws Exception {
        String apiKey = "60205bb15d24ac4769dedd6e68d0dd77-us18";
        MailchimpClient client = new MailchimpClient(apiKey);

        String listId = "a1417c3117";

        EditMemberMethod.CreateOrUpdate createOrUpdate = new EditMemberMethod.CreateOrUpdate(listId, "cafeviet9x@gmail.com");
        createOrUpdate.status = "subscribed";
        createOrUpdate.merge_fields = new MailchimpObject();
        createOrUpdate.merge_fields.mapping.put("FNAME", "SinhVien");
        createOrUpdate.merge_fields.mapping.put("LNAME", "Tung");
        client.execute(createOrUpdate);
    }
}
```
![MC2](https://images.viblo.asia/6bb5cbe8-02e0-449c-89d0-1f48113b6c7e.jpg)

### Step 5. Tạo Campaign
```java
import com.ecwid.maleorang.MailchimpClient;
import com.ecwid.maleorang.method.v3_0.campaigns.CampaignInfo;
import com.ecwid.maleorang.method.v3_0.campaigns.EditCampaignMethod;
import static com.ecwid.maleorang.method.v3_0.campaigns.CampaignInfo.Type.PLAINTEXT;

public class Campaign {
    public static void main(String[] args) throws  Exception{
        String apiKey = "60205bb15d24ac4769dedd6e68d0dd77-us18";
        MailchimpClient client = new MailchimpClient(apiKey);

        EditCampaignMethod.Create campaign = new EditCampaignMethod.Create();
        campaign.type = PLAINTEXT;
        campaign.settings = new CampaignInfo.SettingsInfo();
        campaign.settings.mapping.put("title", "Campaign_DuHocSinh");
        campaign.settings.mapping.put("subject_line", "Subject email - Cơ hội du học sinh miễn phí");
        campaign.settings.mapping.put("from_name", "To Chuc Tuyen Sinh");
        campaign.settings.mapping.put("reply_to", "tungtv202@gmail.com");

        // set List receiver
        CampaignInfo.RecipientsInfo recipientsInfo = new CampaignInfo.RecipientsInfo();
        String listId = "a1417c3117";
        recipientsInfo.list_id= listId;

        campaign.recipients = recipientsInfo;

        CampaignInfo campaignInfo = client.execute(campaign);
        System.out.println(campaignInfo.id);

    }
}
```
-> Campaign ID: 87b2227f76      
![MC3](https://images.viblo.asia/6de625a2-3b64-46a2-b879-abf8e3a10ea8.jpg)

### Step 6. Set nội dung email và kích hoạt Campaign gửi
```java
import com.ecwid.maleorang.MailchimpClient;
import com.ecwid.maleorang.method.v3_0.campaigns.CampaignActionMethod;
import com.ecwid.maleorang.method.v3_0.campaigns.content.ContentInfo;
import com.ecwid.maleorang.method.v3_0.campaigns.content.SetCampaignContentMethod;

public class SetContentEmailAndSend {
    public static void main(String[] args) throws Exception {
        String apiKey = "60205bb15d24ac4769dedd6e68d0dd77-us18";
        MailchimpClient client = new MailchimpClient(apiKey);

        String campaintId = "5432c9c488";

        // Set content email
        SetCampaignContentMethod setCampaignContentMethod = new SetCampaignContentMethod(campaintId);
        setCampaignContentMethod.mapping.put("plain_text","Xin chào! Bạn đang có cơ hội được đi du học miễn phí!");
        ContentInfo contentInfo = client.execute(setCampaignContentMethod);

//         Run campaign
        CampaignActionMethod.Send send = new CampaignActionMethod.Send(campaintId);
        client.execute(send);
    }
}
```
Vào inbox email cafeviet9x@gmail.com check kết quả
![MC4](https://images.viblo.asia/1e0ca7b2-a24f-4234-8815-d2d5fc84bf47.jpg)
![MC5](https://images.viblo.asia/57cb64d8-0b95-4a88-8340-4776dea9f5ba.jpg)

Vì hiện tại email content Java mình code, đang để nội dung là plainText, vậy nên sẽ không thể report thống kê khi receiver open email hoặc click được! (Cái này mailchimp nói)