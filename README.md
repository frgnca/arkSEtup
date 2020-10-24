# arkSEtup
ARK Survival Evolved server setup script

## Download
    git init && git pull https://github.com/frgnca/arkSEtup/tree/test
## Settings
    nano arkSEtup.sh # Edit to change server name and/or map(s)
    nano settings/Game.ini # See https://ark.gamepedia.com/Server_Configuration#Game.ini
    nano settings/GameUserSettings.ini # See https://ark.gamepedia.com/Server_Configuration#GameUserSettings.ini
    nano whitelist/PlayersExclusiveJoinList.txt # Add steamID64(s) to enable
## Setup
    sudo ./arkSEtup.sh
