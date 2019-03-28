#!/bin/bash

src_dir=$1
what=${2:-name}

[[ -z "$src_dir" ]] && \
  echo "usage: $0 <srcdir> [name|sha]"

cd $src_dir
[[ ! -e ".git" ]] && exit 1

case $what in
  name)
    # in case a branch has slashes in it, substitute for underscores.
    # otherwise, you know, directories and whatnot.
    git symbolic-ref --short HEAD 2>/dev/null | tr '/' '_'
    ;;
  sha)
    git rev-parse --short HEAD
    ;;
esac
