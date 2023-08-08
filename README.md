# Docker Tendenci
modified for iniForum by rjd 3/9/2021, 5:53:50 PM

This docker replaces earlier my versions that were based on the phusion container.
Now we use the assets install and run scripts of tendenci12-dockerized.
However the build is modied in the following ways:

1. install.sh does not build the project / mysite directory automatically. Instead the project (mysite) directory is copied from this (./) development directory into the container in the Dockerfile. That means that the state of ./mysite becomes the state of the tendenci container.
2. this copy is done before the install.sh runs, therefore install.sh makes use of the ./mysite/requirements rather than the standard tendenci requirements. In this way our customized requirements are loaded into the tendenci container.
3. The version of tendenci that is installed is set in requirements/common.txt to be our forked (customized) version at https://github.com/iniForum/tendenci.git, rather than the latest tendenci release. SO, if you need to incorporate the standard tendenci release, you must first do a 'git upstream pull' on our version.
4. I have set the project root directory to /var/www/project to maintain backwards compatility with my older tendenci dockers, which are currently running on most of our sites.

*** BEWARE: the container will attempt a fresh install unless it finds a 'system_is_initialized' dummy file in project/conf. SO, if you wish to run this docker against an existing database, be sure, first, to "touch system_is_initialized" in the project/conf that will be mounted.

*** NOTE: when the container is started, it runs script run.sh.  Amongst other things, this script tests whether the appropriate postgis database is running. The check depends on the following Environmennt Variables which MUST be declared in the docker-compose script used to start the container (eg compose-tendenci.yml). The values of thesevariables are usually decalred in the local .env file. The run.sh script cannot pull them directly from .env file. The docker-compose script does that.
POSTGRES_USER, POSTGRES_DB, POSTGRES_PASSWORD, POSTGRES_PORT, POSTGRES_HOST.

The compose-tendenci.yml volumes contains a commented-out entry that allows a development version of tendenci to be mounted over the current version in the container. The development version is at ../tendenci-git. That version is cloned from <https://github.com/iniForum/tendenci.git>.

So the developmental workflow is

  1. mount ../tendenci-git
  2. directly edit ../tendenci-git (the effects are immediately visible in the running container).
  3. When all is well, commit and push ../tendenci-git
  4. unmount ../tendenci-git
  5. rebuild this tendenci image, which will then incorporate the tendenci mods (as well as any other mods that have been made inside mysite.)


## Docker Tendenci  ---------- from tencenci/tendenci12-dockerized

*This repo was originally transferred from @jucajuca. Thanks @jucajuca!*.

Docker file and docker-compose file to launch a tendenci instance.

Original notes as below:

## Installation

Install docker and git in your system

```bash
git clone https://github.com/tendenci/tendenci12-dockerized.git
``````

## Usage

Rename the .env.sample file to .env
Edit the .env file and adjust your settings

```bash
docker build --no-cache=true --rm -t tendenci .
docker-compose up -d
``````

Do not forget the dot at the end of docker build

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.


Based on : https://github.com/frenchbeard/docker-tendenci

## License
[MIT](https://choosealicense.com/licenses/mit/)
