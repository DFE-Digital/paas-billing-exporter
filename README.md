# PaaS Billing Exporter

[Prometheus exporter](https://prometheus.io/docs/instrumenting/exporters/) exposing cost metrics fetched from [paas-billing](https://github.com/alphagov/paas-billing). The data is aggregated by space and resource type (app or service).

## Run locally

### Requirements
- ruby (see .ruby-version)
- [Cloud Foundry cli](https://github.com/cloudfoundry/cli)
- PaaS user with BillingManager role at least

### Set up
- Run `bundle`

### Start with manual login
- Login manually to PaaS with cf cli
- `SKIP_LOGIN=true make start`

### Start with automated login
- Your user must be able to login via username and password (ie no SSO)
- `PAAS_USERNAME=<username> PAAS_PASSWORD=<password> make start`

### Access metrics
http://localhost:8080/metrics

### Run tests
- `make test`
- `make lint`
