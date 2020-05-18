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