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

# output dir
if [ ! -d "${CURR_DIR}/output" ]; then
	mkdir "${CURR_DIR}/output"
fi

OUTPUT=${CURR_DIR}/output

REPO_DIR=${OUTPUT}/${REPO}-${BRANCH}

# get repo URL
REPO_URL=$(jq -r ".\"${REPO}-${BRANCH}\".repo" ./server_info.json)

if [ -z "$REPO_URL" ]; then
	echo "The REPO_URL does not exists on server_info.json"
	exit 1
fi

if [ -d "$REPO_DIR" ]; then
	cd "$REPO_DIR" || return 1
	git pull origin "${BRANCH}"
else
	rm -rf "${OUTPUT}/${REPO}-${BRANCH}".tar.gz
	rm -rf "$REPO_DIR"
	git clone -b "${BRANCH}" "$REPO_URL" "$REPO_DIR"
fi

# run shell
cd "$CURR_DIR" || return 1
sh ./deploy/"${REPO}".sh "$REPO" "$BRANCH" "$CURR_DIR"
