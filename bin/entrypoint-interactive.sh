#!/bin/bash

cwd=$(pwd)

if [[ ! -d "${HOME}/.dot-files" ]]; then
  echo "preparing dot-files" && \
    cd ${HOME} && ( \
    git clone https://github.com/jecluis/dot-files.git .dot-files || exit 1 )

  echo "setting up dot-files" && \
    cd ${HOME}/.dot-files && ( \
    /bin/bash ./do-setup.sh vim zsh || exit 1 )
  cd ${cwd}
fi

export TERM=screen-256color
export SHELL=/usr/bin/zsh
/usr/bin/zsh




