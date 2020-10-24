# arkSEtup
Setup ARK Survival Evolved headless server on Ubuntu 20.04.1 LTS

## Download
    git init && git pull https://github.com/frgnca/arkSEtup
## Change settings
    nano arkSEtup.sh # Edit file to change servername and/or servermaps
    nano Game.ini # Edit to change multipliers, or delete file to use default
    nano GameUserSettings.ini # Edit to change ServerSettings, or delete file to use default
    nano PlayersExclusiveJoinList.txt # Edit to change whitelist, or delete file to not use any
## Setup
    sudo ./arkSEtup.sh
