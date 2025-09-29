# This is a multi-stage build, meaning one image will be built that
# has necessarily dev tools in it, and that image is used to create artifacts
# that will be copied into the second build, which will create the image
# you deploy to production.
#
# # Maintaing this file
#
# You own this file now.  While there could be a way to create it from
# the Dockerfile.dx, for now, you'll need to stay on top of it:
#
# 1 - ensure the versions of Ruby match
# 2 - ensure the versions of NodeJS match
# 3 - ensure that anything you installed in Dockerfile.dx to make 
#     the app work or to pre-generate assets is set up here as well.
#     You are advised to make that setup identical.
#
# You can test this locally but using the `--plaform` flag to `bin/deploy deploy`
# and running a container locally.  You'll need all infrastructure available
# but it can be done to test things before you deploy. If you need to.

# Use Ruby 3.4 as a base.
FROM docker.io/library/ruby:3.4 AS base

# bin/deploy will inject this value so that your app's GIT SHA1
# is in the environment in production, thus allowing you to be more
# sure of what's actually running.
ARG app_git_sha1

WORKDIR /brut-app

# Install base packages
#
# - ca-certificates is needed for other installs 
# - curl is needed generally for other installs and by Heroku
# - gnupg is a PGP replacement used in making sure new APT repos work
# - libjemalloc2 in theory speeds up Ruby
# - lsb-release is used to generically access information for this OS's version
# - wget allows us to copy/paste commands from vendors about how to install
#   software even though it does the same thing as curl
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update --quiet --yes && \
    apt-get install --no-install-recommends --quiet --yes \
      ca-certificates \
      curl \
      gnupg \
      libjemalloc2 \
      lsb-release \
      postgresql-common \
      rsync \
      wget

# Install the PostgreSQL client.  The latest version is not available
# from Debian, so we set up our own. This should match what's in Dockerfile.dx
# and ideally the version of Postgres used in production.
#
# Incancation is based on: https://www.postgresql.org/download/linux/debian/
RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \
    apt-get update --quiet --yes && \
    apt-get --yes --quiet --no-install-recommends install postgresql-client-16 && \
		rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Set basic env vars for production
ENV RACK_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# This makes a new image that we'll throw away after building
# needed artifacts.
FROM base AS build

# - build-essential is needed for almost any build tool we have to install
# - git is needed to install some things
# - libpq-dev is needed by postgres
# - pkg-config is, I guess, not considered "essential" (as in build-essential),
#   but still needed to install downstream stuff
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update --quiet --yes && \
    apt-get install --no-install-recommends --quiet --yes \
			build-essential \
			git \
      libpq-dev \
			pkg-config

# Copy NodeJS from the official image. This should be faster than
# installing it via e.g. nvm
COPY --from=node:22-slim /usr/local /usr/local

# Copy Gemfile only as it may not change between deploys
COPY Gemfile Gemfile.lock .

# Install RubyGems from app's Gemfile
RUN --mount=type=cache,target=${BUNDLE_PATH}/cache \
    bundle install --verbose && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY package.json package-lock.json ./
# Install Node Modules from package.json
RUN npm clean-install --no-audit --no-fund --verbose

COPY . .

# Build all assets
RUN bin/build-assets && \
    rm -rf node_modules

# We are now switching back to building the image that will be deployed.

FROM base
# Copy built artifacts from the throwaway image: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /brut-app /brut-app

# For security, set directories that will be written to be owned by non-root
RUN groupadd --system --gid 1000 brut && \
    useradd brut --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R brut:brut logs tmp
USER 1000:1000

ENV APP_GIT_SHA1="${app_git_sha1}"

# This is used to execute other commands.  When the app is run in production,
# this script is used to run it.
ENTRYPOINT ["/brut-app/deploy/docker-entrypoint"]
