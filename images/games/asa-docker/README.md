# SteamCMD in Docker optimized for Unraid
This Docker will download and install SteamCMD along with Ark Ascended

## Example Env params for Ark Ascended
| Name | Value | Example |
| --- | --- | --- |
| STEAMCMD_DIR | Folder for SteamCMD | /serverdata/steamcmd |
| SERVER_DIR | Folder for gamefile | /serverdata/serverfiles |
| GAME_ID | The GAME_ID that the container downloads at startup. If you want to install a static or beta version of the game change the value to: '2430930 -beta YOURBRANCH' (without quotes, replace YOURBRANCH with the branch or version you want to install). | 2430930 |
| GAME_NAME | SRCDS gamename | cstrike |
| GAME_PARAMS | Values to start the server | -port=7766 -QueryPort=27006 -WinLiveMaxPlayers=20 -server -log -NoBattlEye -clusterid=mycluster -clusterDirOverride=/serverdata/serverfiles/clusterfiles -mods=942024,1188679,947033,934401 |
| UID | User Identifier | 99 |
| GID | Group Identifier | 100 |
| GAME_PORT | Port the server will be running on | 27015 |
| VALIDATE | Validates the game data | blank |
| USERNAME | Leave blank for anonymous login | blank |
| PASSWRD | Leave blank for anonymous login | blank |

## Run example for Ark Ascended
```
docker run --name ASAServer -d \
	-p 27015:27015 -p 27015:27015/udp \
	--env 'GAME_ID=2430930' \
	--env 'GAME_NAME=ark' \
	--env 'GAME_PORT=27015' \
	--env 'GAME_PARAMS=-port=7766 -QueryPort=27006 -WinLiveMaxPlayers=20 -server -log -NoBattlEye -clusterid=mycluster -clusterDirOverride=/serverdata/serverfiles/clusterfiles -mods=942024,1188679,947033,934401' \
	--env 'UID=99' \
	--env 'GID=100' \
	--volume /path/to/steamcmd:/serverdata/steamcmd \
	--volume /path/to/ark:/serverdata/serverfiles \
	caaarrrlll/ark-ascended-proton:latest
```

This Docker was mainly edited for better use with Unraid, if you don't use Unraid you should definitely try it!

This Docker is forked from ich777's game servers, Thanks for the insperation and still uses his debian base image.