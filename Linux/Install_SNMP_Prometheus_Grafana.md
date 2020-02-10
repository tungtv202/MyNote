# Monitor traffic network vs combo: SNMP + Prometheus + Grafana
- Monitor traffic network
    - SNMP: giao thức monitor network
    - Prometheus: collect metric data
    - Grafana: web ui, giao diện đồ họa, dashboard theo dõi 
# Install
## 1. SNMP
- install `apt snmp` tool
```bash
sudo apt-get update
sudo apt-get install snmp snmp-mibs-downloader
```
- Lưu ý:
    - `snmp` mặc định, chỉ có thể monitor resource: ram, cpu.
    - `snmp-mibs-downloader` hỗ trợ download "IF-MIB", dùng để monitor interface, traffic network
- install `apt snmpd` (1 số OS, không cài sẽ không config, start được snmp)
```bash
sudo apt-get install snmpd
```
- edit file config
```bash
sudo nano /etc/snmp/snmp.conf
# comment on #mibs :
```
```bash
# 1
sudo nano /etc/snmp/snmpd.conf

# 2
#  Listen for connections from the local system only
#agentAddress  udp:127.0.0.1:161
#  Listen for connections on all interfaces (both IPv4 *and* IPv6)
agentAddress udp:161,udp6:[::1]:161


# 3. replace config
rocommunity public 172.26.6.172
# để restrict IP có thể monitor

# 4. restart snmpd
sudo service snmpd restart

# 5. check
snmpwalk -v2c -c public 172.26.6.172 
```
## 2. Prometheus
### 2.1 Prometheus export
- Là client thu nhập 1 loại metric riêng biệt
- => `snmp_exporter` 
- Install `snmp_exporter`
    - Ref [link](https://github.com/prometheus/snmp_exporter)
```bash
#1 
wget https://github.com/prometheus/snmp_exporter/releases/download/v0.16.1/snmp_exporter-0.16.1.linux-amd64.tar.gz

#2 
tar -zxf snmp_exporter-0.16.1.linux-amd64.tar.gz

# 3
./snmp_exporter

# 4. validate result via endpoint example
http://172.26.6.172:9116/snmp?module=if_mib&target=172.26.6.172
```

### 2.2 Prometheus server
- Install via docker
```bash
docker run -d \
    -p 9190:9090 \
    -v /home/ubuntu/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
```
- Trong đó file `prometheus.yml`
```yml
global:
  scrape_interval:     1s
scrape_configs:
  - job_name: 'snmp'
    static_configs:
      - targets:
        - 172.26.6.172  # SNMP device.
    metrics_path: /snmp
    params:
      module: [if_mib]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 172.26.6.172:9116 
```
http://ls1.tungexplorer.me:9190/targets
![http://ls1.tungexplorer.me:9190/targets](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/prometheus/snmp_export_prometheus.png)
- promQuery
```
rate(ifHCOutOctets[1m])
```
![query get traffic](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/prometheus/query_gettraffic.png)

## 3. Grafana
- web ui dashboard, graphic monitor
- install via docker
```bash
docker run -d -p 3000:3000 grafana/grafana
## admin/admin
```
- config
    - Add prometheus endpoint
    - Create dashboard with query `rate(ifHCOutOctets[1m])` .   

![Grafana dashboard](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/grafana/snmp_garafana.png)
