# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.4.4
FROM ruby:$RUBY_VERSION

WORKDIR /rails

RUN mkdir -p /usr/local/bundle && chmod -R 777 /usr/local/bundle

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libvips \
      nodejs \
      yarn \
      postgresql-client \
      curl \
      libjemalloc2 \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_DEPLOYMENT="1"

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3000

RUN bundle exec bootsnap precompile app/ lib/
