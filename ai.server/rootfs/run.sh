#!/bin/bash
CONFIG_PATH=/data/options.json
export MODULES_PATH=$(jq --raw-output '.MODULES_PATH // empty' $CONFIG_PATH)
export DATA_DIR=$(jq --raw-output '.DATA_DIR // empty' $CONFIG_PATH)

mkdir -p "$MODULES_PATH"
mkdir -p "$DATA_DIR"

cat /app/server/appsettings.json  | sed -e 's/\/\/ .*$//g' | jq ".ModuleOptions.ModulesPath=\"$MODULES_PATH\"" > /app/server/appsettings.json.new
mv /app/server/appsettings.json.new /app/server/appsettings.json

cd /app/server && dotnet ./CodeProject.AI.Server.dll --ApplicationDataDir="$DATA_DIR"
