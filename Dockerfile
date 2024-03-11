FROM alpine:3.15

RUN echo -e "https://alpine.global.ssl.fastly.net/alpine/v3.18/community" > /etc/apk/repositories
RUN echo -e "https://alpine.global.ssl.fastly.net/alpine/v3.18/main" >> /etc/apk/repositories
RUN apk update
RUN apk add --no-cache binutils go mysql-client git openssh


RUN mkdir /gogs
WORKDIR /gogs
COPY . /gogs

EXPOSE 3000
EXPOSE 22

RUN ls  /gogs

CMD ["/gogs/gogs", "web"]
