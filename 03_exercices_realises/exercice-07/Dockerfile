FROM mysql:8.0
ENV MYSQL_ROOT_PASSWORD=rootpass
ENV MYSQL_DATABASE=kennelDB
COPY init.sql /docker-entrypoint-initdb.d/01-init.sql
EXPOSE 3306
