# syntax=docker.io/docker/dockerfile:1.7-labs

ARG USERID=10001
ARG USER="unitycatalog"
ARG HOME="/home/unitycatalog"

FROM amazoncorretto:17-alpine3.23 as builder

ARG HOME

ENV HOME=$HOME

WORKDIR $HOME

COPY --parents dev/ build/ project/ examples/ server/ api/ clients/python/ version.sbt build.sbt ./

RUN <<EOF
apk add --no-cache bash gettext curl
./build/sbt -info clean package
mkdir -p $HOME/server/target/jars
cat $HOME/server/target/classpath | tr ':' '\n' | grep .jar | xargs -I {} cp {} $HOME/server/target/jars/
EOF

# Small runtime image
FROM amazoncorretto:17-alpine3.23 as runtime

EXPOSE 8080

ARG USERID USER HOME

ENV USERID=$USERID \
    USER=$USER \
    HOME=$HOME

RUN <<EOF
apk upgrade --no-cache
apk add --no-cache bash gettext curl
addgroup -S -g $USERID $USER
adduser -S -u $USERID -G $USER $USER
mkdir -p $HOME/etc/
chmod -R 770 $HOME/etc/
chown -R $USERID:$USERID $HOME
EOF

COPY --from=builder --chown=$USERID:$USERID $HOME/server/target/jars/ $HOME/jars/

USER $USERID

WORKDIR $HOME

CMD ["java", "-cp", "jars/*", "io.unitycatalog.server.UnityCatalogServer"]
