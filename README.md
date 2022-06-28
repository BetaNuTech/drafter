# Summary

Drafter (c)2022 Bluestone Properties

# Development Setup

*Dependencies*

* Ruby version 3.1.2
* NodeJS version 16
* PostgreSQL version 14

# Credentials/Secrets

Credentials are stored encrypted at `config/credentials/ENVIRONMENT.yml.enc`
Rails uses the `RAILS_MASTER_KEY` environment variable to decrypt this file.

In development, store the master key in `.env`

Edit credentials/secrets with:
`RAILS_MASTER_KEY=XXXX rails credentials:edit --environment development`
`RAILS_MASTER_KEY=XXXX rails credentials:edit --environment production`

