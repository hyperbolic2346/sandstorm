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

[ ! -f Admins.txt ] && [ ! -L Admins.txt ] && ln -s serverfiles/Insurgency/Config/Server/Admins.txt Admins.txt
[ ! -f MapCycle.txt ] && [ ! -L MapCycle.txt ] && ln -s serverfiles/Insurgency/Config/Server/MapCycle.txt MapCycle.txt
[ ! -f Game.ini ] && [ ! -L Game.ini ] && ln -s serverfiles/Insurgency/Config/Server/Game.ini Game.ini

# Start the insurgency service using the generated config

echo "[insurgency] starting game server..."
./inssserver start

# Stop server in case of signal INT or TERM
echo "Waiting..."
trap 'inssserver stop;' INT
trap 'inssserver stop' TERM

read < /tmp/FIFO &
wait
