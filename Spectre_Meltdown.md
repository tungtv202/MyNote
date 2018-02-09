Mới đây Google đã công bố 2 lỗ hổng bảo mật cực kỳ nghiêm trọng của Intel đó là Meltdown và Spectre.
Cả 2 đều lợi dụng lỗ hổng bảo mật cơ bản trong các chip nói trên, về mặt lý thuyết mà nói thì chúng có thể được dùng để "đọc những thông tin nhạy cảm trong bộ nhớ của một hệ thống, như mật khẩu, khóa để mở nội dung được mã hóa hay bất kì thông tin nhạy cảm nào".
Hiện nay lỗ hổng này đều đã có trong bản vá lỗi của Microsoft, nhưng điều này sẽ làm chậm tới 30% tốc độ của chíp xử lý. Và các bản vá lỗi này đều chỉ là vá lỗi dựa trên OS, chứ không phải vá lỗi ở tầng thiết bị phần cứng của chíp xử lý.

## Bản chất của Meltdown và Spectre là gì?

Chúng không phải là "bug" trong hệ thống. Chúng là những CÁCH THỨC tấn công vào chính cách hoạt động của các bộ xử lý Intel, ARM hay AMD. Lỗi này được phòng thí nghiệm bảo mật mạng Project Zero của Google phát hiện ra.
Họ nghiên cứu kỹ những con chip trên, tìm ra được một lỗ hổng trong thiết kế, một lỗ hổng chết người mà Meltdown và Spectre có thể lợi dụng, kéo đổ những phương thức bảo mật thông thường của các bộ xử lý này.

Cụ thể, đó chính là cách thức "thực hành suy đoán – speculative execution", một kỹ thuật xử lý được sử dụng trong chip Intel từ năm 1995 và cũng là cách thức xử lý dữ liệu thường gặp trên bộ xử lý ARM và AMD. Với cách thức thực hành suy đoán thì về cơ bản, con chip sẽ suy đoán xem bạn chuẩn bị làm gì. Nếu như chúng đoán đúng thì chúng đã đi trước bạn một bước, việc đó sẽ khiến bạn cảm thấy máy chạy trơn tru hơn. Nếu như chúng đoán sai, dữ liệu được bỏ đi và đoán lại từ đầu.
## Giải thích bug Spectre dưới góc nhìn code
if a > b:
then do C
Sếp yêu cầu bạn kiểm tra lại số tiền trong ngân hàng nếu có đủ thì vác xác đi mua cho sếp 1 thùng rượu để biếu nhân dịp năm mới.
Vì việc kiểm tra này tốn thời gian nên trong lúc chờ đợi thì bạn cứ liên hệ với bên bán rượu để hỏi giá cả và làm các việc khác.

CPU cũng vậy, thay vì đợi a và b load lên nó sẽ thực hiện C, nếu sau này phát hiện ra là a < b, nó sẽ revert lại tình trạng ban đầu và bỏ đi kết quả đã thực hiện C, cũng như bạn sẽ huỷ kèo với bên bán rượu.

Bây giờ hãy nhìn nhận tiếp ví dụ sau:

```java
Func exploit:
if (x < array1_size):
........y = array2[array1[x] * 256];
```
Lần đầu function exploit được gọi với x < array1_size để CPU được dạy rằng khả năng cao là phép kiểm tra đó đúng, lần thứ 2 gọi lại với x là số lớn hơn, lúc này CPU tiếp tục thực hiện phép load x lên từ array1 và giá trị OOB ( ngoài khả năng của array1 ) này được sử dụng làm index cho việc load giá trị từ array2, khi thực hiện phép load CPU sẽ đưa giá trị này vào cache để cho tốc độ truy xuất lần tiếp sau sẽ nhanh hơn, dựa vào đó khi xem xét ví dụ tiếp theo:
```java
struct array *arr1 = ...; /* small array */
struct array *arr2 = ...; /* array of size 0x400 */
/* >0x400 (OUT OF BOUNDS!) */
unsigned long untrusted_offset_from_caller = ...;
if (untrusted_offset_from_caller < arr1->length) {
........unsigned char value = arr1->data[untrusted_offset_from_caller];
........unsigned long index2 = ((value&1)*0x100)+0x200;
........if (index2 < arr2->length) {
................unsigned char value2 = arr2->data[index2];
}
}
```
Tuỳ vào value là 0 hay 1 mà arr2 sẽ load lên 0x200 hay 0x300, sau đó kiểm tra lại bằng timing 1 lần nữa xem 0x200 hay 0x300 có trên cache hay không sẽ biết được giá trị value ban đâu là bao nhiêu -> leak dc memory ngoài độ dài cho phép của arr1.
