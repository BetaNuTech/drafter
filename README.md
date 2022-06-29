# Summary

### Drafter (c)2022 Bluestone Properties

Draw Requests for constructed multi-family properties, working along side Asana for reviews

# Development 

## General Use Commands

* First time use/setup: `docker-compose build; docker-compose run web rake db:setup db:migrate db:seed`

* Start the stack: `docker-compose up`
* Run tests: `docker-compose run web rspec`
* Run a command against a service: `docker-compose run web XXXX`
  * Open a console: `docker-compose run web rails console`
  * Open a database console: `docker-compose run web rails dbconsole`
* View/tail logs `tail -f log/*.log`

NOTE: files generated using docker will be owned by root. You will have to change file ownership manually.

## Dependencies

### Native

* Ruby version 3.1.2
* NodeJS version 16
* PostgreSQL version 14

### Docker

* Docker
* Docker Compose

## Docker

* Install docker, docker-compose
* Create `.env` file based on `env.example` (Ask for development `RAILS_MASTER_KEY` value from other developer)

### Cleanup

* List running containers: `docker ps`
* Stop running containers: `docker stop XXX`
* Clean up stopped containers: `docker system prune` (this affects all containers on the system, not just drafter)
* Delete image: `docker images | grep drafter-dev | awk '{print $3}' | xargs docker rm`
* Delete volumes: `docker volume ls` `docker volume rm XXX`

# Credentials/Secrets

Credentials are stored encrypted at `config/credentials/ENVIRONMENT.yml.enc`
Rails uses the `RAILS_MASTER_KEY` environment variable to decrypt this file.

In development, store the master key in `.env`

Edit credentials/secrets with:
`RAILS_MASTER_KEY=XXXX rails credentials:edit --environment development`

`RAILS_MASTER_KEY=XXXX rails credentials:edit --environment production`

# Docker Development Environment

* Install docker and docker-compose


