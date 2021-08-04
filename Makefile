PORT ?= 8080

test:
	@rspec -f doc

lint:
	@rubocop --require rubocop-rspec

start:
	@rackup -p ${PORT}
