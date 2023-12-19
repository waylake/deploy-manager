#!/bin/bash

check_dir() {
	local dir=$1
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
	fi
}

write_log() {
	local repo=$1
	local branch=$2
	local log_message=$3

	check_dir "$CURR_DIR/log/$repo-$branch"
	local log_file="$CURR_DIR/log/$repo-$branch/$(date +%Y%m%d).log"

	echo "$(date '+%Y-%m-%d %H:%M:%S'): $log_message" >>"$log_file"
}

log_deployment_start() {
	local repo=$1
	local branch=$2

	write_log "$repo" "$branch" "---------------------- Deployment Start ----------------------"
}

log_deployment_end() {
	local repo=$1
	local branch=$2

	write_log "$repo" "$branch" "---------------------- Deployment End ------------------------"
}

check_repo_url() {
  local repo_url=$1
  if [ -z "$repo_url" ]; then
    echo "The REPO_URL does not exists on server_info.json"
    exit 1
  fi
}

git_clone_or_pull() {
  local repo=$1
  local branch=$2
  local repo_url=$3
  local repo_dir=$4
  if [ -d "$repo_dir" ]; then
    cd "$repo_dir" || return 1
    git pull origin "$branch"
  else
    rm -rf "$repo_dir"
    git clone -b "$branch" "$repo_url" "$repo_dir"
  fi
}

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
	hasEnv=$(echo "$data" | jq -r "$jq_filter.hasEnv")
	tool=$(echo "$data" | jq -r "$jq_filter.tool")
	deployPath=$(echo "$data" | jq -r "$jq_filter.deployPath")


	write_log "$repo" "$branch" "Server information loaded for $repo-$branch"
}

copy_env() {
	local repo=$1
	local branch=$2
	local CURR_DIR=$3
	local env_name=$4

	local envPath="$CURR_DIR"/env/"$repo"-"$branch".env

	if [ -f "$envPath" ]; then
		cp "$envPath" "$CURR_DIR"/output/"$repo"-"$branch"/"$env_name"
		write_log "$repo" "$branch" "Environment file copied for $repo-$branch"
	else
		write_log "$repo" "$branch" "No env file found for $repo-$branch"
		exit 1
	fi
}

install_dependencies() {
	local tool=$1
	if [ "$tool" = "yarn" ]; then
		write_log "$repo" "$branch" "Installing dependencies using $tool"
		yarn install
	elif [ "$tool" = "npm" ]; then
		write_log "$repo" "$branch" "Installing dependencies using $tool"
		npm install
	else
		write_log "$repo" "$branch" "Unsupported tool: $tool"
		exit 1
	fi
}

build_project() {
	local tool=$1
	if [ "$tool" = "yarn" ]; then
		write_log "$repo" "$branch" "Building using $tool"
		yarn build
	elif [ "$tool" = "npm" ]; then
		write_log "$repo" "$branch" "Building using $tool"
		npm run build
	elif [ "$tool" = "maven" ]; then
		write_log "$repo" "$branch" "Building using $tool"
		mvn package
	elif [ "$tool" = "gradle" ]; then
		write_log "$repo" "$branch" "Building using $tool"
		./gradlew build
	else
		write_log "$repo" "$branch" "Unsupported build tool: $tool"
		exit 1
	fi
}

deploy_to_server() {
	local ip=$1
	local username=$2
	local deployPath=$3
	local deployFile=$4

	write_log "$repo" "$branch" "Starting deployment to server $ip"
	echo "make dir"
	ssh "$username@$ip" "rm -rf $deployPath"
	ssh "$username@$ip" "mkdir -p $deployPath"

	echo "rsync"
	rsync -avz --progress "$deployFile" "$username@$ip:$deployPath"
	write_log "$repo" "$branch" "Deployment completed to $ip"
}
