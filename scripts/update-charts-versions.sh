#!/usr/bin/env bash
#
# This script updates the Helm charts versions to use
# whenever there's a new release in the upstream charts
# or there's a version bump in the charts we maintain.
#
# This script is used on the "Update charts" GH action that is
# triggered periodically and creates a PR if new versions are
# detected.

set -o errexit
set -o pipefail

# Constants
ROOT_DIR="$(git rev-parse --show-toplevel)"
RESET='\033[0m'
GREEN='\033[38;5;2m'
RED='\033[38;5;1m'
YELLOW='\033[38;5;3m'

# Load Libraries
. "${ROOT_DIR}/scripts/lib/liblog.sh"
. "${ROOT_DIR}/scripts/lib/libutil.sh"

# Axiliar functions
print_menu() {
    local script
    script=$(basename "${BASH_SOURCE[0]}")
    log "${RED}NAME${RESET}"
    log "    $(basename -s .sh "${BASH_SOURCE[0]}")"
    log ""
    log "${RED}SYNOPSIS${RESET}"
    log "    $script [${YELLOW}-h${RESET}] [${YELLOW}-s ${GREEN}\"/path/to/services.json\"${RESET}] [${YELLOW}-t ${GREEN}\"target\"${RESET}]"
    log ""
    log "${RED}DESCRIPTION${RESET}"
    log "    Script to update charts versions."
    log ""
    log "    The options are as follow:"
    log ""
    log "      ${YELLOW}-s, --service-info ${GREEN}[/path/to/services.json]${RESET}     Path to JSON file containing services information."
    log "      ${YELLOW}-t, --target ${GREEN}[target]${RESET}                           Target to use (staging or production)."
    log ""
    log "${RED}EXAMPLES${RESET}"
    log "      $script --help"
    log "      $script --target \"staging\""
    log "      $script --target \"production\" --service-info \"/tmp/services.json\""
    log ""
}

service_info="${ROOT_DIR}/infrastructure/build/services.json"
target="staging"
help_menu=0
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help)
            help_menu=1
            ;;
        -s|--service-info)
            shift; service_info="${1:?missing service info}"
            ;;
        -t|--target)
            shift; target="${1:?missing target}"
            ;;
        *)
            error "Invalid command line flag $1" >&2
            exit 1
            ;;
    esac
    shift
done

if [[ "$target" != "production" ]] && [[ "$target" != "staging" ]]; then
    error "Allowed targets are: \"production\" and \"staging\". Found: $target"
    help_menu=1
fi

if [[ "$help_menu" -eq 1 ]]; then
    print_menu
    exit 0
fi

info "Updating chart repositories..."
info "..."
silence helm repo add bitnami https://charts.bitnami.com/bitnami || true
silence helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets || true
silence helm repo update || true

info "Updating chart versions for target \"$target\""
info "..."

i=0
services_length=$(jq -r ". | length" "$service_info")
while [[ $i -lt $services_length ]]; do
    svc_name="$(jq -r ".[$i].name" "$service_info")"
    chart_repo="$(jq -r ".[$i][\"chart-repo\"]" "$service_info")"
    if [[ "$chart_repo" = "local" ]]; then
        latest_version="$(yq ".version" "${ROOT_DIR}/src/${svc_name}/helm/Chart.yaml")"
    else
        latest_version="$(helm search repo "${chart_repo}/${svc_name}" -o json | jq -r '.[0].version')"
    fi
    info "Updating \"$svc_name\" chart version ..."
    # Update charts versions
    for f in "cd"; do
        replace_in_file "${ROOT_DIR}/infrastructure/environments/${target}/${f}-services.tf" "\".*\" # auto-updated-${svc_name}" "\"$latest_version\" # auto-updated-${svc_name}" || true
    done
    ((i+=1))
done
info "done!"
