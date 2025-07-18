#! /bin/bash

if [[ $(command -v podman) ]];  then
    podman pod create --replace \
        --restart=unless-stopped \
        --label=app=paperless \
        --network bridge \
        --name=paperless \
        --publish 8000:8000 \
        --publish 8001:3000 \
        --publish 8002:8080 \
        --label=tsdproxy.enable=true

    podman volume create paperless-redis
    podman volume create paperless-database
    podman volume create paperless-ai
    podman volume create paperless-data
    podman volume create paperless-media
    podman volume create stirling-training
    podman volume create stirling-conf
    podman volume create stirling-custom
    podman volume create stirling-logs
    podman volume create sirling-pipelines

    read -rsp "PostgreSQL database password: " DB_PASSWORD
    echo "${DB_PASSWORD}" | podman secrete create paperless-postgres -
    read -p "Path to consume folder: " PAPERLESS_CONSUME
    read -p "Path to export folder: " PAPERLESS_EXPORT

    if [[ ! -d "${PAPERLESS_CONSUME}" ]]; then
        mkdir -p "${PAPERLESS_CONSUME}"
    fi

    if [[ ! -d "${PAPERLESS_EXPORT}" ]]; then
        mkdir -p "${PAPERLESS_EXPORT}"
    fi

    podman run --pod paperless -dt \
        --replace --restart=unless-stopped \
        --label=app=paperless \
        --name tika \
        docker.io/apache/tika:latest

    podman run --pod paperless -dt \
        --replace --restart=unless-stopped \
        --label=app=paperless \
        --name \
        gotenberg docker.io/gotenberg/gotenberg:8.20

    podman run --pod paperless -dt \
        --replace --restart=unless-stopped \
        --label=app=paperless \
        --name db \
        -v paperless-database:/var/lib/postgresql/data \
        -e POSTGRES_DB=paperless \
        -e POSTGRES_USER=paperless \
        --secret=paperless-postgres-pw,type=env,target=POSTGRES_PASSWORD \
        docker.io/library/postgres:17

    podman run --pod paperless -dt \
        --replace --restart=unless-stopped \
        --label=app=paperless \
        --name wenbserver \
        -v paperless-data:/usr/src/paperless/data \
        -v paperless-media:/usr/src/paperless/media \
        -v "${PAPERLESS_CONSUME}":/usr/src/paperless/consume \
        -v "${PAPERLESS_EXPORT}":/usr/src/paperless/export \
        -e PAPERLESS_REDIS=redis://broker:637 \
        -e PAPERLESS_DBHOST=db \
        -e PAPERLESS_DBUSER=paperless \
        --secret=paperless-postgres-pw,type=env,target=PAPERLESS_DBPASS \
        -e PAPERLESS_DBNAME=paperless \
        -e PAPERLESS_TIKA_ENABLED=1 \
        -e PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3000 \
        -e PAPERLESS_TIKA_ENDPOINT=http://tika:9998 \
        ghcr.io/paperless-ngx/paperless-ngx:latest

    podman run --pod paperless -dt \
        --replace --label=app=paperless \
        --restart=unless-stopped \
        --name paperless-ai \
        -v paperless-ai:/app/data \
        docker.io/clusterzx/paperless-ai:latest

    podman run --pod paperless -dt \
        --replace --label=app=paperless \
        --restart=unless-stopped \
        --name stirlingpdf \
        -v stirling-training:/usr/share/tessdata \
        -v stirling-conf:/configs \
        -v stirling-custom:/customFiles \
        -v stirling-logs:/logs \
        -v stirling-pipelines:/pipeline \
        -e DISABLE_ADDITIONAL_FESTURES=true \
        -e LANGS=de_DE \
        docker.stirlingpdf.com/stirlingtools/stirling-pdf:latest

    # open necessary ports in firewalld if running
    if [[ "$(firewall-cmd --state)" == "running" ]]; then
        firewall-cmd --zone=public --add-port=8000/tcp --permanent
        firewall-cmd --zone=public --add-port=8001/tcp --permanent
        firewall-cmd --zone=public --add-port=8002/tcp --permanent
        firewall-cmd --reload
    fi
fi