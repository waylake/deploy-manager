#!/bin/bash
# get argument
repo=$1
branch=$2
CURR_DIR=$3

source "$CURR_DIR"/utils/deploy_utils.sh

# if error, exit
set -e

load_server_info "$repo" "$branch" "$CURR_DIR"

# copy_env "$repo" "$branch" "$CURR_DIR" ".env"
# if hasEnv is true, copy env file, it could be in copy env function but it's better to be here to make it more readable
if [ "$hasEnv" = true ]; then
	copy_env "$repo" "$branch" "$CURR_DIR" ".env"
fi

install_dependencies "$tool"
if [ "$build" = true ]; then
	build_project "$tool"
fi

deploy_to_server "$ip" "$username" "$deployPath" "$CURR_DIR"/output/"$repo"-"$branch"/

log_deployment_end "$repo" "$branch"