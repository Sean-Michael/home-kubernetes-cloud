# Minecraft Java Edition Server

## Overview

Minecraft is a childhood classic game that I truly love. I spent so many youthful hours happily exploring and building, part of what made it so special was getting to play with others on servers that my friends and I hosted!

Figuring out how to run our own servers on hamachi back in 2011 from a [youtube tutorial](https://www.youtube.com/watch?v=ZACvglbdN4A) over Skype was such a blast for 12 year old me.

The beauty is in it's simplicity, which is probably why it's such a popular target for containerization.

Prior to this project I had previously created a containerized Minecraft game server that ran prettywell! It used docker-compose to build the image, mount the persistent storage and expose the ports.

Admittidly, a Minecraft server is probably not the best candidate for a cluster application. It's a dead simple single-threaded java app that doesn't have any mechanisms of allowing multiple instances to write to the same game world. The only benefit is Perhaps in maintaining some availability, or allow for easy deployments of different configurations.

In this directory I've created a Deployment for this Minecraft Server. At some point I would like to be able to dynamically request different variants of the server, maybe with different configurations or certain mods installed.

---

### Original Docker Implementation

#### Dockerfile

```Dockerfile
FROM openjdk:21
WORKDIR /server

RUN curl -o server.jar https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar

RUN echo "eula=true" > eula.txt

EXPOSE 25565/tcp
EXPOSE 25565/udp

CMD ["java", "-Xmx2048M", "-Xms1024M", "-jar", "server.jar", "nogui"]
```

### Original docker-compose

```yaml
services:
  mc-server:
    build: .
    ports:
      - "25565:25565/tcp"
      - "25565:25565/udp"
    volumes:
      - ./world:/server/world
      - ./server.properties:/server/server.properties
```

Pretty boring right? We'll improve it.

---

### Kubernetes Implementation

### StatefulSets

We'll setup the server as a [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) since we want the world and server data to persist, and maintain a stable IP.

```yaml
apiVersion: v1
kind: StatefulSet
metadata:
  name: 
```

## References & Resources

* [Minecraft Wiki](https://minecraft.wiki/w/Tutorial:Setting_up_a_Java_Edition_server#Startup_script)
