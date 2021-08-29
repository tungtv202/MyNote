---
title: E-Wallet Note
date: 2020-02-22 18:00:26
updated: 2020-02-22 18:00:26
tags:
    - e-wallet
    - momo
category: 
    - other
---

# Note về tích hợp ví điện tử

## ví MOMO

![Payment](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/payment/momo-payment-flow.jpg)

- Tích hợp trên nền tảng website
- Có nét tương đồng với Ví Bảo Kim (có thể các ví điện tử sẽ chung flow)
- Key credential
    - `Partner Code`: Thông tin để định danh tài khoản doanh nghiệp.
    - `Access Key`: Cấp quyền truy cập vào hệ thống MoMo.
    - `Secret Key`: Dùng để tạo chữ ký điện tử signature.
    - `Public Key`: Sử dụng để tạo mã hoá dữ liệu bằng thuật toán RSA.
- Ý nghĩa của `Secret key`: khi nhận data từ `momo`, server tích hợp sẽ sử dụng nó để làm khóa cho hàm băm. (các thuật
  toán băm như md5, sha1, sha256...). đối tượng băm là `payload`. Sau khi có kết quả băm, sẽ compare với giá trị `hash`
  được gửi kèm trong payload. Nếu bằng nhau thì xác nhận là đúng momo gửi data.

    ```java
    String signResponse = Encoder.signHmacSHA256(responserawData, getSecretKey());
    if (signResponse.equals(captureMoMoResponse.getSignature())) {
        return oke;
    } else {
        throw new IllegalArgumentException("Wrong signature");
    }
    ```
- `hash` là 1 chiều, chỉ encode, không thể decode
- `Public key` - được sử dụng trong thuật toán mã hóa RSA (async- encrypt là 1 khóa, decrypt là 1 khóa khác, ai có
  public key cũng có thể khóa, nhưng chỉ có momo có `private key` mới có thể giải mã, ví dụ giải thuật AES). Server tích
  hợp không được cấp `Private key`. Server tích hợp sẽ không gửi `payload` "thô" cho momo. Mà gửi payload đã
  được `encrypt` với `publickey` cho momo.
  ![Encprypt1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/payment/momo-encrypt-1.JPG)

- Momo gửi IPN (instant payment notification / 1 kiểu kiểu như webhook) cho merchant server thì dùng Secret key
- Merchant server gửi request cho momo thì dùng Public key
- Trong `Create payment request` sẽ luôn có 2 trường
    - `returnUrl`: Một URL của đối tác. URL này được sử dụng để chuyển trang (redirect) từ MoMo về trang mua hàng của
      đối tác sau khi khách hàng thanh toán.
    - `notifyUrl`: địa chỉ nhận IPN
- `NotifyURL` sinh ra để tránh trường hợp attacker fake url request tới momo. Merchant server sẽ sử dụng `notifyurl` để
  nhận data từ momo báo về kết quả giao dịch, verify chúng, trước khi xác nhận cho buyer giao dịch thành công.