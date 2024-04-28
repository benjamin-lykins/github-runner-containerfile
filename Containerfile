FROM ubuntu:22.04

ARG RUNNER_VERSION="2.316.0"
# Only linux in this case, windows containers are probably possible, but not tested.
ARG RUNNER_IMAGE="linux"
# Either x64 or arm64 or arm
ARG RUNNER_ARCH="arm64"

# Echo the argument
RUN echo "Runner Architecture : ${RUNNER_ARCH}"
RUN echo "Runner Version : ${RUNNER_VERSION}"
RUN echo "Runner Image : ${RUNNER_IMAGE}"
RUN echo "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-${RUNNER_IMAGE}-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

# Prevents installdependencies.sh from prompting the user and blocking the image creation
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update -y && apt upgrade -y && useradd -m runner
RUN apt install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip unzip libicu


RUN cd /home/runner && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-${RUNNER_IMAGE}-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-${RUNNER_IMAGE}-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz

RUN chown -R runner ~runner && /home/runner/actions-runner/bin/installdependencies.sh

COPY start.sh start.sh

# make the script executable
RUN chmod +x start.sh

# since the config and run script for actions are not allowed to be run by root,
# set the user to "runner" so all subsequent commands are run as the runner user
USER runner

ENTRYPOINT ["./start.sh"]
