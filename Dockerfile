FROM ubuntu
RUN apt-get update
RUN apt-get install -y build-essential \
    gcc \
    libreadline6-dev \
    libsystemd-dev \
    wget \
    zlib1g-dev
ENV PG_MAJOR 9.2
ADD entrypoint.sh entrypoint.sh
ADD pg_exec.c /opt/pg_exec/pg_exec.c
ENTRYPOINT ["./entrypoint.sh"]