PORT ?= 8080
IMAGE_TAG ?= latest

test:
	@rspec -f doc

lint:
	@rubocop --require rubocop-rspec

start:
	@rackup -o 0.0.0.0 -p ${PORT}

build:
	docker buildx build -t ghcr.io/dfe-digital/paas-billing-exporter:${IMAGE_TAG} \
		--cache-to=type=inline \
		--cache-from ghcr.io/dfe-digital/paas-billing-exporter:${IMAGE_TAG} \
		--cache-from ghcr.io/dfe-digital/paas-billing-exporter:main \
		.

push:
	docker push ghcr.io/dfe-digital/paas-billing-exporter:${IMAGE_TAG}

docker-run:
	docker run -ti -e PAAS_USERNAME=${PAAS_USERNAME} -e PAAS_PASSWORD=${PAAS_PASSWORD} \
	-p 8080:8080 \
	ghcr.io/dfe-digital/paas-billing-exporter:${IMAGE_TAG}
