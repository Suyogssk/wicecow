FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends cowsay fortune-mod fortunes-min netcat-openbsd \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 wisecow \
    && useradd --system --uid 10001 --gid wisecow --home-dir /app --shell /usr/sbin/nologin wisecow \
    && mkdir -p /app \
    && chown wisecow:wisecow /app

ENV PATH="/usr/games:/usr/bin:/bin"
WORKDIR /app
COPY --chown=wisecow:wisecow wisecow.sh /app/wisecow.sh
RUN sed -i 's/\r$//' /app/wisecow.sh && chmod 0555 /app/wisecow.sh

USER 10001:10001
EXPOSE 4499
CMD ["/bin/bash", "/app/wisecow.sh"]
