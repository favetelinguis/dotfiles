https://devhints.io/docker-compose
### Start a upp and get into my devenv
If we change something
docker compose build 
docker compose up -d
docker compose ps
docker compose exec dev-env /bin/bash

To attache to a shell and start a single service
docker-compose run --rm dev-env

run vs up?