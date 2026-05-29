FROM python:3.12-alpine

LABEL maintainer="Adure <support@adure.io>"
LABEL description="adurefs — Shared Filesystem Volume Driver for Docker Swarm"
LABEL version="1.0.0"

# Guarantee the internal destination directory exists in the rootfs
# so runc never throws a "no such file or directory" upon initialization
RUN mkdir -p /var/lib/docker/volumes

# Copy the plugin execution driver
COPY adurefs /usr/local/bin/adurefs
RUN chmod +x /usr/local/bin/adurefs

CMD ["/usr/local/bin/adurefs"]