# arkSEtup
ARK Survival Evolved setup script for headless linux server

## Download
    git init && git pull https://github.com/frgnca/arkSEtup test
## Settings
**settings/Game.ini**  
See https://ark.gamepedia.com/Server_Configuration#Game.ini

**settings/GameUserSettings.ini**  
See https://ark.gamepedia.com/Server_Configuration#GameUserSettings.ini

**template/**  
Copy backup to use as template

**whitelist/PlayersExclusiveJoinList.txt**  
Add steamID64(s) to enable  

**arkSEtup.sh**  
Edit to change server name and/or map(s)
## Setup
    sudo ./arkSEtup.sh
