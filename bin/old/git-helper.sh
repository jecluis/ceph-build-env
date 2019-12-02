#!/bin/bash

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

find_remote() {
  local branch=$1

  ref=$(git for-each-ref --format='%(refname:short) %(objectname:short)' \
    "refs/remotes/*/${branch}" --sort='committerdate' --count=1)
  [[ -z "${ref}" ]] && \
    echo "unable to find reference for branch '${branch}' in all remotes" && \
    exit 1

  remote_ref=$(echo ${ref} | cut -f1 -d' ')
  remote_sha=$(echo ${ref} | cut -f2 -d' ')

  [[ -z "${remote_ref}" ]] && \
    echo "remote ref for '${branch}' not found" && \
    exit 1
  [[ -z "${remote_sha}" ]] && \
    echo "remote sha for branch '${branch_name}' not available" && \
    exit 1

  remote_name=$(echo ${remote_ref} | cut -f1 -d'/')
  branch_name=$(echo ${remote_ref} | cut -f2 -d'/')

  [[ -z "${remote_name}" ]] && \
    echo "unable to find a remote for branch '${branch}'" && \
    exit 1

  [[ "${branch_name}" != "${branch}" ]] && \
    echo "branch found at remote '${remote_name}' is not '${branch}'" && \
    exit 1


  echo "${remote_name} ${remote_sha}"
}

get_repo_path() {
  abs_path=$(realpath -m $1)
  echo "file://${abs_path}/.git"
}

usage() {
  cat << EOF
usage: $0 <srcdir> <cmd>

commands:
  branch [get-name|get-sha [name] ]
  get-git-path
  get-tag

  do-clone <target directory>
  do-checkout <branch>
  do-update
  do-pull
EOF
}

if [[ $# -lt 2 ]]; then
  usage 
  exit 1
fi

srcdir=$(realpath -m $1)
[[ $? -ne 0 ]] && \
  echo "source dir at '$1' does not exist" && exit 1
shift

[[ -z "${srcdir}" ]] && \
  echo "something went wrong; unable to figure out source path" && \
  exit 1

if [[ ! -d "${srcdir}" ]]; then
  echo "src dir at '${srcdir}' is not a directory"
  exit 1
elif [[ ! -d "${srcdir}/.git" ]]; then
  echo "src dir at '${srcdir}' is not a git repository"
  exit 1
fi

cmd=$1
cmd_get_branch=false
cmd_get_git_path=false
cmd_get_tag=false
cmd_get_sha=false

cmd_do_clone=false
cmd_do_checkout=false
cmd_do_update=false
cmd_do_pull=false

cmd_get_branch_op="get-name"
cmd_get_branch_sha_name=""
cmd_do_clone_target=""

cmd_is_read=true
cmd_needs_exports=true

while [[ $# -gt 0 ]]; do
  case $1 in
    branch)
      cmd_get_branch=true
      if [[ -n "$2" ]]; then
        cmd_get_branch_op="$2"
        shift
      fi
      if [[ "${cmd_get_branch_op}" == "get-sha" ]]; then
        if [[ -n "$2" ]]; then
          cmd_get_branch_sha_name="$2"
          shift
        fi
      fi
      ;;
    get-git-path)
      cmd_get_git_path=true
      ;;
    get-tag)
      cmd_get_tag=true
      ;;
    *)
      cmd_is_read=false
      ;;
  esac

  if $cmd_is_read ; then
    break
  fi

  case $1 in
    do-clone)
      cmd_do_clone=true
      [[ -z "$2" ]] && usage && exit 1
      cmd_do_clone_target=$(realpath -m $2)
      cmd_needs_exports=false
      shift
      ;;
    do-checkout)
      cmd_do_checkout=true
      [[ -z "$2" ]] && usage && exit 1
      cmd_do_checkout_branch="$2"
      shift
      ;;
    do-update)
      cmd_do_update=true
      ;;
    do-pull)
      cmd_do_pull=true
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

if $cmd_is_read || $cmd_needs_exports; then
  export GIT_DIR=${srcdir}/.git
  export GIT_WORK_TREE=${srcdir}
fi

if $cmd_branch_find ; then
  find_branch ${branch}
fi


if $cmd_get_branch ; then
  if [[ "${cmd_get_branch_op}" == "get-name" ]]; then
    git symbolic-ref --short HEAD 2>/dev/null | tr '/' '_'
  elif [[ "${cmd_get_branch_op}" == "get-sha" ]]; then
    [[ -z "${cmd_get_branch_sha_name}" ]] && \
      cmd_get_branch_sha_name=$(git symbolic-ref \
        --short HEAD 2>/dev/null | tr '/' '_')

    sha=$(git rev-parse --short ${cmd_get_branch_sha_name} 2>/dev/null)
    [[ $? -ne 0 ]] && exit 1
    echo ${sha}
  else
    usage
    exit 1
  fi

elif $cmd_get_git_path ; then
  echo $(get_repo_path ${srcdir})

elif $cmd_get_tag ; then
  echo $(git describe --abbrev=0 --tags)

elif $cmd_do_clone ; then
  [[ -z "${cmd_do_clone_target}" ]] && usage && exit 1
  [[ -e "${cmd_do_clone_target}" ]] && \
    echo "target directory at '${cmd_do_clone_target}' already exists" && \
    exit 1

  git_repo_path=$(get_repo_path ${srcdir})
  git clone ${git_repo_path} ${cmd_do_clone_target} || exit 1

elif $cmd_do_checkout ; then
  [[ -z "${cmd_do_checkout_branch}" ]] && usage && exit 1
  existing_branch=$(git --no-pager branch --list ${cmd_do_checkout_branch})
  if [[ -z "${existing_branch}" ]]; then
    git checkout -b ${cmd_do_checkout_branch} \
      --track origin/${cmd_do_checkout_branch} || exit 1
  fi

elif $cmd_do_update || $cmd_do_pull ; then
  if $cmd_do_update ; then
    git remote update origin || exit 1
  fi
  git pull || exit 1

else
  2>& echo "unrecognized command '${cmd}'"
  usage
  exit 1
fi

