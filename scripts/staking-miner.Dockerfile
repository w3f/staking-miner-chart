FROM lukemathwalker/cargo-chef:latest-rust-latest AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN apt-get update && apt-get install -y \
	build-essential lld pkg-config openssl libssl-dev gcc g++ clang make autoconf
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN cargo build --release --bin --package staking-miner

# ===== SECOND STAGE ======

FROM docker.io/library/ubuntu:20.04
LABEL description="This is the 2nd stage: a very small image where we copy the binary."
LABEL io.parity.image.authors="devops@web3.foundation" \
	io.parity.image.vendor="Web 3.0 Technologies Foundation" \
	io.parity.image.title="${IMAGE_NAME}" \
	io.parity.image.description="${IMAGE_NAME} for substrate based chains" \
	io.parity.image.revision="${VCS_REF}" \
	io.parity.image.created="${BUILD_DATE}"

ARG PROFILE=release
COPY --from=builder /app/target/$PROFILE/staking-miner /usr/local/bin

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