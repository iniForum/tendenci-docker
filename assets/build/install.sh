#! /bin/bash

# Environment
PIP=$(which pip3)
PYTHON=$(which python3)

# Check directories and create them if necessary
function check_dirs()
{
    for dir in $TENDENCI_INSTALL_DIR\
        $TENDENCI_LOG_DIR;
do
    [ -d "$dir" ] || mkdir "$dir"
    chown "$TENDENCI_USER:" "$dir"
done
}

# Check user to run the application, create it if not done yet
function check_user()
{
    if ! grep -i "^$TENDENCI_USER" /etc/passwd; then
        useradd -b "$TENDENCI_HOME" -U "$TENDENCI_USER"
    fi
}


function install_tendenci()
{
    # Installing tendenci
    echo "Installing tendenci" && echo ""

# install site from tendenci project template, and use tendenci's requirements
#    cd "$TENDENCI_INSTALL_DIR"
#    $PIP install --no-cache-dir tendenci
#    tendenci startproject "$APP_NAME" "$APP_NAME"
#    cd "$APP_NAME"

# install site from exisiting rjd project, copied into Dockerfile, and use those requirements
    cd "$TENDENCI_PROJECT_ROOT"
    $PYTHON -m pip install --no-cache-dir --upgrade pip
    $PYTHON -m pip install --no-cache-dir --upgrade -r requirements/dev.txt


    #Install theme
    echo "Installing theme" && echo ""
    mkdir "$TENDENCI_PROJECT_ROOT"/themes/tendenci2020
    cd "$TENDENCI_INSTALL_DIR"
    PACKAGE_ORIGIN=$(pip3 show tendenci | grep Location:)
    THEME_ORIGIN=${PACKAGE_ORIGIN//"Location: "/}"/tendenci/themes/t7-tendenci2020"
    cd $THEME_ORIGIN
    cp -r ./* "$TENDENCI_PROJECT_ROOT"/themes/tendenci2020

    # Preparing directories
    echo "Preparing directories" && echo ""
    mkdir "$TENDENCI_PROJECT_ROOT"/static
    chown "$TENDENCI_USER:" /var/log/"$APP_NAME"/
    chmod -R -x+X,g+rw,o-rwx /var/log/"$APP_NAME"/

# rjd === inserted to solve the /var/log/tendenci/ error
#    chown "$TENDENCI_USER:" /var/log/tendenci/
#    chmod -R -x+X,g+rw,o-rwx /var/log/tendenci/

    chown -R "$TENDENCI_USER:" "$TENDENCI_HOME"
    chmod -R -x+X,g-w,o-rwx "$TENDENCI_PROJECT_ROOT"/
    chmod +x                "$TENDENCI_PROJECT_ROOT"/manage.py
    chmod -R ug-x+rwX,o-rwx "$TENDENCI_PROJECT_ROOT"/media/
    chmod -R ug-x+rwX,o-rwx "$TENDENCI_PROJECT_ROOT"/themes/
    chmod -R ug-x+rwX,o-rwx "$TENDENCI_PROJECT_ROOT"/whoosh_index/

}

function create_cronjobs()
{

    echo "Creating cronjobs" && echo ""
    (crontab -l ; echo "30   2 * * * $PYTHON $TENDENCI_PROJECT_ROOT/manage.py run_nightly_commands") | crontab -
    (crontab -l ; echo "30   2 * * * $PYTHON $TENDENCI_PROJECT_ROOT/manage.py process_unindexed") | crontab -

}

check_user
check_dirs
install_tendenci
create_cronjobs
