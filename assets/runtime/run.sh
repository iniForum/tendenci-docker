#! /bin/bash

# set -o errexit
# set -o pipefail
# set -o nounset

PYTHON=$(which python3)

function setup_keys()
{
    echo "Creating secret keys"  && echo ""

    SECRET_KEY=${SECRET_KEY:-$(mcookie)}
    SITE_SETTINGS_KEY=${SITE_SETTINGS_KEY:-$(mcookie)}
    sed -i "s/^SECRET_KEY.*/SECRET_KEY='$SECRET_KEY'/" \
       "$TENDENCI_PROJECT_ROOT/conf/settings.py"
    echo "SECRET_KEY: $SECRET_KEY" && echo ""
    sed -i "s/^SITE_SETTINGS_KEY.*/SITE_SETTINGS_KEY='$SITE_SETTINGS_KEY'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"
    echo "SITE_SETTINGS_KEY: $SITE_SETTINGS_KEY" && echo ""
}

function create_settings
{
    echo "Creating settings"  && echo ""

     sed -i "s/^#DATABASES\['default'\]\['NAME'\].*/DATABASES\['default'\]\['NAME'\] = '${POSTGRES_DB:-tendenci}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/^#DATABASES\['default'\]\['HOST'\].*/DATABASES\['default'\]\['HOST'\] = '${POSTGRES_HOST:-localhost}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/^#DATABASES\['default'\]\['USER'\].*/DATABASES\['default'\]\['USER'\] = '${POSTGRES_USER:-tendenci}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/^#DATABASES\['default'\]\['PASSWORD'\].*/DATABASES\['default'\]\['PASSWORD'\] = '${POSTGRES_PASSWORD:-password}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/^#DATABASES\['default'\]\['PORT'\].*/DATABASES\['default'\]\['PORT'\] = '${POSTGRES_PORT:-5432}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/TIME_ZONE.*/TIME_ZONE='${TIME_ZONE:-GMT+0}'/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

     sed -i "s/ALLOWED_HOSTS =.*/ALLOWED_HOSTS = \[${ALLOWED_HOSTS:-'\*'}\]/" \
        "$TENDENCI_PROJECT_ROOT/conf/settings.py"

    echo "Finished creating settings" && echo ""
}


function create_superuser
{
    echo "Starting super user set-up" && echo ""

    cd "$TENDENCI_PROJECT_ROOT"
    echo "from django.contrib.auth import get_user_model; \
        User = get_user_model(); User.objects.create_superuser( \
        '${ADMIN_USER:-admin}', \
        '${ADMIN_MAIL:-admin@example.com}', \
        '${ADMIN_PASS:-password}')" \
        | "$PYTHON" manage.py shell

    echo "Finished super user set-up" && echo ""

}

function initial_setup
{

    echo  "Running Initial set up" && echo ""

    echo  "$TENDENCI_PROJECT_ROOT" && echo ""

    cd "$TENDENCI_PROJECT_ROOT"

    "$PYTHON" manage.py initial_migrate
    "$PYTHON" manage.py deploy
    "$PYTHON" manage.py load_tendenci_defaults
    "$PYTHON" manage.py update_dashboard_stats
    "$PYTHON" manage.py set_setting site global siteurl "$SITE_URL"

    create_superuser

    touch "$TENDENCI_PROJECT_ROOT/conf/site_initialized_flag"
    echo  "Initial set up completed" && echo ""

}


postgres_ready() {
    echo  "Testing postgres_ready" && echo ""

"$PYTHON" << END
import sys
import psycopg2

try:
    psycopg2.connect(
        dbname="${POSTGRES_DB}",
        user="${POSTGRES_USER}",
        password="${POSTGRES_PASSWORD}",
        host="${POSTGRES_HOST}",
        port="${POSTGRES_PORT}",
    )
except psycopg2.OperationalError:
    sys.exit(-1)
sys.exit(0)

END
}


function run
{
    echo  "***** Starting Tendenci Server ******* " && echo ""
    cd "$TENDENCI_PROJECT_ROOT" \
    && "$PYTHON" ./manage.py runserver 0.0.0.0:8000
}


if [ -z "${POSTGRES_USER}" ]; then
    base_postgres_image_default_user='postgres'
    export POSTGRES_USER="${base_postgres_image_default_user}"
fi

until postgres_ready; do
>&2 echo 'Waiting for Postgres Server >'${POSTGRES_HOST}'< to become available...'
sleep 1
done
>&2 echo 'Postgres Server '${POSTGRES_HOST}' is available'


if [ ! -f "$TENDENCI_PROJECT_ROOT/conf/site_initialized_flag" ]; then
     echo  "../conf/ does not contain signal file > site_initialized_flag" && echo ""
     setup_keys
     create_settings
     initial_setup
     run "$@"
fi

if [ -f "$TENDENCI_PROJECT_ROOT/conf/site_initialized_flag" ]; then
    run "$@"
fi
