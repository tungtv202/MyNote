# Install SecureCRT có thuốc
## 1. Install
Version 8.5.4
- Download package
https://drive.google.com/drive/u/0/folders/1URylpTv4MGMdZJ6rUeSIkHe1_Pj1GuJa
- Install file setup "Setup 64 Bit.exe"
- Coppy file keygen_path vào folder file location cài đặt 
ex:
```
C:\Program Files\VanDyke Software\Clients
```
- Chạy file "Patch & Keygen.exe" với quyền Run As Admin 
- Click Path, và thực hiện select lần lượt tới 2 file .exe 
```
SecureCRT.exe
LicenseHelper.exe
```
Báo success là thành công path
- Chạy file SecureCRT.exe       
Tại giao diện phần mềm, thực hiện nhập liencese từ file keygen gen ra.      
DONE
## 2. Config theme
### 2.1 Basic
- SSH tới server
- Options > Session Options > Terminal > Appearance     
Trong mục "Current color scheme", lựa chọn 1 theme bất kỳ, và bấm OK
- Theme sẽ được apply tại session ssh đang kết nối ngay lập tức

### 2.2 Config bởi file theme trên mạng
- Download file theme example       
Link 1: https://forums.vandyke.com/showpost.php?p=45225&postcount=1     
Link 2: https://drive.google.com/drive/u/0/folders/1URylpTv4MGMdZJ6rUeSIkHe1_Pj1GuJa
```
ColorSchemeAutoRotation.py
```
- Tại cửa sổ SecureCRT > View > tick Button Bar
- Tại bottom của window, click chuột phải, chọn New Button 
- Tại cửa sổ Map Button 
    - Funciton: Run Script
    - Select file .py vừa download (trong window chọn .All file để có thể chọn file)
    - Label: đặt tên bất kỳ, ví dụ: ChangeSchemaColor
    - OK
- Click vào button vừa tạo, mỗi lần click sẽ ra 1 màu khác nhau

// Tham khảo: https://www.youtube.com/watch?v=SZLbBsp3914
