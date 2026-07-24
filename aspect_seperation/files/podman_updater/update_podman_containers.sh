#!/usr/bin/env bash

BASE_DIR="/opt/podman_updater"
NORMAL_CONTAINERS_ENABLED="${BASE_DIR}/normal-containers-enabled"
HA_CONTAINERS_ENABLED="${BASE_DIR}/ha-containers-enabled"
LOG_DIR="${BASE_DIR}/LOGS/container-logs"
rm -rf "$LOG_DIR" 2>/dev/null
mkdir -p "$LOG_DIR"

KEEPALIVED_ROLE_FILE="$BASE_DIR/keepalived_role"
ROLE="UNKNOWN"
if [[ -f "$KEEPALIVED_ROLE_FILE" ]]; then
    ROLE=$(cat "$KEEPALIVED_ROLE_FILE")
fi

# CASE 1: No args → update ALL linked containers
# CASE 2: Args → update ONLY those containers
if [[ $# -gt 0 ]]; then
    TARGET_CONTAINERS=("$@")
else
    TARGET_CONTAINERS=($(ls -1 "$NORMAL_CONTAINERS_ENABLED" 2>/dev/null) $(ls -1 "$HA_CONTAINERS_ENABLED" 2>/dev/null))
fi

echo -e "$(date)\nHost HA role: $ROLE" > "$(dirname "$LOG_DIR")/role.log"
echo -e "$(date)\nUpdating containers (parallel): ${TARGET_CONTAINERS[*]}" > "$(dirname "$LOG_DIR")/update.log"

echo -n > "$(dirname "$LOG_DIR")/skipped.log"
echo -n > "$(dirname "$LOG_DIR")/updated_containers.log"

update_container() {
    local name="$1"
    local dir=""

    # Check NORMAL first
    if [[ -d "$NORMAL_CONTAINERS_ENABLED/$name" ]]; then
        dir="$NORMAL_CONTAINERS_ENABLED/$name"
    fi

    # HA takes precedence, so check it second and override
    if [[ -d "$HA_CONTAINERS_ENABLED/$name" ]]; then
        dir="$HA_CONTAINERS_ENABLED/$name"
    fi

    # Skip if container is not linked/enabled
    if [[ -z "$dir" ]]; then
        echo "Skipping $name (not enabled on this host)" >> "$(dirname "$LOG_DIR")/skipped.log"
        return
    fi

    # HA container logic
    if [[ "$(dirname "$dir")" = "$HA_CONTAINERS_ENABLED" ]]; then
        if [[ "$ROLE" == "MASTER" ]]; then
            echo "Updating HA container $name (MASTER host, will NOT start)" >> "$(dirname "$LOG_DIR")/updated_containers.log"
            (
                cd "$dir"
                podman-compose pull
            ) &> "$LOG_DIR/$name.log"
            return
        else
            echo "Updating HA container $name (BACKUP host, will start)" >> "$(dirname "$LOG_DIR")/updated_containers.log"
            (
                cd "$dir"
                podman-compose pull
                podman-compose up -d
            ) &> "$LOG_DIR/$name.log"
            return
        fi
    fi

    # Non-HA container logic
    echo "Updating non-HA container $name" >> "$(dirname "$LOG_DIR")/updated_containers.log"
    (
        cd "$dir"
        podman-compose pull
        podman-compose up -d
    ) &> "$LOG_DIR/$name.log"
}

# Run all updates in parallel
for c in "${TARGET_CONTAINERS[@]}"; do
    update_container "$c" &
done

wait

echo "$(date) All updates complete (parallel mode)." >> "$(dirname "$LOG_DIR")/update.log"
