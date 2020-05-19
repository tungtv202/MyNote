## Important:
Rabbitmq từ version 3.8.0 trở đi, có 1 thay đổi lớn về các feature support. Trong đó đặc biệt có Quorum Queue. Cái ra đời để giải quyết các vấn đề của Mirror Queue trong các version trước đó gặp phải. Các note dưới đây có thể không đúng với Quorum Queue nữa.

- Sử dụng Mnesia database
- Durable Queues/Exchanges:
    - 2 loại queue:
        - durable: khi node bị lỗi, hoặc sự cố khởi động lại thì queue sẽ được "load" lại khi startup
        - non-durable: ngược lại vs durable. Restart là mất
- Persistent Messages
    - message phải được set là `persistent` + vs queue là durable, thì mới không lo message bị mất khi bị restart
- Evalution
    - Non-durable Queue + Non-Persistent message = mất Queue + mất Message (sau khi Broker restart)
    - Durable queue + Non-Persistent message = Còn Queue + mất Message 
    - Durable queue + Persistent message = Còn Queue + Còn Message 
    - Mirrored queue + Persistent message = Còn Queue + Còn Message
- Rabbitmq không khi message vào disk ngay khi nhận được. Mà nó sẽ save vào disk theo lịch định kỳ (mỗi chu kỳ vài trăm ms). Nếu có cấu hình `mirror queue`, thì tất cả các node mirror ghi vào disk xong, thì publisher mới confirm ACK là write message done.
- Thiết kế cluster rabbitmq, thì client có thể connect tới bất kỳ broker nào, Nhưng sau đó các message đọc ghi sẽ được điều hướng về broker có queue master. (giống cơ chế của Kafka)
##  Mirrored Queues
- Tiền thân là Replicated queue
- Node master sẽ nhận tất cả các request đọc/ ghi. Các node mirror sẽ nhận tất cả message từ node master và ghi vào disk. 
- `Lưu ý: các node mirror không có nhiệm vụ giảm tải "read"/"write" cho node master. Nó chỉ mirror message để phụ vụ việc HA. => Từ phiên bản 3.8 trở đi, Rabbit MQ support QUORUM QUEUE để giải quyết vấn đề này.`
- Lưu ý: Ví dụ có 3 broker. Queue A có thể master trên broker 1. Nhưng Queue B có thể master trên broker 2
- Khi node mirror gặp sự cố, cluster sẽ chọn node mirror `oldest` để làm mirror. Và broadcast lại cho cluster.
### ha-mode
- Ví dụ cách chỉ định:
    - ha-mode: all
    - ha-mode: exactly, ha-params: 2 (one master and one mirror)
    - ha-mode: nodes, ha-params: rabbit@node1, rabbit@node2
- Lưu ý: số broker trong cluster >= số node được khai báo ở `ha-mode`. Ví dụ có 3 broker, nhưng Queue A chỉ khai báo `ha-mode: exactly, ha-params: 2` thì queue đó chỉ có 1 master, 1 mirror. (broker thứ 3 còn lại không làm gì).
### Synchronization - ha-sync-mode
- Có 2 mode để sync data giữa các broker:
    - `ha-sync-mode = automatic` : khi có 1 broker fail, bị loại ra khỏi cluster, sau đó online trở lại broker. Thì data sẽ được sync từ master lại "từ đầu". (queue + message trong queue)
    - `ha-sync-mode = manual`: sau khi broker fail quay trở lại cluster. thì chỉ sync queue + ko sync các message cũ. (chỉ sync các message mới, từ lúc broker fail online trở lại)
- Mode manual gặp vấn đề khi broker fail comeback. Tuy nhiên ưu điểm của manual là `trong khoảng thời gian broker online gia nhập cluster lại `  queue ở master vẫn hoạt động bình thường. Còn với mode `automatic` gặp vấn đề là sẽ bị mất 1 khoảng thời gian để sync data message. Và khoảng thời gian này sẽ làm block việc đọc ghi queue.

