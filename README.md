# PaaS Billing Exporter

[Prometheus exporter](https://prometheus.io/docs/instrumenting/exporters/) exposing cost metrics fetched from
[paas-billing](https://github.com/alphagov/paas-billing). The data is aggregated by space and resource type (app or service).

## Run locally

### Requirements
- ruby (see .ruby-version)
- [Cloud Foundry cli](https://github.com/cloudfoundry/cli)
- PaaS user with BillingManager role at least
- Docker (to build the image)
- Github Personal Access Token (PAT) with write access to the repository packages (to push to the docker registry)
- PaaS user with SpaceDeveloper role (to deploy to PaaS)

### Set up
- Run `bundle`

### Start with manual login
- Login manually to PaaS with cf cli
- `SKIP_LOGIN=true make start`

### Start with automated login
- Your user must be able to login via username and password (ie no SSO)
- `PAAS_USERNAME=<PAAS_USERNAME> PAAS_PASSWORD=<PAAS_PASSWORD> make start`

### Start with byebug enabled
- Add `dev` in the command
- `[...] make dev start`

### Access metrics
http://localhost:8080/metrics

### Run tests
- `make test`
- `make lint`

## Docker image
### Build
- Use default tag: `latest`
  ```
  make build
  ```
- Tag with commit id
  ```
  make build IMAGE_TAG=0c564603f492f64f1c5bb824beec855f3a756972
  ```
- Tag with branch name
  ```
  make build IMAGE_TAG=bug-fix
  ```

### Push to Github container registry
- Login to the registry
  ```
  echo $PAT | docker login ghcr.io -u - --password-stdin
  ```
- Push
  ```
  make push IMAGE_TAG=<IMAGE_TAG>
  ```

## Deploy to PaaS
- Deploy
  ```
  cf push --no-start --docker-image ghcr.io/dfe-digital/paas-billing-exporter:<IMAGE_TAG> paas-billing-exporter
  cf set-env paas-billing-exporter PAAS_USERNAME=<PAAS_USERNAME>
  cf set-env paas-billing-exporter PAAS_PASSWORD=<PAAS_PASSWORD>
  cf start paas-billing-exporter
  ```
- Access the metrics: https://paas-billing-exporter.london.cloudapps.digital/metrics
