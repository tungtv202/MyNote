# Tổng hợp các lệnh để install đã từng dùng
- Postgresql
```bash
 docker run --name some-postgres \
    -e POSTGRES_PASSWORD=password@ \
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
