#!/bin/bash
# Copyright (c) 2017-2020 Francois Gendron <fg@frgn.ca>
# MIT License

# arkSEtup.sh
# ARK Survival Evolved setup script for headless linux server
#   Creates a user to run the systemd daemon for each map
#   Installs steamcmd and the ARK Survival Evolved game
#   Allows necessary ports through ufw
# Based on https://www.linode.com/docs/game-servers/create-an-ark-survival-evolved-server-on-ubuntu-16-04/

################################################################################
# Name of the ARK server/cluster
servername="arkSEtup"
# Map(s) of the ARK server/cluster
servermaps="TheIsland TheCenter Ragnarok Valguero_P CrystalIsles" #"TheIsland TheCenter ScorchedEarth_P Ragnarok Aberration_P Extinction Valguero_P Genesis CrystalIsles"
###################
# Script location
ScriptLocation="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Username for the daemon
username="ark"
# Starting range for query ports
StartingQueryPort=27015
# Starting range for ports
StartingPort=7777

# Add user that will be used to run the server
echo "Create password for new user $username"
adduser --gecos "" --force-badname $username > /dev/null

# Auto accept Steam EULA
echo steam steam/license note '' | debconf-set-selections
echo steam steam/question select "I AGREE" | debconf-set-selections

# Install Steam
apt-get -y install lib32gcc1 steamcmd

# Create symlink from steamcmd to $username home directory
ln -s /usr/games/steamcmd /home/$username/steamcmd

# As user $username, install ARK server
su $username -c "steamcmd +login anonymous +force_install_dir ~/server +app_update 376030 +quit"

# If there is a non-empty Game file
if [ -s "$ScriptLocation/settings/Game.ini" ]; then
  # There is a non-empty Game file

  # As user $username, copy Game file
  su ark -c "mkdir -p /home/$username/server/ShooterGame/Saved/Config/LinuxServer"
  su ark -c "cp $ScriptLocation/settings/Game.ini /home/$username/server/ShooterGame/Saved/Config/LinuxServer/Game.ini"
fi

# If there is a non-empty GameUserSettings file
if [ -s "$ScriptLocation/settings/GameUserSettings.ini" ]; then
  # There is a non-empty GameUserSettings file

  # As user $username, copy GameUserSettings file
  su ark -c "mkdir -p /home/$username/server/ShooterGame/Saved/Config/LinuxServer"
  su ark -c "cp $ScriptLocation/settings/GameUserSettings.ini /home/$username/server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"
fi

# For each file in the template folder
for file in $ScriptLocation/template; do
# If the file is non-empty
if [ -s "$file" ]; then
  # The file is non-empty

  # As user $username, copy the file to the SavedArks folder
  su ark -c "cp $file /home/$username/server/ShooterGame/Saved/SavedArks/$file"
fi

done

# If there is a non-empty server whitelist
if [ -s "$ScriptLocation/whitelist/PlayersExclusiveJoinList.txt" ]; then
  # There is a non-empty server whitelist

  # As user $username, copy server whitelist
  su ark -c "mkdir -p /home/$username/server/ShooterGame/Binaries/Linux"
  su ark -c "cp $ScriptLocation/whitelist/PlayersExclusiveJoinList.txt /home/$username/server/ShooterGame/Binaries/Linux/PlayersExclusiveJoinList.txt"
fi

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
ExecStartPre=/home/$username/steamcmd +login anonymous +force_install_dir /home/$username/server +app_update 376030 +quit" >> /etc/systemd/system/$username.$servername.$map.service
# If there is a non-empty server whitelist
if [ -s "$ScriptLocation/whitelist/PlayersExclusiveJoinList.txt" ]; then
  # There is a non-empty server whitelist
  echo "ExecStart=/home/$username/server/ShooterGame/Binaries/Linux/ShooterGameServer $map?listen?SessionName=$servername?QueryPort=$QueryPort?Port=$PortA -NoTransferFromFiltering -clusterid=$servername -server -log -exclusivejoin" >> /etc/systemd/system/$username.$servername.$map.service
else
  # There is no non-empty server whitelist
  echo "ExecStart=/home/$username/server/ShooterGame/Binaries/Linux/ShooterGameServer $map?listen?SessionName=$servername?QueryPort=$QueryPort?Port=$PortA -NoTransferFromFiltering -clusterid=$servername -server -log" >> /etc/systemd/system/$username.$servername.$map.service
fi
echo "[Install]
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
crontab -l > crontmp > /dev/null 2>&1
echo "0 6 * * * systemctl stop $username.$servername.* && systemctl start $username.$servername.*" >> crontmp
crontab crontmp
rm crontmp
