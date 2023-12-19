#!/bin/bash
while getopts ":r:b:" opt; do
	case ${opt} in
	r)
		REPO=${OPTARG}
		;;
	b)
		BRANCH=${OPTARG}
		;;
	\?)
		echo "Invalid option: -$OPTARG" 1>&2
		exit 1
		;;
	:)
		echo "Invalid option: -$OPTARG requires an argument" 1>&2
		exit 1
		;;
	esac
done

CURR_DIR=$(pwd)
OUTPUT=${CURR_DIR}/output
REPO_DIR=${OUTPUT}/${REPO}-${BRANCH}
REPO_URL=$(jq -r ".\"${REPO}-${BRANCH}\".repo" ./server_info.json)

source "${CURR_DIR}"/utils/deploy_utils.sh
log_deployment_start "$REPO" "$BRANCH"

check_dir "$OUTPUT"
check_repo_url "$REPO_URL"
git_clone_or_pull "$REPO" "$BRANCH" "$REPO_URL" "$REPO_DIR"

# run shell
cd "$CURR_DIR" || return 1
# sh ./deploy/"${REPO}".sh "$REPO" "$BRANCH" "$CURR_DIR"
sh ./deploy/deploy.sh "$REPO" "$BRANCH" "$CURR_DIR"
