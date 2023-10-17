FROM rust:1.68.2-slim-buster as backend
ENV RUSTFLAGS='-C linker=x86_64-linux-gnu-gcc'
ENV CC_x86_64_unknown_linux_musl=clang
ENV AR_x86_64_unknown_linux_musl=llvm-ar
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_RUSTFLAGS="-Clink-self-contained=yes -Clinker=rust-lld"
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_RUNNER="qemu-x86_64 -L /usr/x86-64-linux-gnu"
RUN rustup target add x86_64-unknown-linux-musl
RUN apt update && apt install -y musl-tools musl-dev build-essential gcc-x86-64-linux-gnu clang llvm
RUN update-ca-certificates

RUN USER=root cargo new postgres_migrator
WORKDIR /usr/src/postgres_migrator
COPY Cargo.toml Cargo.lock ./
RUN cargo build --release  --target x86_64-unknown-linux-musl

COPY src ./src
RUN cargo install --target x86_64-unknown-linux-musl --path .


FROM python:slim

RUN pip install migra~=3.0.0 psycopg2-binary~=2.9.3

COPY --from=backend /usr/local/cargo/bin/postgres_migrator /usr/bin/

WORKDIR /working

ENTRYPOINT ["/usr/bin/postgres_migrator"]
