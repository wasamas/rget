FROM ruby:2
ENV USER vscode
LABEL maintainer "@tdtds <t@tdtds.jp>"
RUN bundle config set path vendor/bundle && \
    bundle config set with development:test && \
    useradd -u 1000 -m $USER && chsh -s /bin/bash $USER && \
    echo 'git config --global --unset core.editor' >> /home/$USER/.bashrc && \
    echo 'git config --global --unset core.sshCommand' >> /home/$USER/.bashrc && \
    echo 'git ls-remote -q > /dev/null' >> /home/$USER/.bashrc
USER $USER
CMD [ "sleep", "infinity" ]
