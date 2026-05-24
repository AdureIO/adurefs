FROM python:3.12-slim

LABEL maintainer="Adure <support@adure.io>"
LABEL description="adurefs — Shared Filesystem Volume Driver for Docker Swarm"
LABEL version="1.0.0"

# No external Python dependencies — stdlib only
COPY adurefs /usr/local/bin/adurefs
RUN chmod +x /usr/local/bin/adurefs

# Create default mount point
RUN mkdir -p /mnt/shared/volumes

CMD ["/usr/local/bin/adurefs"]