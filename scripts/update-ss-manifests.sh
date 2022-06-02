#!/usr/bin/env bash

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
    log "    $script [${YELLOW}-h${RESET}] [${YELLOW}-c ${GREEN}\"my-staging-context\"${RESET}] [${YELLOW}-s ${GREEN}\"/path/to/services.json\"${RESET}] [${YELLOW}-t ${GREEN}\"target\"${RESET}]"
    log ""
    log "${RED}DESCRIPTION${RESET}"
    log "    Script to update sealed secrets manifests."
    log ""
    log "    The options are as follow:"
    log ""
    log "      ${YELLOW}-c, --context ${GREEN}[context]${RESET}                         Kubectl context to use."
    log "      ${YELLOW}-s, --service-info ${GREEN}[/path/to/services.json]${RESET}     Path to JSON file containing services information."
    log "      ${YELLOW}-t, --target ${GREEN}[target]${RESET}                           Target to use (staging or production)."
    log ""
    log "${RED}EXAMPLES${RESET}"
    log "      $script --help"
    log "      $script --target \"staging\""
    log "      $script --target \"production\" --context \"my-production-context\" --service-info \"/tmp/services.json\""
    log ""
}

context=""
service_info="${ROOT_DIR}/infrastructure/build/services.json"
target="staging"
help_menu=0
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help)
            help_menu=1
            ;;
        -c|--context)
            shift; context="${1:?missing context}"
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

if [[ -n "$context" ]]; then
    kubectl config use-context "$context"
fi

info "Updating sealed secrets for target \"$target\" (using context \"$(kubectl config current-context)\")"
info "..."

i=0
services_length=$(jq -r ". | length" "$service_info")
while [[ $i -lt $services_length ]]; do
    svc_name="$(jq -r ".[$i].name" "$service_info")"
    svc_namespace="$(jq -r ".[$i].namespace" "$service_info")"
    sealed_secrets_length=$(jq -r ".[$i][\"sealed-secrets\"] | length" "$service_info")
    if [[ $sealed_secrets_length -eq 0 ]]; then
        info "Service \"$svc_name\" doesn't require any sealed secret. Skipping ..."
    else
        info "Updating sealed secrets for service \"$svc_name\" ..."
        mkdir -p "${ROOT_DIR}/infrastructure/kubernetes/${target}/${svc_namespace}/${svc_name}"
        j=0
        while [[ $j -lt $sealed_secrets_length ]]; do
            ss_name="$(jq -r ".[$i][\"sealed-secrets\"][$j]" "$service_info")"
            info "Updating sealed secret \"$ss_name\" for service \"$svc_name\" in namespace \"$svc_namespace\" ..."
            kubectl create secret generic "$ss_name" \
                --namespace "$svc_namespace" \
                --dry-run=client \
                -o yaml | kubeseal --controller-namespace kube-system --allow-empty-data --format yaml > "${ROOT_DIR}/infrastructure/kubernetes/${target}/${svc_namespace}/${svc_name}/${ss_name}-ss.yaml"
            read -r -a keys <<< "$(jq -r '. | keys[]' "${ROOT_DIR}/infrastructure/secrets/${ss_name}.json" | tr '\n' ' ')"
            for k in "${keys[@]}"; do
                kubectl create secret generic "$ss_name" \
                    --namespace "$svc_namespace" \
                    --dry-run=client \
                    --from-literal="$k"="$(jq --arg key "$k" -r '.[$key]' "${ROOT_DIR}/infrastructure/secrets/${ss_name}.json")" \
                    -o yaml | kubeseal --controller-namespace kube-system --format yaml --merge-into "${ROOT_DIR}/infrastructure/kubernetes/${target}/${svc_namespace}/${svc_name}/${ss_name}-ss.yaml"
            done
        done
    fi
    info "..."
    ((i+=1))
done
info "done!"
