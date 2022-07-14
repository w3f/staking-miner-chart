FROM docker.io/library/ubuntu:22.10
LABEL description="This is the 2nd stage: a very small image where we copy the binary."
LABEL io.parity.image.authors="devops@web3.foundation" \
	io.parity.image.vendor="Web 3.0 Technologies Foundation" \
	io.parity.image.title="${IMAGE_NAME}" \
	io.parity.image.description="${IMAGE_NAME} for substrate based chains" \
	io.parity.image.revision="${VCS_REF}" \
	io.parity.image.created="${BUILD_DATE}"

ARG POLKADOT_VERSION="v0.9.25"

RUN apt-get update && \
    apt-get install -y ca-certificates wget && \
	update-ca-certificates
RUN wget https://github.com/paritytech/polkadot/releases/download/${POLKADOT_VERSION}/staking-miner -O /usr/local/bin/staking-miner && \
    chmod +x /usr/local/bin/staking-miner

RUN useradd -u 1000 -U -s /bin/bash miner

# show backtraces
ENV RUST_BACKTRACE 1

USER miner

ENV SEED=""
ENV URI="wss://rpc.polkadot.io"
ENV RUST_LOG="info"

# check if the binary works in this container
RUN /usr/local/bin/staking-miner --version

ENTRYPOINT [ "/usr/local/bin/staking-miner" ]