# syntax=docker.io/docker/dockerfile:1.7-labs

ARG USERID=10001
ARG USER="unitycatalog"
ARG HOME="/home/unitycatalog"

FROM amazoncorretto:17-alpine3.23 as builder

RUN apk add --no-cache bash gettext

ARG HOME

ENV HOME=$HOME

WORKDIR $HOME

COPY --parents dev/ build/ project/ examples/ server/ api/ clients/python/ version.sbt build.sbt ./

RUN ./build/sbt -info clean package

RUN mkdir -p $HOME/server/target/jars && \
    cat $HOME/server/target/classpath | tr ':' '\n' | grep .jar | xargs -I {} cp {} $HOME/server/target/jars/

# Small runtime image
FROM amazoncorretto:17-alpine3.23 as runtime

RUN apk add --no-cache bash gettext curl

EXPOSE 8080

ARG USERID
ARG USER
ARG HOME

ENV USERID=$USERID \
    USER=$USER \
    HOME=$HOME

RUN addgroup -S -g $USERID $USER && \
    adduser -S -u $USERID -G $USER $USER

COPY --from=builder $HOME/server/target/jars/ $HOME/jars/

RUN chown -R $USERID:$USERID $HOME

USER $USERID

WORKDIR $HOME

CMD ["java", "-cp", "jars/*", "io.unitycatalog.server.UnityCatalogServer"]
