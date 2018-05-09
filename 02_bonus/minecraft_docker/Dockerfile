FROM java

WORKDIR /app

RUN curl  https://launcher.mojang.com/mc/game/1.12.2/server/886945bfb2b978778c3a0288fd7fab09d315b25f/server.jar --output server.jar

RUN echo "eula=true" > eula.txt

EXPOSE 25565
EXPOSE 25565/udp

CMD ["java", "-Xmx1024M", "-Xms1024M", "-jar", "server.jar", "nogui"]
