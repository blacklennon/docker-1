FROM debian

RUN apt-get update && apt-get install -y \
	bzip2 \
	wget \
	&& wget http://dl.4players.de/ts/releases/3.0.13.8/teamspeak3-server_linux_amd64-3.0.13.8.tar.bz2 -O /tmp/ts3_server.tar.bz2 \
	&& tar jxf /tmp/ts3_server.tar.bz2 -C /tmp \
	&& mv /tmp/teamspeak3-server_* /opt/teamspeak3_server

EXPOSE 9987/udp 30033 10011

WORKDIR /opt/teamspeak3_server

ENTRYPOINT ["./ts3server_minimal_runscript.sh"]
