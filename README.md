# Dynatrace configuration exporter

A simple shell script to dump configuration from Dynatrace environments.

## Features
- Stores JSON configuration in directories (per environment) (`config/<ENVIRONMENT>/<ENTITY>`)
- Access to multiple environments by shell variables
- Provides pre-formatted curl commands to push configurations to different environments (copy&paste curl command)

## Dependencies: 
- curl
- jq

## Usage:
1. Export environment variables for accessing the environment
- **ENVIRONMENT** - Environment name (used )
- **TENANT** - Base URL to tenant (https://xxxx.live.dynatrace.com or https://managed/e/uuid)
- **APITOKEN** - Dynatrace API token with scope of reading configuration
- **CURLARGS** - optional arguments passed to curl (proxy)
For convenience you shell env file (example in env-\<template\>.sh)

2. Run the exporter to export desired configuration entity \
  \
  `dynatraceConfigurationExporter.sh <entity>` \
  \
  For each entity a curl command is display to put the configuration into environment. To push the same entity into a different Dynatrace tenant, just export or source environment variables and paste the URL command. Entity will be created with the same identifier allowing simple synchronization in the future. \
  \
  For displaying known entites for export, run the exporter with the `-help`.

3. Find your exported configuration entites in the config directory per environment.

