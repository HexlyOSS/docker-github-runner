#!/bin/bash

# Ensure Docker socket is owned by docker group
if [[ -e "/var/run/docker.sock" ]]; then
    sudo chgrp docker /var/run/docker.sock
fi

if [[ "$@" == "bash" ]]; then
    exec $@
fi

if [[ -z $RUNNER_NAME ]]; then
    echo "RUNNER_NAME environment variable is not set, using '${HOSTNAME}'."
    export RUNNER_NAME=${HOSTNAME}
fi

if [[ -n "$RUNNER_SUFFIX_TS" ]]; then 
    DATE_TS=$(date +"%Y_%m_%d_%H_%M_%S")
    export RUNNER_NAME="$RUNNER_NAME"'_'"$DATE_TS"
    echo "Configured dynamic runner name $RUNNER_NAME"
fi

if [[ -z $RUNNER_WORK_DIRECTORY ]]; then
    echo "RUNNER_WORK_DIRECTORY environment variable is not set, using '_work'."
    export RUNNER_WORK_DIRECTORY="_work"
fi


if [[ -n "$RUNNER_PAT" ]]; then
    echo "RUNNER_PAT detected; attempting to secure RUNNER_TOKEN via Personal Access Token to repo $PAT_OWNER/$PAT_REPO"
    export RUNNER_TOKEN=$(curl -s -X POST -H "Authorization: token $RUNNER_PAT" "https://api.github.com/repos/$PAT_OWNER/$PAT_REPO/actions/runners/registration-token" | jq -r .token)
    if [[ "$RUNNER_TOKEN" = "null" ]]; then
        echo "Error: RUNNER_PAT failed to retrieve RUNNER_TOKEN"
        exit 1
    fi

    echo "Giving it a second before using token: ${RUNNER_TOKEN:0:5}**********"
fi

if [[ -z $RUNNER_TOKEN ]]; then
    echo "Error : You need to set the RUNNER_TOKEN environment variable."
    exit 1
fi

if [[ -z $RUNNER_REPOSITORY_URL ]]; then
    echo "Error : You need to set the RUNNER_REPOSITORY_URL environment variable."
    exit 1
fi

if [[ -z $RUNNER_REPLACE_EXISTING ]]; then
    export RUNNER_REPLACE_EXISTING="true"
fi

CONFIG_OPTS=""
if [ "$(echo $RUNNER_REPLACE_EXISTING | tr '[:upper:]' '[:lower:]')" == "true" ]; then
	CONFIG_OPTS="--replace"
fi

if [[ -f ".runner" ]]; then
    echo "Runner already configured. Skipping config."
else
    ./config.sh \
        --url $RUNNER_REPOSITORY_URL \
        --token $RUNNER_TOKEN \
        --name $RUNNER_NAME \
        --work $RUNNER_WORK_DIRECTORY \
        $CONFIG_OPTS \
        --unattended
fi

exec "$@"