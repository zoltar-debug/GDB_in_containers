FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        g++ \
        gdb \
        gdbserver \
        procps \
        coreutils \
        less \
        vim-tiny \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY src/buggy.cpp .

RUN g++ -std=c++17 -g3 -O0 -fno-omit-frame-pointer \
        -o crashme crashme.cpp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /cores

ENTRYPOINT ["/entrypoint.sh"]
CMD ["1"]
