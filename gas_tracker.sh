#!/bin/bash

API_URL="https://api.vanascan.io/api/v2/stats"
GAS_LIMIT=0.5  

get_gas_prices() {
    local response gas_prices gas_price_updated_at
    response=$(curl -s "${API_URL}")
    gas_prices=$(echo "${response}" | jq '.gas_prices')
    gas_price_updated_at=$(echo "${response}" | jq -r '.gas_price_updated_at')

    if [ -z "${gas_prices}" ] || [ -z "${gas_price_updated_at}" ]; then
        echo "$current_timestamp Failed to fetch gas prices or timestamp."
        return 1
    fi

    echo "${gas_prices}|${gas_price_updated_at}"
    return 0
}


format_timestamp() {
    local timestamp=$1

    timestamp=$(echo "${timestamp}" | sed -nE 's/.*([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})?).*/\1/p')

    if [[ "${timestamp}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})?$ ]]; then

        formatted=$(echo "${timestamp}" | sed 's/T/ /;s/Z//' | awk '{ 
            cmd="date -d \"" $1 " " $2 "\" +\"%b %d, %H:%M:%S\""; 
            cmd | getline formatted; 
            close(cmd); 
            print formatted; 
        }')

        if [ -n "${formatted}" ]; then
            echo "${formatted}"
        else
            echo "Date command failed to format the timestamp"
        fi
    else
        echo "Timestamp does not match regex: '${timestamp}'"
    fi
}




container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

is_container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

run_container() {
    echo "$current_timestamp Running ${CONTAINER_NAME} container interactively (detached)..."
    docker run -d -e VANA_PRIVATE_KEY="${VANA_PRIVATE_KEY}" --name "${CONTAINER_NAME}" enggaraziz/minercli
}

start_container() {
    echo "$current_timestamp Starting ${CONTAINER_NAME} container (detached)..."
    docker start "${CONTAINER_NAME}"
}

stop_container() {
    echo "$current_timestamp Stopping ${CONTAINER_NAME} container..."
    docker stop "${CONTAINER_NAME}"
}
prompt_container_input() {
    read -p "Container name that you wanna track: " CONTAINER_NAME
}

prompt_container_input

while true; do
    current_timestamp=$(date +"[%Y-%m-%d, %H:%M:%S]")

    response=$(get_gas_prices)
    if [ $? -ne 0 ]; then
        echo "$current_timestamp Skipping this cycle due to an error fetching gas prices."
        sleep 10
        continue
    fi

    gas_prices=$(echo "${response}" | cut -d'|' -f1)
    gas_price_updated_at=$(echo "${response}" | cut -d'|' -f2)

    slow=$(echo "${gas_prices}" | jq -r '.slow')
    average=$(echo "${gas_prices}" | jq -r '.average')
    fast=$(echo "${gas_prices}" | jq -r '.fast')

    formatted_date=$(format_timestamp "${gas_price_updated_at}")

    if [ -z "${formatted_date}" ]; then
        formatted_date="Unknown"
    fi

    echo "$current_timestamp Gas Prices - Slow: ${slow} GWEI, Average: ${average} GWEI, Fast: ${fast} GWEI | Last update ${formatted_date}"

    if (( $(echo "${slow} > ${GAS_LIMIT}" | bc -l) )) || \
       (( $(echo "${average} > ${GAS_LIMIT}" | bc -l) )) || \
       (( $(echo "${fast} > ${GAS_LIMIT}" | bc -l) )); then
        echo "$current_timestamp Gas prices are high. Ensuring the container is stopped."
        if is_container_running; then
            stop_container
        fi
    else
        if ! container_exists; then
            run_container
        elif ! is_container_running; then
            start_container
        fi
    fi

    sleep 10 
done
