# Summary

### Drafter (c)2022 Bluestone Properties

Draw Requests for constructed multi-family properties, working along side Asana for reviews

# Development Setup

## Dependencies

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

# Docker Environment

**Reference**
* https://evilmartians.com/chronicles/ruby-on-whales-docker-for-ruby-rails-development
* https://github.com/evilmartians/ruby-on-whales
