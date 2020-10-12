---
title: CICD - Flow Example
date: 2020-02-22 18:00:26
tags:
    - cicd
category: 
    - cicd_ops
---
## Example 1 - Jenkins 
![Example 1](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/cicd/Diagram_Example_1.png)
- Có 2 repository, 1 repo chứa source code của developer đẩy lên, 1 repo chứa file application (ex: .jar, .dll..., file này được build từ source code) 
- Trong mỗi repository tạo file `Jenkinsfile` chứa script `pipelines`. (giúp hạn chế việc viết script ở Jenkins -> developer chủ động hơn trong việc chỉnh sửa file Jenkins)
- Ở mỗi Git repository (ví dụ gitlab, github...) có feature `intergrations` đẩy `hooks/ notification`
- Jenkins khi nhận được `hooks` cần detect được `branch/label` nào

