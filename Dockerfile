FROM maven:3.6-openjdk-11 AS BUILDER
ADD guacamole-jetty /src
RUN cd /src && mvn package

FROM guacamole/guacd:1.5.4
USER root
RUN apk update && apk add openjdk11-jre-headless bash && apk cache clean
COPY --from=BUILDER /src/target/guacamole-jetty-1.0.0-jar-with-dependencies.jar /guacamole-jetty.jar
ADD start.sh /
USER guacd
ENTRYPOINT ["/start.sh"]
EXPOSE 4822 8080 8081