### Network Partitions
- Vấn đề gặp phải khi network bị partitions giữa các node. Khiến cho các node không kết nối được tới node khác, nên tự set chính mình lên làm master. Dẫn tới có >1 master trong 1 cluster. Và khi sự cố network được giải quyết, thì không biết chọn node nào làm master, node nào làm mirror. Cái này keyword là "split-brain"
- Để giải quyết vấn đề này cần setup `Pause Minority`. Khi bị `split-brain` thì bên phía nào ít node hơn. Sẽ tự pause chính mình. Từ chối nhận bất kỳ message nào từ publisher. Để publisher sau đó tự tìm tới node master bên phía có nhiều node hơn. 
    - Ví dụ: có 3 node. Khi gặp sự cố network partition. Sẽ có 2 bên. 1 bên là 1 node master. 1 bên là 1 node master và 1 node mirror. 
    bên phía chỉ có 1 node master sẽ tự pause chính mình. từ chối các message tới. Để publisher tìm tới node master bên phía có 2 node.

### Tổng kết
- Nếu nghiêng về hướng thiết kế HA (chấp nhận rủi ro mất message, hoặc không đảm bảo tính nhất quán):
    - ha-promote-on-failure=always
    - ha-sync-mode=manual
    - cluster_partition_handling=ignore or autoheal
    - Persistent messages
    - Cần đảm bảo client có kết nối tới cluster khi có node down
- Nếu nghiêng về hướng thiết kế đảm bảo data (không đảm bảo HA trong 1 thời gian ngắn)
    - use Publisher Confirms and Manual Acknowledgements on the consumer side
    - ha-promote-on-failure=when-synced (nếu publisher có thể retry sau, và bộ nhớ thoải mái)
    - ha-sync-mode=automatic (chấp nhận khi có node restart thì quá trình sync lại data sẽ làm block cả cluster trong khoảng thời gian sync)
    - Pause Minority mode
    - Persistent messages
- Khi thiết kế HA, nên có 1 LB, để khi accesss vào node lỗi, thì sẽ được lb qua node khác.

## Quorum Queue
- client sử dụng mirror queue có thể sử dụng với quorum queue (có khả năng tương thích ngược)
- khi sử dụng quorum queue, message luôn là durable (ko cần phải khai báo như với Mirror Queue)

![Quorum vs Mirror](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/rabbitmq/QuorumVsMirrorQueue.PNG)

- Poison Message Handling: message gửi cho consumer với số lần quá ngưỡng cho phép
    - x-delivery-count  : thông tin ở header msg
    - delivery-limit : sử dụng attribute này để setup config giới hạn
- Quorum queue dữ msg mãi mãi trên disk (khác với mirror là sau khi consumer ack thì sẽ delete ?)
- WAL - write-ahead-log
- khi node fail, xong quay lại, thì nó chỉ đồng bộ các message mới. mà ko phải sync lại từ đầu. Và quá trình sync các message mới này ko bị blockking (ưu việt hơn so với Mirror)
- MEMORY USAGE - ALL MESSAGES IN-MEMORY ALL THE TIME
- Nếu broker bị lỗi gì đó làm mất dữ liệu, thì toàn bộ msg trên broker đó sẽ mất vĩnh viễn. Khi broker đó online trở lại, thì ko thể sync lại data từ leader từ đầu.

----------------------------------------------------------------------------------------
# Triển khai HA cho RabbitMQ
## 1. Quick Start
### Kịch bản
- Xây dựng HA với 3 node (3 broker)
- Sử dụng docker-compose để install (version 3.6)
### Cài đặt 
- Trên 3 node tải script tại thư mục `docker_rabbitmq_ha`
- Sửa thông số:
    - Tại port tại file docker-compose
        - "5672:5672" : port để client connect vào broker. Sửa đổi port này tại field `listeners.tcp.default` trong file `rabbitmq-qq.conf`
        - "4369:4369" : port epmd , port này có thể thay đổi, nhưng trên tất cả các node, port này phải giống nhau. Để thay đổi port này. Sửa variable `ERL_EPMD_PORT` tại file `rabbitmq-qq-env.conf`
        - "25672:25672" : port đi kèm với epmd, sử dụng cho các node trong cluster giao tiếp với nhau. Có thể đổi port này bằng thay đổi variable `RABBITMQ_NODE_PORT` tại file `rabbitmq-qq-env.conf`
        - "15672:15672" : port vào webadmin
- Truy cập vào từng node và run bash command
    - Node 1: `docker-compose -f docker/docker-compose-ha-node1.yml up`
    - Node 2: `docker-compose -f docker/docker-compose-ha-node2.yml up`
    - Node 3: `docker-compose -f docker/docker-compose-ha-node3.yml up`
