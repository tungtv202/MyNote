# Elastic Network Interface
- Là card mạng ảo, được đính vào EC2 (vd: eth0, eth1...)
- Khi EC2 bị terminated => Nếu ENI tạo bằng console thì cũng terminate theo, nếu tạo bằng command line thì ko bị terminated
- Có thể được cấu hình khi: instance running, stopped, launched
- 1 ENI chỉ được cho 1 Insntace, nhưng 1 instance có thể attached nhiều ENI
- Subnet có thể khác nhau nhưng phải chung VPC, chung AZ
