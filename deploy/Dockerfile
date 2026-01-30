FROM ruby:3.4

SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update

# Update RubyGems and Bundler
RUN echo "gem: --no-document" >> ~/.gemrc && \
    gem update --system

ARG brut_version
RUN gem install --version ${brut_version} mkbrut

ARG user_uid=10001
ARG user_gid=10002

# Create the user's group ID if it does not exist
RUN getent group ${user_gid} || groupadd --gid ${user_gid} appgroup
RUN useradd --uid ${user_uid} --gid ${user_gid} --create-home --home-dir /home/appuser appuser

# NOT including the group here as that will place the user's environment
# ONLY in that group and not in all the groups in which they are a part.
USER appuser

