FROM rustlang/rust:nightly-trixie AS build

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apt-get update && apt-get install -y musl-tools

RUN case ${TARGETPLATFORM} in \
    "linux/amd64")  echo "x86_64-unknown-linux-musl" > /tmp/rust_target ;; \
    "linux/arm64")  echo "aarch64-unknown-linux-musl" > /tmp/rust_target ;; \
    "linux/arm/v7") echo "armv7-unknown-linux-musleabihf" > /tmp/rust_target ;; \
    *)              echo "x86_64-unknown-linux-musl" > /tmp/rust_target ;; \
    esac && \
    TARGET=$(cat /tmp/rust_target) && \
    echo "Building for target: $TARGET" && \
    rustup target add $TARGET

RUN rustc --version && \
    rustup --version && \
    cargo --version

WORKDIR /app
COPY . /app

RUN TARGET=$(cat /tmp/rust_target) && \
    cargo clean && \
    cargo build --release --target $TARGET && \
    strip ./target/$TARGET/release/vigil && \
    cp ./target/$TARGET/release/vigil /tmp/vigil

FROM alpine:latest

ARG TARGETPLATFORM

WORKDIR /usr/src/vigil

COPY ./res/assets/ ./res/assets/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /tmp/vigil /usr/local/bin/vigil

CMD [ "vigil", "-c", "/etc/vigil.cfg" ]

EXPOSE 8080
