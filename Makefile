PORT ?= 8080
IMAGE_TAG ?= latest

test:
	@bundle exec rspec -f doc

lint:
	@bundle exec rubocop --require rubocop-rspec

.PHONY: dev
dev:
	$(eval RACKUP_REQUIRE=-rbyebug)

start:
	@rackup -o 0.0.0.0 -p ${PORT} ${RACKUP_REQUIRE}

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
