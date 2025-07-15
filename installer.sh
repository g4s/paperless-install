#! /bin/bash

if [[ $(command -v podman) ]];  then
    podman pod create --replace \
        --restart=unless-stopped \
        --label=app=paperless \
        --network bridge \
        --name=paperless \
        --publish 8000:8000 \
        --publish 8001:3000

    podman volume create paperless-redis
    podman volume create paperless-database
    podman volume create paperless-ai

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
        --secret=paperless-postgress-pw,type=env,target=POSTGRES_PASSWORD \
        docker.io/library/postgres:17

    podman run --pod paperless -dt \
        --replace --label=app=paperless \
        --restart=unless-stopped \
        --name paperless-ai \
        -v paperless-ai:/app/data \
        docker.io/clusterzx/paperless-ai
fi