- Verify:
    - Truy cập vào webadmin của rabbitmq để verify cluster đã nhận đủ 3 node 
        - Ex: http://localhost:15672 (guest/guest)
        
    ![web_admin_verify_install](https://tungexplorer.s3-ap-southeast-1.amazonaws.com/rabbitmq/web_admin_verify_install.png)
    
### Sử dụng 
- Khi tạo queue mới:
    - `type = Quorum` : bắt buộc
    - `node` : chọn bất kỳ 1 node để làm leader cho queue. (không quan trọng, sau này có sự cố tự động cluster sẽ bầu lại leader mới)
    ![create_quorum_queue](https://tungexplorer.s3-ap-southeast-1.amazonaws.com/rabbitmq/create_quorum_queue.png)
- Sau khi tạo queue xong, có thể verify lại bằng vào tab `detail`
    - ![quorum_detail](https://tungexplorer.s3-ap-southeast-1.amazonaws.com/rabbitmq/quorum_detail.png)
- Cấu hình cluster ở `Spring Boot`
    ```yml
    spring.rabbitmq.addresses=localhost:5679,localhost:5680,localhost:5681
    spring.rabbitmq.username=guest
    spring.rabbitmq.password=guest
    ```
## 2. Một vài chú ý
### Lựa chọn giải pháp 
- RabbitMQ chỉ support Quorum Queue từ version 3.8 trở đi. Trước đó để xây dựng HA phải sử dụng Mirror Queue
- Quorum Queue ra đời để giải quyết các vấn đề lớn mà Mirror Queue đăng gặp phải:
    - Quá trình sync data sau khi có node bị lỗi, xong sau đó online lại, làm `block` cả cluster. (Queue master sẽ không thể write/read)
    - Khi gặp sự cố Network Partition, Mirror Queue rơi vào kịch bản `split-brain`. (1 queue/cluster > 1 master)
- Để xây dựng cluster với Mirror Queue cần phải config policy từ đầu.
    - Ví dụ:
    ```json
    "policies": [
        {
        "vhost": "/",
        "name": "mirrorqueues",
        "apply-to": "queues",
        "pattern":"^.*",
        "definition": {
            "ha-mode":"exactly",
            "ha-params":2,
            "ha-sync-mode":"automatic"
        }
        }
    ],
    ```
    - hiện tại tài liệu chưa có guide setup Mirror Queue
- Có thể sử dụng 1 Load Balancer. Thay cho cách khai báo danh sách các broker ở `Spring boot`
    - Ví dụ sử dụng nginx.
    ```
    events {

    }
    stream {
    upstream myrabbit {
        server rabbitmq1:5672;
        server rabbitmq2:5672;
    }

    server {
        listen 5000;
        proxy_pass myrabbit;
    }
    }
    ```       
### Lưu ý vận hành
- Đổi user/pass tại file `rabbitmq-qq-definitions.json` hoặc sau khi setup cluster thành công, login vào webadmin đổi
- Mặc định message trên Quorum Queue lưu trên memory/disk mãi mãi. Cần setup giới hạn (và hệ thống 3rd giám sát) để khi tới ngưỡng, rabbitmq release tài nguyên
    - `x-max-in-memory-length` sets a limit as a number of messages. Must be a non-negative integer.
    - `x-max-in-memory-bytes` sets a limit as the total size of message bodies (payloads), in bytes. Must be a non-negative integer.
- Cân nhắc khi sử dụng Quorum Queue cho Fanout Exchange. (Vì bộ nhớ để chứa message được nhân lên rất nhiều => tốn resource)
- Nên set up số node (broker) là số lẻ. Ví dụ 3,5,7 để thuận lợi cho giải thuật bầu leader
- Một khi node (broker) bị mất data msg (ví dụ lỗi disk/memory). Thì các msg trên broker đó sẽ mất mãi mãi. Khi online trở lại cluster. Sẽ chỉ có các msg mới được sync từ Leader (tính từ thời điểm online)
- Khai báo node trong cluster sử dụng sortName, (ko dùng được FQDN)
- 1 vài command
    - rabbitmq status
    - epmd -port 4369 -names
