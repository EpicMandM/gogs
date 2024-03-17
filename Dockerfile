# Use a specific version of Alpine
FROM alpine:3.15

# Install necessary packages and glibc
ENV GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc \
    GLIBC_VERSION=2.34-r0

RUN apk update && \
    apk add --no-cache mariadb-client git openssh ca-certificates curl && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION}; do \
        curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; \
    done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk /var/cache/apk/* && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

# Set the working directory
WORKDIR /gogs

COPY gogs /gogs
COPY conf /gogs/conf

# Expose ports for web and SSH
EXPOSE 3000 22

# Define the entrypoint
CMD ["/gogs/gogs", "web"]
