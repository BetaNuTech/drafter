# Summary

### Drafter (c)2022 Bluestone Properties

Draw Requests for constructed multi-family properties, working along side ClickUp for reviews

# Development 

FIRST!:
* Install docker, docker-compose
* Create `.env` file based on `env.example` (Ask for development `RAILS_MASTER_KEY` value from other developer)
* First time use/setup:
```
docker-compose build
docker-compose run web rake db:setup db:schema:load db:seed
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
* Fix local file permissions after running a Rails generator within a Docker container: `bin/fix_perms`
  * NOTE: files generated using docker will be owned by root. You will have to change file ownership manually.

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

# Testing

## Creating Tests

Tests are written for `rspec` and are present in the `rspec` directory.

## Automatic Testing with 'Guard'

The `guard` command launches a test suite which automatically runs tests when associated files are created or updated.

In a dedicated terminal window, launch `guard` with the following commmand:

```
docker-compose run test bundle exec guard
```

You may enter the letter `a` then press enter to instruct `guard` to run all tests one time.

Type `exit` or press `CTRL-C` to exit


## Running Tests Manually

Run the following command to run the test suite:

```
docker-compose run test bundle exec rspec
```

### Test Code Coverage

Manually running the test suite will automatically generate a test coverage report.

Open `http://localhost:3000/coverage/` (be sure to include the trailing slash)

The `simplecov` tool automatically determines the code coverage of the test suite. After `rspec` is run, open the
URL `http://localhost:3000/` to view an HTML report of code coverage that is output to the `coverage` folder. 
Docker Compose is configured to store the code coverage files in a data volume mounted at `/coverage` in the test
container and `/public/coverage` in the web container.


# Credentials/Secrets

Credentials are stored encrypted at `config/credentials/ENVIRONMENT.yml.enc`
Rails uses the `RAILS_MASTER_KEY` environment variable to decrypt this file.

In development, store the master key in `.env`

Edit credentials/secrets with:
`docker-compose run -e RAILS_MASTER_KEY=XXXX web rails credentials:edit --environment development`

`docker-compose run -e RAILS_MASTER_KEY=XXXX web rails credentials:edit --environment production`

# Email

## Development

In development the mail handler is "letter opener".

Go to `http://localhost:3000/letter_opener` to view outgoing emails

# Background Workers

Background jobs are handled using DelayedJob backed by the default database.
A logged-in administrator has access to a web interface to observe jobs at `/delayed_job`

In development, there is a dedicated worker service/container which runs `bin/delayed_job`.

For more information, see: `https://github.com/collectiveidea/delayed_job`

# ActiveStorage / Object Storage

In development, local file storage is used by default.

For testing the Amazon S3 bucket used by the staging environment add the following line to `.env`

```
USE_S3_IN_DEVELOPMENT=true
```

# Staging

Drafter Staging is hosted on Heroku.

URL: `https://drafter-staging.heroku.com`
Control Panel: `https://dashboard.heroku.com/apps/drafter-staging`

## Heroku Config

* Region: United States
* Stack: heroku-22
* Frameworks: NONE
* Git URL: `https://git.heroku.com/drafter-staging.git`

## Buildpacks

1. heroku-community/apt
2. heroku/ruby

See `Aptfile` for managing system dependencies installed by the Apt buildpack

## Services/Resources

* Web Dyno x1 -- Hobby
* Worker Dyno x1 -- Hobby

### Addons

* Heroku Postgres -- Hobby
* Twilio Sendgrid -- Free

### Database 

* Service: Heroku Postgres:
* Plan: Hobby Dev
* Resource Name: `postgresql-angular-94031`
* Quota: 10,000 rows

### Email

Twilio Sendgrid

### Object Storage

Amazon S3

### Invoice Analysis

AWS Textract
AWS SNS
AWS SQS

## Initial Staging Setup

### 1. Setup Twilio

* Go to the Twilio control panel from the drafter-staging Resources page
* Create a 'Single Sender'
* Create a Restricted API key with just the 'Mail Send' permission
* Update the smtp_password in the staging credentials using the API key. Get production master key from lead developer.
  * `RAILS_MASTER_KEY=XXX rails credentials:edit --environment production`

### 2. Set Host Environment Variables

```
RAILS_MASTER_KEY=XXX # get from lead developer
APPLICATION_HOST=drafter-staging.herokuapp.com
APPLICATION_PROTOCOL="https"
APPLICATION_DOMAIN=drafter-staging.herokuapp.com
APPLICATION_ENV=staging
LANG=en_US.UTF-8
RACK_ENV=production
RAILS_ENV=production
RAILS_MAX_THREADS=5
RAILS_SERVE_STATIC_FILES=enabled
WEB_CONCURRENCY=2
```

Run to set Heroku environment variables:
```
heroku config:set \
  RAILS_MASTER_KEY=XXX \
  APPLICATION_HOST=drafter-staging.herokuapp.com APPLICATION_PROTOCOL=http PORT=80 \
  APPLICATION_DOMAIN=drafter-staging.herokuapp.com APPLICATION_ENV=staging \
  LANG=en_US.UTF-8 RACK_ENV=production RAILS_ENV=production RAILS_MAX_THREADS=5 \
  RAILS_SERVE_STATIC_FILES=enabled WEB_CONCURRENCY=2 \
  --app drafter-staging
```

### 3. Setup Deployment Configuration

On your development/deployment machine:

* Add a 'heroku-staging' git remote: `git remote add heroku-staging https://git.heroku.com/drafter-staging.git`
* Update `bin/deploy_heroku` variables for staging/production application names if needed (and commit changes)
* Update `staging` branch. `git checkout staging && git reset --hard main && git push`

### 4. Add Heroku Ruby Buildpack

Go to the Settings tab in the application control panel, and add the `heroku/ruby` buildpack.

### 4. Deploy

`bin/deploy_heroku staging`

### 5. Setup SSL

* Setup SSL in Settings tab of control panel
* Update Environment Variables

```
APPLICATION_PROTOCOL=https
PORT=443
```

```
heroku config:set APPLICATION_PROTOCOL=https PORT=443 --app drafter-staging
```
