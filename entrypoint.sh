#!/bin/bash
set -euo pipefail

cd /opt

version="$PG_MAJOR"
arch=$(arch)
echo -n "[+] Preparing to download PostgreSQL $version..."
wget -q "https://ftp.postgresql.org/pub/source/v$version/postgresql-$version.tar.gz" -O postgresql-$version.tar.gz
download=$?

if [ $download -ne 0 ]; then
    echo ""
    echo "[-] Failed to download version $version"
    wget -q "https://ftp.postgresql.org/pub/source/" -O options.txt
    first=$(grep "=\"v$PG_MAJOR" options.txt | grep -Po '="v\K(.*?)(?=/)' | sort --version-sort | head -n 1)
    if [ -z "$first" ]
    then
        exit -1
    else
        echo "[-] Warning, will continue using oldest $PG_MAJOR version: $first"
        version="$first"
        echo -n "[+] Preparing to download PostgreSQL $version..."
        wget -q "https://ftp.postgresql.org/pub/source/v$version/postgresql-$version.tar.gz" -O postgresql-$version.tar.gz
        download=$?
        if [ $download -ne 0 ]; then
            echo "[-] Also failed downloading $version version"
            exit -2
        fi
        echo "Done!"
    fi
else
    echo "Done!"
fi
wget -q "https://ftp.postgresql.org/pub/source/v$version/postgresql-$version.tar.gz.md5" -O hash.txt

echo "[+] Validating hash... "
md5sum -c hash.txt
echo ""

validHash=$?
if [ "$validHash" -ne 0 ]; then
    echo "[-] Invalid hash, quiting"
    exit -1
fi

gunzip "postgresql-$version.tar.gz" && tar xf "postgresql-$version.tar"

cd "postgresql-$version"

echo "[+] Building PosgreSQL $version from source... (this can take a while)"
./configure > /dev/null 2> /dev/null && make > /dev/null 2> /dev/null

echo "[+] Building extension..."
cd /opt/pg_exec
gcc -I"/opt/postgresql-$version/src/include" -shared -fPIC -o "libraries/pg_exec-$arch-$PG_MAJOR.so" pg_exec.c

echo "[+] Updating checksums..."
cd libraries
sha256sum *.so > checksums.sha256
md5sum *.so > checksums.md5

echo "[+] Done"