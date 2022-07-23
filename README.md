# Summary

### Drafter (c)2022 Bluestone Properties

Draw Requests for constructed multi-family properties, working along side Asana for reviews

# Development 

FIRST!:
* Install docker, docker-compose
* Create `.env` file based on `env.example` (Ask for development `RAILS_MASTER_KEY` value from other developer)
* First time use/setup:
```
docker-compose build
docker-compose run web rake db:setup db:migrate db:seed`
docker-compose run test rake db:test:prepare
```

## General Use Commands

* Start the stack: `docker-compose up`
* Stop the stack `docker-compose down`
* Run tests: `docker-compose run test rspec` for a single run -or- `docker-compose run test guard` to continuously test
* View/tail logs `docker-compose run web bin/tail_logs`
* Run a command against a service: `docker-compose run web XXXX`
  * Open a console: `docker-compose run web rails console`
  * Open a database console: `docker-compose run web rails dbconsole`

NOTE: files generated using docker will be owned by root. You will have to change file ownership manually.
From the project root directory: `sudo chown -R $USER:$USER ./`

## Dependencies

### Native

* Ruby version 3.1.2
* NodeJS version 16
* PostgreSQL version 14

### Docker

* Docker
* Docker Compose

### Cleanup

* List running containers: `docker ps`
* Stop running containers: `docker stop XXX`
* Stop the stack and remove containers: `docker-compose down`
* Delete data volumes: `docker volume ls | grep drafter | awk '{print $2}' | xargs docker volume rm`
* Delete webapp image: `docker images | grep drafter-dev | awk '{print $3}' | xargs docker rm`

# Credentials/Secrets

Credentials are stored encrypted at `config/credentials/ENVIRONMENT.yml.enc`
Rails uses the `RAILS_MASTER_KEY` environment variable to decrypt this file.

In development, store the master key in `.env`

Edit credentials/secrets with:
`RAILS_MASTER_KEY=XXXX rails credentials:edit --environment development`

`RAILS_MASTER_KEY=XXXX rails credentials:edit --environment production`

# Email

## Development

In development the mail handler is "letter opener".

Go to `http://localhost:3000/letter_opener` to view outgoing emails

# Background Workers

Background jobs are handled using DelayedJob backed by the default database.
A logged-in administrator has access to a web interface to observe jobs at `/delayed_job`

In development, there is a dedicated worker service/container which runs `bin/delayed_job`.

For more information, see: `https://github.com/collectiveidea/delayed_job`

