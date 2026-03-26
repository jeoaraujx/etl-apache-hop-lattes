FROM pgvector/pgvector:pg17

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=22020120
ENV POSTGRES_DB=BD_PESQUISADOR
ENV POSTGRES_HOST_AUTH_METHOD=trust

COPY init_db.sh /docker-entrypoint-initdb.d/init_db.sh

RUN chmod +x /docker-entrypoint-initdb.d/init_db.sh

EXPOSE 5437