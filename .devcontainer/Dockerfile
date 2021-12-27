FROM ruby:3
ENV USER vscode
LABEL maintainer "@tdtds <t@tdtds.jp>"
RUN apt-get -y update && apt-get -y install ffmpeg && \
    curl -sLo /usr/local/bin/youtube-dl http://www.yt-dl.org/downloads/latest/youtube-dl && \
    chmod +x /usr/local/bin/youtube-dl && \
    useradd -u 1000 -m $USER && chsh -s /bin/bash $USER
USER $USER
RUN bundle config set path vendor/bundle && \
    bundle config set with development:test && \
    echo 'git config --global --unset core.editor' >> /home/$USER/.bashrc && \
    echo 'git config --global --unset core.sshCommand' >> /home/$USER/.bashrc && \
    echo 'git ls-remote -q > /dev/null' >> /home/$USER/.bashrc
CMD [ "sleep", "infinity" ]
