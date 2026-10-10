# Portable shell functions (kubectl + ffmpeg helpers). No secrets.

# kexec <env> <pattern> [command] — exec into a matching pod (interactive pick if many)
kexec() {
    local namespace
    case "$1" in
        u) namespace="service-uat" ;;
        p) namespace="service-production" ;;
        s) namespace="service-staging" ;;
        d) namespace="service-dev" ;;
        c) namespace="system-common" ;;
        *) echo "Invalid env. Use u|p|s|d|c"; return 1 ;;
    esac
    local pattern="$2" command="${3:-bash}"
    [ -z "$pattern" ] && { echo "Usage: kexec <env> <pattern> [command]"; return 1; }
    local pod_names
    pod_names=$(kubectl -n "$namespace" get pod | grep "$pattern" | cut -d' ' -f1)
    echo "Pod found: $pod_names"
    [ -z "$pod_names" ] && { echo "No pod matching '$pattern' in '$namespace'."; return 1; }
    local pods
    IFS=$'\n' read -rd '' -A pods <<< "$pod_names"
    if [ ${#pods[@]} -gt 1 ]; then
        select pod_name in "${pods[@]}"; do
            [ -n "$pod_name" ] && { kubectl -n "$namespace" exec -it "$pod_name" -- "${command}"; break; }
        done
    else
        kubectl -n "$namespace" exec -it "${pods[1]:-${pods[0]}}" -- "${command}"
    fi
}

# klogs <env> <pattern> — follow logs of a matching pod
klogs() {
    local namespace
    case "$1" in
        u) namespace="service-uat" ;;
        p) namespace="service-production" ;;
        s) namespace="service-staging" ;;
        d) namespace="service-dev" ;;
        c) namespace="system-common" ;;
        *) echo "Invalid env. Use u|p|s|d|c"; return 1 ;;
    esac
    local pattern="$2"
    [ -z "$pattern" ] && { echo "Usage: klogs <env> <pattern>"; return 1; }
    local pod_names
    pod_names=$(kubectl -n "$namespace" get pod | grep "$pattern" | cut -d' ' -f1)
    echo "Pod found: $pod_names"
    [ -z "$pod_names" ] && { echo "No pod matching '$pattern' in '$namespace'."; return 1; }
    local pods
    IFS=$'\n' read -rd '' -A pods <<< "$pod_names"
    if [ ${#pods[@]} -gt 1 ]; then
        select pod_name in "${pods[@]}"; do
            [ -n "$pod_name" ] && { kubectl -n "$namespace" logs -f "$pod_name"; break; }
        done
    else
        kubectl -n "$namespace" logs -f "${pods[1]:-${pods[0]}}"
    fi
}

# kdel <type> <env-abbr> <pattern> — delete matching resources
kdel() {
    typeset -A service_map=( d service-dev s service-staging u service-uat p service-production )
    local type="$1" service_abbr="$2" pattern="$3"
    local service_name="${service_map[$service_abbr]}"
    [ -z "$service_name" ] && { echo "Invalid service abbreviation: $service_abbr"; return 1; }
    kubectl -n "$service_name" get "$type" | grep "$pattern" | cut -d' ' -f1 \
        | xargs -I {} kubectl -n "$service_name" delete "$type" {}
}

# dbfs <file> — show audio volume/peak via ffmpeg volumedetect
dbfs() { ffmpeg -i "$1" -filter:a volumedetect -f null /dev/null; }

# lufs <file> — EBU R128 loudness measurement (JSON)
lufs() {
    ffmpeg -i "$1" -af loudnorm=print_format=json -f null - 2>&1 \
        | awk '/^\{/{flag=1} flag; /^\}/{flag=0}'
}
