#!/bin/bash

echo "###########################################################################"
echo "# Insurgency Sandstorm Server - " `date`
echo "###########################################################################"
[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

export TERM=linux

if [ ! -w /insurgency ]; then
   echo "[Error] Unable to access insurgency directory. Check permissions on your mapped directory to /insurgency"
   exit 1
fi

cd /insurgency

# make sure we have these symlinks(could be a new volume)
[ ! -f linuxgsm.sh ] && [ ! -L linuxgsm.sh ] && cp /defaults/linuxgsm.sh linuxgsm.sh && chmod a+x linuxgsm.sh
#[ ! -f crontab ] && cp /defaults/crontab crontab

[ ! -f inssserver ] && [ ! -L inssserver ] && ./linuxgsm.sh inssserver

if [ ! -d "serverfiles" ] || [ ! -f "serverfiles/srcds_linux" ]; then
  echo "Installing..."
  ./inssserver auto-install
else
  if [ ! -d "/linuxgsm/steamcmd" ] || [ ! -f "/linuxgsm/steamcmd/steamcmd.sh" ]; then
    echo "Setting up steamcmd..."
    curl -o sc.tgz http://media.steampowered.com/client/steamcmd_linux.tar.gz
    mkdir -p /linuxgsm/steamcmd
    tar -xzf sc.tgz /linuxgsm/steamcmd
    rm sc.tgz
  fi

  if [ ${UPDATEONSTART} -eq 1 ]; then
    echo "Updating..."
    ./inssserver update
  fi
fi

#[ ! -d serverfiles/insurgency/addons/metamod ] && mkdir -p serverfiles/insurgency/addons && cp -r /defaults/addons/meta* serverfiles/insurgency/addons/ && chmod a+r -R serverfiles/insurgency/addons/*
#[ ! -d serverfiles/insurgency/addons/sourcemod ] && mkdir -p serverfiles/insurgency/addons/sourcemod && cp -r /defaults/addons/sourcemod/* serverfiles/insurgency/addons/sourcemod/ && chmod a+r -r serverfiles/insurgency/addons/*
#[ ! -f addons ] && [ ! -L addons ] && ln -s serverfiles/insurgency/addons addons
#[ ! -f mapcycle_cooperative.txt ] && [ ! -L mapcycle_cooperative.txt ] && ln -s serverfiles/insurgency/mapcycle_cooperative.txt mapcycle_cooperative.txt
#[ ! -f subscribed_file_ids.txt ] && [ ! -L subscribed_file_ids.txt ] && ln -s serverfiles/insurgency/subscribed_file_ids.txt subscribed_file_ids.txt
#[ ! -f webapi_authkey.txt ] && [ ! -L webapi_authkey.txt ] && ln -s serverfiles/insurgency/webapi_authkey.txt webapi_authkey.txt
#[ ! -f log ] && [ ! -L log ] && ln -s /linuxgsm/log log
#[ ! -f cfg ] && [ ! -L cfg ] && ln -s serverfiles/insurgency/cfg cfg
[ ! -f Admins.txt ] && [ ! -L Admins.txt ] && ln -s serverfiles/Insurgency/Config/Server/Admins.txt Admins.txt
[ ! -f MapCycle.txt ] && [ ! -L MapCycle.txt ] && ln -s serverfiles/Insurgency/Config/Server/MapCycle.txt MapCycle.txt
[ ! -f Game.ini ] && [ ! -L Game.ini ] && ln -s serverfiles/Insurgency/Config/Server/Game.ini Game.ini


# If there is uncommented line in the file
#CRONNUMBER=`grep -v "^#" crontab | wc -l`
#if [ $CRONNUMBER -gt 0 ]; then
#	echo "Loading crontab..."
#	# We load the crontab file if it exist.
#	crontab /insurgency/crontab
#	# Cron is attached to this process
#	sudo cron -f &
#else
#	echo "No crontab set."
#fi

# Start the insurgency service using the generated config

echo "[insurgency] starting game server..."
./inssserver start

# Stop server in case of signal INT or TERM
echo "Waiting..."
trap 'inssserver stop;' INT
trap 'inssserver stop' TERM

read < /tmp/FIFO &
wait
