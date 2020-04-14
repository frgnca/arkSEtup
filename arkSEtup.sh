#!/bin/bash
# Copyright (c) 2017-2020 Francois Gendron <fg@frgn.ca>
# MIT License

# arkSEtup.sh
# Setup ARK Survival Evolved headless server on Ubuntu 18.04.4 LTS
#   Create a user which will run the systemd daemon for each map
#   Install steamcmd and the ARK Survival Evolved game
#   Allow necessary ports through ufw
# Based on https://www.linode.com/docs/game-servers/create-an-ark-survival-evolved-server-on-ubuntu-16-04/

################################################################################
# Username for the daemon
username="ark"
# Name of the ARK server/cluster
servername="ip.frgn.ca"
# Map(s) of the ARK server/cluster
servermaps="TheIsland TheCenter Ragnarok Valguero_P" #"TheIsland TheCenter Ragnarok Valguero_P ScorchedEarth_P Aberration_P Extinction"
###################
# Starting range for query ports
StartingQueryPort=27015
# Starting range for ports
StartingPort=7777
# Script location
ScriptLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Add user that will be used to run the server
adduser --gecos "" --force-badname $username

# Add repository for Steam
dpkg --add-architecture i386
apt-get update
apt-get -y upgrade
apt-get -y install lib32gcc1 steamcmd

# Create symlink from steamcmd to $username home directory
ln -s /usr/games/steamcmd /home/$username/steamcmd

# As user $username, install ARK server
su $username -c "steamcmd +login anonymous +force_install_dir ~/server +app_update 376030 +quit"

# As user $username, copy server whitelist
su ark -c "mkdir -p /home/$username/server/ShooterGame/Binaries/Linux"
su ark -c "cp $ScriptLocation/PlayersExclusiveJoinList.txt /home/$username/server/ShooterGame/Binaries/Linux/PlayersExclusiveJoinList.txt"

# As user $username, copy server settings
su ark -c "mkdir -p /home/$username/server/ShooterGame/Saved/Config/LinuxServer"
su ark -c "cp $ScriptLocation/GameUserSettings.ini /home/$username/server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"
su ark -c "cp $ScriptLocation/Game.ini /home/$username/server/ShooterGame/Saved/Config/LinuxServer/Game.ini"

# For each map part of the cluster
i=-1 #One query port needed per map
j=-2 #Two ports needed per map
for map in $servermaps; do
i=$(($i + 1))
j=$(($j + 2))

# Open firewall port
QueryPort=$(($StartingQueryPort + $i))
PortA=$(($StartingPort + $j))
PortB=$(($PortA + 1))
ufw allow $QueryPort/udp #server can now appear on unofficial list
ufw allow $PortA:$PortB/udp #? maybe optional

# Create daemon #TODO check if exist not to append
echo "[Unit]
Description=ARK Survival Evolved $servername.$map
[Service]
Type=simple
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3
User=$username
Group=$username
ExecStartPre=/home/$username/steamcmd +login anonymous +force_install_dir /home/$username/server +app_update 376030 +quit
ExecStart=/home/$username/server/ShooterGame/Binaries/Linux/ShooterGameServer $map?listen?SessionName=$servername?AltSaveDirectoryName=$servername.$map?QueryPort=$QueryPort?Port=$PortA -NoTransferFromFiltering -clusterid=$servername -server -log -exclusivejoin
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/$username.$servername.$map.service

done

# Reload daemons
systemctl daemon-reload

# For each map part of the cluster
for map in $servermaps; do

# Enable and start daemon
systemctl enable $username.$servername.$map.service
systemctl start $username.$servername.$map.service

done

# Create daily cron job to stop/start the daemons
crontab -l > crontmp
echo "0 6 * * * systemctl stop $username.$servername.* && systemctl start $username.$servername.*" >> crontmp
crontab crontmp
rm crontmp

# Show daemon status
systemctl status $username.$servername.*
