#! /bin/bash

if [[ $(command -v podman) ]];  then
    # loading configuration parameter
    # Parameter should be prefixed with PAPERLESS_
    if [[ -f /etc/sysconfig/paperless ]]; then
        source /etc/sysconfig/paperless
    fi

    # create pod
    podman pod create --replace \
        --restart=unless-stopped \
        --label=app=paperless \
        --label=dev.dozzle.group="${PAPERLESS_DOZZLE_GROUP}" \
        --label=tsdproxy.enable \
        --label=tsdproxy.name=dms \
        --network bridge \
        --name=paperless \
        --publish 8000:8000 \
        --publish 8001:3030 \
        --publish 8002:8080 \
        --publish 8003:3000 \
        --label=tsdproxy.enable=true

    # create volumes, if not exists
    volumes=(
        paperless-redis
        paperless-database
        paperless-ai
        paperless-data
        paperless-media
        stirling-training
        stirling-conf
        stirling-custom
        stirling-logs
        stirling-pipelines
        docuseal-data
        )
    for volume in "${volumes[@]}"; do
        if [[ $(podman volume exists "${volume}") -ne 0 ]]; then
            podman volume create "${volume}"
        fi
    done

    read -rsp "PostgreSQL database password: " DB_PASSWORD
    echo "${DB_PASSWORD}" | podman secret create paperless-postgres -

    if [[ $(podman secret exists paperless_secret_token) -ne 0 ]]; then
        echo "create secret token for paperless with openSSL"
        podman secrete create paperless_secret_token "$(openssl rand -base64 32)"
        echo "created token paperless_secret_token"
    fi

    read -rsp "Enter paperless-ngx password: " PAPERLESS_ADMIN_PWD

    if [[ ! -d "${PAPERLESS_CONSUME}" ]]; then
        mkdir -p "${PAPERLESS_CONSUME}"
    fi

    if [[ ! -d "${PAPERLESS_EXPORT}" ]]; then
        mkdir -p "${PAPERLESS_EXPORT}"
    fi

    if [[ ! -z $PAPERLESS_TIME_ZONE ]]; then
        PAPERLESS_TIME_ZONE=$(timedatectl show | grep Timezone | cut -d "=" -f2)
    fi

    if [[ ! -z $PAPERLESS_SCRIPTS ]]; then
        PAPERLESS_SCRIPTS="$(pwd)/scripts"
        mkdir -p "$(pwd)/scripts"
    fi

    ####
    # spawn container
    podman run --pod paperless -dt \
        --replace --restart=unless-stopped \
        --label=app=paperless \
        --label=dev.dozzle.group="${PAPERLESS_DOZZLE_GROUP}" \
        --name tika \
        docker.io/apache/tika:latest

    podman run --pod paperless -dt \
        --replace --restart=unless-stopped \
        --label=app=paperless \
        --label=dev.dozzle.group="${PAPERLESS_DOZZLE_GROUP}" \
        --name gotenberg \
        gotenberg docker.io/gotenberg/gotenberg:8.20 \
        gotenberg --api-port=3030

    podman run --pod paperless -dt \
        --replace --restart=unless-stopped \
        --label=app=paperless \
        --label=dev.dozzle.group="${PAPERLESS_DOZZLE_GROUP}" \
        --name db \
        -v paperless-database:/var/lib/postgresql/data \
        -e POSTGRES_DB=paperless \
        -e POSTGRES_USER=paperless \
        --secret=paperless-postgres,type=env,target=POSTGRES_PASSWORD \
        docker.io/library/postgres:17

    podman run --pod paperless -dt \
        --replace --restart=unless-stopped \
        --label=app=paperless \
        --label=dev.dozzle.group="${PAPERLESS_DOZZLE_GROUP}" \
        --name wenbserver \
        -v paperless-data:/usr/src/paperless/data: \
        -v paperless-media:/usr/src/paperless/media \
        -v "${PAPERLESS_CONSUME}":/usr/src/paperless/consume:Z \
        -v "${PAPERLESS_EXPORT}":/usr/src/paperless/export:Z \
        -v "${PAPERLESS_DATA}":/usr/src/paperless/data:Z \
        -v "${PAPERLESS_SCRIPTS}":/usr/bin/scripts:Z \
        -e PAPERLESS_REDIS=redis://broker:637 \
        -e PAPERLESS_DBHOST=db \
        -e PAPERLESS_DBUSER=paperless \
        --secret=paperless-postgres-pw,type=env,target=PAPERLESS_DBPASS \
        -e PAPERLESS_DBNAME=paperless \
        -e PAPERLESS_EMAIL_PARSE_DEFAULT_LAYOUT=2 \
        --secret=paperless_secret_token,type=env,target=PAPERLESS_SECRET_KEY \
        -e PAPERLESS_URL=${PAPERLESS_URL:-"localhost"} \
        -e PAPERLESS_ADMIN_USER="${PAPERLESS_ADMIN_USER:-admin}" \
        -e PAPERLESS_AMDIN_PASSWORD="${PAPERLESS_ADMIN_PWD}" \
        -e PAPERLESS_ACCOUNT_ALLOW_SIGNUPS=False \
        -e PAPERLESS_TIME_ZONE="${PAPERLESS_TIME_ZONE}" \
        -e USERMAP_UID="$(id -u)" \
        -e USERMAP_GID="$(id -g)" \
        -e PAPERLESS_TIKA_ENABLED=1 \
        -e PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3030 \
        -e PAPERLESS_TIKA_ENDPOINT=http://tika:9998 \
        ghcr.io/paperless-ngx/paperless-ngx:latest

    podman run --pod paperless -dt \
        --replace --label=app=paperless \
        --label=dev.dozzle.group="${PAPERLESS_DOZZLE_GROUP}" \
        --restart=unless-stopped \
        --name paperless-ai \
        -v paperless-ai:/app/data \
        docker.io/clusterzx/paperless-ai:latest

    # adding stirlingPDF to techstack
    podman run --pod paperless -dt \
        --replace --label=app=paperless \
        --label=dev.dozzle.group="${PAPERLESS_DOZZLE_GROUP}" \
        --restart=unless-stopped \
        --name stirlingpdf \
        -v stirling-training:/usr/share/tessdata \
        -v stirling-conf:/configs \
        -v stirling-custom:/customFiles \
        -v stirling-logs:/logs \
        -v stirling-pipelines:/pipeline \
        -e DISABLE_ADDITIONAL_FATURES=true \
        -e LANGS=de_DE \
        docker.stirlingpdf.com/stirlingtools/stirling-pdf:latest

    # adding DocuSeal to techstack
    # https://www.docuseal.com/docs/configuring-docuseal-via-environment-variables
    # https://www.docuseal.com/docs/configuring-saml-with-authentic
    podman run --pod paperless -dt \
        --replace --label=app=paperless \
        --label=dev.dozzle.group="${PAPERLESS_DOZZLE_GROUP}" \
        --restart=unless-stopped \
        -v docuseal-data:/data \
        --name docuseal \
        docker.io/docuseal/docuseal

    # open necessary ports in firewalld if running
    if [[ "$(firewall-cmd --state)" == "running" ]]; then
        firewall-cmd --zone=public --add-port=8000/tcp --permanent
        firewall-cmd --zone=public --add-port=8001/tcp --permanent
        firewall-cmd --zone=public --add-port=8002/tcp --permanent
        firewall-cmd --zone=public --add-port=8003/tcp --permanent
        firewall-cmd --reload
    fi
fi