#!/bin/bash
# get argument
repo=$1
branch=$2
CURR_DIR=$3

# source the deploy_utils.sh
source "$CURR_DIR"/utils/deploy_utils.sh

# if error, exit
set -e

load_server_info "$repo" "$branch" "$CURR_DIR"

copy_env "$repo" "$branch" "$CURR_DIR" ".env"

install_dependencies "$tool"
if [ "$build" = true ]; then
	build_project "$tool"
fi

deploy_to_server "$ip" "$username" "$deployPath" "$CURR_DIR"/output/"$repo"-"$branch"/
