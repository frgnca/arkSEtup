# arkSEtup
Setup ARK Survival Evolved headless server on Ubuntu 18.04.4 LTS

## Download
    git init && git pull https://github.com/frgnca/arkSEtup
## Change settings
    nano arkSEtup.sh # Change username, servername, and/or servermaps
    nano Game.ini # Change multipliers
    nano GameUserSettings.ini # Change ServerSettings
    nano PlayersExclusiveJoinList.txt # Change whitelist
## Setup
    sudo ./arkSEtup.sh
