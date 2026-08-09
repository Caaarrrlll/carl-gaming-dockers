#!/bin/bash
echo "---Checking the maximum map count per process...---"
CUR_MAX_MAP_COUNT=$(cat /proc/sys/vm/max_map_count)
if [[ $CUR_MAX_MAP_COUNT -ge 256000 ]]; then
  echo "---Maximum map count per process OK...---"
  echo "---Current map count per process: $CUR_MAX_MAP_COUNT---"
else
  echo
  echo "+---ATTENTION---ATTENTION---ATTENTION---ATTENTION---ATTENTION---"
  echo "| Maximum map count per process too low, currently: $CUR_MAX_MAP_COUNT"
  echo "| Please set the value to at least '256000' on the host and"
  echo "| restart the container afterwards."
  echo "|"
  echo "| You can change the value by executing this command on the host"
  echo "| as root:"
  echo
  echo "echo 265000 > /proc/sys/vm/max_map_count"
  echo
  echo "| You can make that persistent by using a User Script that runs"
  echo "| on startup or putting this line in your go file."
  echo "+---ATTENTION---ATTENTION---ATTENTION---ATTENTION---ATTENTION---"
  echo
  echo "---Putting container into sleep mode!---"
  sleep infinity
fi

LOGIN_CREDENTIALS="anonymous"
if [[ -n "${STEAM_USERNAME}" && "${STEAM_USERNAME}" != "" ]] && \
   [[ -n "${STEAM_PASSWRD}" && "${STEAM_PASSWRD}" != "" ]]; then    
    LOGIN_CREDENTIALS="${STEAM_USERNAME} ${STEAM_PASSWRD}"
fi

if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
  echo "SteamCMD not found!"
  wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
  tar --directory ${STEAMCMD_DIR} -xvzf /serverdata/steamcmd/steamcmd_linux.tar.gz
  rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

echo "---Update SteamCMD---"
  ${STEAMCMD_DIR}/steamcmd.sh \
  +login ${LOGIN_CREDENTIALS} \
  +quit

VALIDATE_CMD=""
echo "---Update Server---"
if [ "${VALIDATE}" == "true" ]; then
  echo "---Validating installation---"
  VALIDATE_CMD="validate"
fi
  ${STEAMCMD_DIR}/steamcmd.sh \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir ${SERVER_DIR} \
  +login ${LOGIN_CREDENTIALS} \
  +app_update ${GAME_ID} ${VALIDATE_CMD} \
  +quit

export WINEARCH=win64
export WINEPREFIX=/serverdata/serverfiles/WINE64
export WINEDEBUG=-all

echo "---Checking if WINE workdirectory is present---"
if [ ! -d ${SERVER_DIR}/WINE64 ]; then
  echo "---WINE workdirectory not found, creating please wait...---"
  mkdir ${SERVER_DIR}/WINE64
else
  echo "---WINE workdirectory found---"
fi
echo "---Checking if WINE is properly installed---"
if [ ! -d ${SERVER_DIR}/WINE64/drive_c/windows ]; then
  echo "---Setting up WINE---"
  cd ${SERVER_DIR}
  winecfg > /dev/null 2>&1
  sleep 15
else
  echo "---WINE properly set up---"
fi
echo "---Prepare Server---"
chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"

ARK_RUN_STRING="${MAP}?listen?SessionName=\"${SERVER_NAME}\"?ServerPassword=${SRV_PWD}?ServerAdminPassword=${SRV_ADMIN_PWD}" 
ARK_RUN_STRING="${ARK_RUN_STRING} ${GAME_PARAMS_EXTRA}"
if [ "${SRV_CLUSTER_INFO}" != "" ]; then
  ARK_RUN_STRING="${ARK_RUN_STRING} -clusterid=${SRV_CLUSTER_INFO} -clusterDirOverride=/serverdata/serverfiles/clusterfiles"
fi
if [ "${SRV_MOD_IDS}" != "" ]; then
  ARK_RUN_STRING="${ARK_RUN_STRING} -mods=${SRV_MOD_IDS}"
fi

if [ ${DEBUG} -eq 1 ]; then
    echo -e "DEBUG: Starting server with the following environment variables:"
    # env | sort
    # custom params
    echo -e "DEBUG: Normalized variables:"
    echo "MAP: ${MAP}"
    echo "GAME_ID: ${GAME_ID}"
    echo "SERVER_NAME: ${SERVER_NAME}"
    echo "SRV_PWD: ${SRV_PWD}"
    echo "SRV_ADMIN_PWD: ${SRV_ADMIN_PWD}"
    echo "VALIDATE_CMD: ${VALIDATE_CMD}"
    echo "LOGIN_CREDENTIALS: ${LOGIN_CREDENTIALS}"
    echo "SERVER_DIR: ${SERVER_DIR}"
    echo "STEAMCMD_DIR: ${STEAMCMD_DIR}"
    echo "Cluster Info: ${SRV_CLUSTER_INFO}"
    echo "MOD IDs: ${SRV_MOD_IDS}"
    echo "ARK_RUN_STRING: ${ARK_RUN_STRING}"
fi

echo "---Start Server---"
if [ ! -f ${SERVER_DIR}/ShooterGame/Binaries/Win64/ArkAscendedServer.exe ]; then
  echo "---Something went wrong, can't find the executable, putting container into sleep mode!---"
  sleep infinity
else
  cd ${SERVER_DIR}/ShooterGame/Binaries/Win64
  wine ArkAscendedServer.exe $ARK_RUN_STRING &
  echo "Waiting for logs..."
  ATTEMPT=0
  sleep 2
  while [ ! -f "${SERVER_DIR}/ShooterGame/Saved/Logs/ShooterGame.log" ]; do
    ((ATTEMPT++))
    if [ $ATTEMPT -eq 10 ]; then
      echo "No log files found after 20 seconds, putting container into sleep mode!"
      sleep infinity
    else
      sleep 2
      echo "Waiting for logs..."
    fi
  done
  # /opt/scripts/start-watchdog.sh &
  tail -n 9999 -f ${SERVER_DIR}/ShooterGame/Saved/Logs/ShooterGame.log
fi
