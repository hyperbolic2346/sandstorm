FROM ubuntu:focal
MAINTAINER Mike Wilson <knobby@burntsheep.com>

# Tell the server to update on start
ENV UPDATEONSTART 1

# Install things we need - special hoops to get tmux 2.0
RUN dpkg --add-architecture i386 &&\
    apt update &&\
    apt install -y tzdata mailutils postfix curl wget file bzip2 gzip unzip \
                   bsdmainutils python util-linux ca-certificates binutils \
                   bc jq tmux lib32gcc1 libstdc++6 libstdc++6:i386 &&\
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Create insurgency user
RUN /usr/sbin/useradd --create-home --home-dir /insurgency --shell /bin/bash insurgency

# Add to sudo group
RUN usermod -a -G sudo insurgency

RUN mkdir -p /insurgency/serverfiles
RUN mkdir -p /defaults

COPY files/crontab /defaults/crontab

#RUN git clone -b master https://github.com/dgibbs64/linuxgsm.git /linuxgsm
RUN mkdir /linuxgsm
ADD https://linuxgsm.sh /linuxgsm/linuxgsm.sh
RUN chmod +x /linuxgsm/linuxgsm.sh
RUN mkdir -p /linuxgsm/lgsm/config-lgsm/inssserver
RUN mv /linuxgsm/linuxgsm.sh /defaults/linuxgsm.sh &&\
    ln -s /linuxgsm/linuxgsm.sh /usr/local/bin/linuxgsm.sh &&\
    ln -s /insurgency/linuxgsm.sh /linuxgsm/linuxgsm.sh &&\
    ln -s /insurgency/inssserver.cfg /linuxgsm/lgsm/config-lgsm/inssserver/inssserver.cfg

# change server directory in script
RUN sed -i.bkp -e \
        's/serverfiles=\"${rootdir}\/serverfiles\"/serverfiles=\"\/insurgency\/serverfiles\"/g' /defaults/linuxgsm.sh \
        /defaults/linuxgsm.sh

RUN sed -i.bkp -e \
        's/rootdir=.*/rootdir=\"\/linuxgsm\/\"/g' /defaults/linuxgsm.sh \
        /defaults/linuxgsm.sh

# install steamcmd manually since we might not run install... sigh
RUN curl -o sc.tgz http://media.steampowered.com/client/steamcmd_linux.tar.gz &&\
    mkdir -p /linuxgsm/steamcmd &&\
    tar -xzf sc.tgz -C /linuxgsm/steamcmd &&\
    rm sc.tgz

WORKDIR /insurgency

# useful symlinks
RUN ln -s serverfiles/Insurgency/Config/Server/Admins.txt Admins.txt && \
    ln -s serverfiles/Insurgency/Config/Server/MapCycle.txt MapCycle.txt && \
    ln -s serverfiles/Insurgency/Config/Server/Game.ini Game.ini

RUN chown -R insurgency /insurgency && chown -R insurgency /linuxgsm && chown -R insurgency /defaults

ADD files/run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

# Set the timezone
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

ENV HOME /insurgency

USER insurgency

CMD ["/usr/local/bin/run.sh"]
