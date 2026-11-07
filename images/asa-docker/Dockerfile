FROM caaarrrlll/wine-baseimage:latest

LABEL org.opencontainers.image.authors="venter109@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/Caaarrrlll/docker-steamcmd-server"

RUN apt-get update && \
	apt-get -y install --no-install-recommends lib32gcc-s1 lib32stdc++6 lib32z1 screen xvfb winbind && \
	rm -rf /var/lib/apt/lists/*

ENV DATA_DIR="/serverdata" \
	XDG_RUNTIME_DIR=/tmp

ENV STEAMCMD_DIR="${DATA_DIR}/steamcmd" \
	SERVER_DIR="${DATA_DIR}/serverfiles"

ENV GAME_ID="2430930" \
	MAP="TheIsland_WP" \
	SERVER_NAME="ASA Docker" \
	SRV_PWD="Docker" \
	SRV_ADMIN_PWD="adminDocker" \
	VALIDATE="" \
	DEBUG=0

ENV GAME_PARAMS="" \
	GAME_PARAMS_EXTRA="-port=7777 -QueryPort=27015 -WinLiveMaxPlayers=20 -server -log -NoBattlEye" \
	SRV_CLUSTER_INFO="" \
	SRV_MOD_IDS=""

ENV UMASK=000 \
	UID=99 \
	GID=100 \
	STEAM_USERNAME="" \
	STEAM_PASSWRD="" \
	VALIDATE=0 \
	USER="steam" \
	DATA_PERM=770

RUN mkdir $DATA_DIR && \
	mkdir $STEAMCMD_DIR && \
	mkdir $SERVER_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	ulimit -n 2048

ADD /scripts/ /opt/scripts/
RUN chmod -R $DATA_PERM /opt/scripts/

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]