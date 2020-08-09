# Tổng hợp các lệnh để install đã từng dùng
- Postgresql
```bash
 docker run --name postgres-crawler1688 \
    -e POSTGRES_PASSWORD=crawler1688a@ \
    -v /home/ubuntu/docker/postgres_data:/var/lib/postgresql/data  \
    -p 5432:5432 \
    -d postgres
```

- pgadmin4 (webui cho postgresql)
```bash
docker run -p 8083:80 \
    -e 'PGADMIN_DEFAULT_EMAIL=admin' \
    -e 'PGADMIN_DEFAULT_PASSWORD=password@' \
    -d dpage/pgadmin4
```
- install psql client
```bash
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt-get install postgresql-client
```

pg_dump -h crawler1688-s2.tungexplorer.me -U postgres -d crawler1688  --exclude-table=exclude_id_seq > backup_crawler1688_`date +%Y_%m_%d`.sql