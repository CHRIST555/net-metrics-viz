# Dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    snmp snmpd \
    python3 python3-pip python3-venv \
    iputils-ping curl jq vim less net-tools \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# A small helper script path (optional)
COPY scripts /opt/monitor-scripts
RUN chmod +x /opt/monitor-scripts/* || true

WORKDIR /root
CMD ["/bin/bash"]
