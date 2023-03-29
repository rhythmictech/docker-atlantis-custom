# source: https://gist.github.com/nitrocode/62505b0623cd9bf27e4b39a3f98412f5

# https://github.com/runatlantis/atlantis/tags
ARG ATLANTIS_VERSION=0.23.3

# https://github.com/aws/aws-cli/tags
ARG AWS_CLI_VERSION=2.11.6

# https://hub.docker.com/_/python/tags?page=1&name=alpine
ARG PYTHON_ALPINE_VERSION=3.10.10-alpine3.17

FROM python:${PYTHON_ALPINE_VERSION} as builder

ARG AWS_CLI_VERSION
RUN apk add --no-cache \
      git \
      unzip \
      groff \
      build-base \
      libffi-dev \
      cmake \
    && git clone \
        --single-branch \
        --depth 1 \
        -b ${AWS_CLI_VERSION} \
        https://github.com/aws/aws-cli.git

WORKDIR /aws-cli

# shellcheck disable=SC1091
RUN python -m venv venv \
    && . venv/bin/activate \
    && scripts/installers/make-exe \
    && unzip -q dist/awscli-exe.zip \
    && aws/install --bin-dir /aws-cli-bin \
    && /aws-cli-bin/aws --version

# reduce image size: remove autocomplete and examples
RUN rm -rf \
      /usr/local/aws-cli/v2/current/dist/aws_completer \
      /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
      /usr/local/aws-cli/v2/current/dist/awscli/examples \
    && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data \
      -name examples-1.json \
      -delete

# build the final image
FROM ghcr.io/runatlantis/atlantis:v${ATLANTIS_VERSION}

LABEL org.opencontainers.image.source="https://github.com/rhythmictech/docker-atlantis-custom"

COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /aws-cli-bin/ /usr/local/bin/
