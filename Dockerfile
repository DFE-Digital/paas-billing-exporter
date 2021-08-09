FROM ruby:3.0.2-alpine3.14

ENV CF_CLI_VERSION v7

RUN wget -O - "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github&version=${CF_CLI_VERSION}" \
    | tar -zx -C /usr/local/bin

COPY Gemfile* .

RUN apk update
RUN apk add libc-dev make gcc

RUN bundle config set --local without 'development'
RUN bundle

COPY Makefile config.ru billing.rb .

CMD make start
