FROM alpine:3.15

# Update the repository URLs
RUN echo -e "https://alpine.global.ssl.fastly.net/alpine/v3.18/community" > /etc/apk/repositories && \
    echo -e "https://alpine.global.ssl.fastly.net/alpine/v3.18/main" >> /etc/apk/repositories

# Install necessary packages
RUN apk update && \
    apk add --no-cache binutils go mysql-client git openssh

# Create the /gogs directory and set it as the working directory
RUN mkdir /gogs
WORKDIR /gogs

# Copy only the gogs executable and the conf directory
COPY gogs /gogs/gogs
COPY conf /gogs/conf

# Expose the necessary ports
EXPOSE 3000
EXPOSE 22

# List contents for debugging
RUN ls /gogs

# Command to run when the container starts
CMD ["/gogs/gogs", "web"]
