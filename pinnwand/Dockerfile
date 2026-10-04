ARG BUILD_FROM
FROM node:24-bookworm-slim

# git zum Holen des Programmcodes, jq zum Lesen der Add-on-Optionen,
# Build-Werkzeuge nur als Rückfall, falls ein natives Modul keine fertige Version hat
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates jq python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
