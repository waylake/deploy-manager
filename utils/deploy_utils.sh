#!/bin/bash

load_server_info() {
	local repo=$1
	local branch=$2
	local CURR_DIR=$3

	cd output/"$repo"-"$branch" || return 1
	local data=$(cat "$CURR_DIR"/server_info.json)

	jq_filter=".[\"$repo-$branch\"]"
	ip=$(echo "$data" | jq -r "$jq_filter.ip")
	username=$(echo "$data" | jq -r "$jq_filter.username")
	build=$(echo "$data" | jq -r "$jq_filter.build")
	tool=$(echo "$data" | jq -r "$jq_filter.tool")
	deployPath=$(echo "$data" | jq -r "$jq_filter.deployPath")
}

copy_env () {
	local repo=$1
	local branch=$2
	local CURR_DIR=$3
	local env_name=$4

	# pre defined env path is env/repo-branch.env and copy to output/repo-branch/$env_name
	local envPath="$CURR_DIR"/env/"$repo"-"$branch".env
	
	if [ -f "$envPath" ]; then
		cp "$envPath" "$CURR_DIR"/output/"$repo"-"$branch"/"$env_name"
	else
		echo "No env file found"
		exit 1
	fi
}

install_dependencies() {
	local tool=$1
	if [ "$tool" = "yarn" ]; then
		echo "Installing dependencies using Yarn"
		yarn install
	elif [ "$tool" = "npm" ]; then
		echo "Installing dependencies using NPM"
		npm install
	else
		echo "Unsupported tool"
		exit 1
	fi
}

build_project() {
	local build=$1
	if [ "$build" = "yarn" ]; then
		echo "Building using Yarn"
		yarn build
	elif [ "$build" = "npm" ]; then	
		echo "Building using NPM"
		npm run build
	else
		echo "Unsupported build tool"
		exit 1
	fi
}

deploy_to_server() {
	local ip=$1
	local username=$2
	local deployPath=$3
	local deployFile=$4

	echo "make dir"
	ssh "$username@$ip" "rm -rf $deployPath"
	ssh "$username@$ip" "mkdir -p $deployPath"

	echo "rsync"
	rsync -avz --progress "$deployFile" "$username@$ip:$deployPath"
}
