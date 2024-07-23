#!/bin/bash

# A comprehensive script to fetch various system information.

# Set constants for log file
LOG_FILE="$HOME/devopsfetch.log"
MAX_LOG_SIZE=$((10 * 1024 * 1024)) # 10 MB

# Function to display help information
display_help() {
    cat << EOF
Usage: devopsfetch [OPTION]...
Retrieve and display system information

Options:
  -p, --port [PORT]    Display active ports or specific port info
  -d, --docker [NAME]  Display Docker images/containers or specific container info
  -n, --nginx [DOMAIN] Display Nginx domains or specific domain config
  -u, --users [USER]   Display user logins or specific user info
  -t, --time START END Display activities within specified time range
  -h, --help           Display this help message
EOF
}

# Function to log activities to a file
log_activity() {
    local message="$1"
    # Create log file if it doesn't exist
    [ ! -f "$LOG_FILE" ] && touch "$LOG_FILE" && chmod 644 "$LOG_FILE"

    # Rotate log file if it exceeds max size
    if [ "$(stat -c %s "$LOG_FILE")" -gt "$MAX_LOG_SIZE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
    fi

    # Append log entry
    echo "$(date): $message" >> "$LOG_FILE"
}

# Function to display all active ports and services
display_ports() {
    echo "Active Ports and Services:"
    (
        printf "%-15s %-6s %-10s %-15s %s\n" "Host" "Port" "PID" "Service" "User"
        netstat -tuln | awk 'NR > 2 {
            split($4, addr, ":")
            host = addr[1]
            port = addr[2]
            split($7, pid_service, "/")
            pid = pid_service[1]
            service = pid_service[2]
            user = "N/A"
            if (pid) {
                user = system("ps -o user= -p " pid " 2>/dev/null") ? "N/A" : user
            }
            printf "%-15s %-6s %-10s %-15s %s\n", host, port, pid, service, user
        }'
    )
}

# Function to display detailed information about a specific port
display_port_details() {
    local port_number="$1"
    echo "Details for port $port_number:"
    (
        printf "%-15s %-6s %-10s %-15s %s\n" "Host" "Port" "PID" "Service" "User"
        netstat -tuln | awk -v port="$port_number" 'NR > 2 {
            split($4, addr, ":")
            host = addr[1]
            port_num = addr[2]
            split($7, pid_service, "/")
            pid = pid_service[1]
            service = pid_service[2]
            if (port_num == port) {
                user = "N/A"
                if (pid) {
                    user = system("ps -o user= -p " pid " 2>/dev/null") ? "N/A" : user
                }
                printf "%-15s %-6s %-10s %-15s %s\n", host, port_num, pid, service, user
            }
        }'
    )
}

# Function to list all Docker images and containers
list_docker() {
    echo "Docker Images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}"
    echo -e "\nDocker Containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

# Function to provide detailed information about a specific Docker container
docker_container_details() {
    local container_name="$1"
    echo "Details for Docker container $container_name:"
    docker inspect "$container_name" | jq '.[] | {Name: .Name, State: .State, Config: .Config}'
}

# Function to display all Nginx domains and their ports
list_nginx_domains() {
    echo "Nginx Domains and Ports:"
    (
        printf "%-40s %-10s %-40s %-10s\n" "Server Name" "Port" "Proxied Host" "Proxied Port"
        for file in /etc/nginx/sites-enabled/*; do
            server_names=$(grep -E -h "^\s*server_name" "$file" | sed 's/^\s*server_name \(.*\);/\1/' | tr -d ';' | grep -v '^_')
            listen_ports=$(grep -E -h "^\s*listen" "$file" | sed 's/^\s*listen \(.*\);/\1/' | tr -d ';')
            proxy_passes=$(grep -E -h "^\s*proxy_pass" "$file" | sed 's/^\s*proxy_pass \(.*\);/\1/' | tr -d ';' | sed 's/^\(http:\/\/\|https:\/\/\)//')

            IFS=' ' read -r -a server_name_array <<< "$server_names"
            IFS=' ' read -r -a listen_array <<< "$listen_ports"
            IFS=' ' read -r -a proxy_pass_array <<< "$proxy_passes"

            for name in "${server_name_array[@]}"; do
                for port in "${listen_array[@]}"; do
                    if [ ${#proxy_pass_array[@]} -eq 0 ]; then
                        printf "%-40s %-10s %-40s %-10s\n" "$name" "$port" "-" "-"
                    else
                        for proxy in "${proxy_pass_array[@]}"; do
                            proxy_host=$(echo "$proxy" | awk -F/ '{print $1}')
                            proxy_port=$(echo "$proxy" | awk -F: '{print $2}')
                            printf "%-40s %-10s %-40s %-10s\n" "$name" "$port" "$proxy_host" "$proxy_port"
                        done
                    fi
                done
            done
        done
    )
}

# Function to get detailed Nginx configuration for a specific domain
nginx_domain_details() {
    local domain="$1"
    echo "Configuration for domain $domain:"
    grep -r -A 20 "server_name $domain" /etc/nginx/sites-enabled/
}

# Function to get user information
get_user_info() {
    if [ -z "$1" ]; then
        echo "Regular users and last login times:"
        (
            printf "%-15s %-20s %-15s\n" "User" "Login Time" "Session Duration"
            awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd | while read -r user; do
                last_login=$(last "$user" -1 2>/dev/null | awk 'NR==1 {print $4, $5, $6, $7, $8, $9}')
                session_duration=$(last "$user" -1 2>/dev/null | awk 'NR==1 {print $10, $11, $12, $13, $14, $15, $16, $17}')
                if [ -n "$last_login" ]; then
                    printf "%-15s %-20s %-15s\n" "$user" "$last_login" "$session_duration"
                else
                    printf "%-15s %-20s %-15s\n" "$user" "Never logged in" ""
                fi
            done
        )
    else
        echo "Information for user $1:"
        if id "$1" >/dev/null 2>&1; then
            if [ "$(id -u "$1")" -ge 1000 ] && [ "$(id -u "$1")" -ne 65534 ]; then
                id "$1"
                echo "Last login:"
                last "$1" -1 | head -n 1
            else
                echo "This is a system user, not a regular user."
            fi
        else
            echo "User $1 does not exist."
        fi
    fi
}

# Function to get time range information
get_time_range_info() {
    local start_time="$1"
    local end_time="$2"

    if [ -z "$start_time" ] || [ -z "$end_time" ]; then
        echo "Please provide both start and end times (e.g., 'Jul 20 10:00' 'Jul 20 12:00')"
    else
        # Validate and format timestamps
        if date -d "$start_time" >/dev/null 2>&1 && date -d "$end_time" >/dev/null 2>&1; then
            echo "Activities from $start_time to $end_time:"
            journalctl --since "$start_time" --until "$end_time"
        else
            echo "Invalid timestamp format. Please use a valid format (e.g., 'Jul 20 10:00' 'Jul 20 12:00')."
        fi
    fi
}

# Main function to handle command-line arguments
main() {
    log_activity "DevOpsFetch executed with arguments: $*"

    case "$1" in
        -p|--port)
            if [ -n "$2" ]; then
                display_port_details "$2"
            else
                display_ports
            fi
            ;;
        -d|--docker)
            if [ -n "$2" ]; then
                docker_container_details "$2"
            else
                list_docker
            fi
            ;;
        -n|--nginx)
            if [ -n "$2" ]; then
                nginx_domain_details "$2"
            else
                list_nginx_domains
            fi
            ;;
        -u|--users)
            get_user_info "$2"
            ;;
        -t|--time)
            get_time_range_info "$2" "$3"
            ;;
        -h|--help)
            display_help
            ;;
        *)
            echo "Invalid option. Use -h or --help for usage information."
            exit 1
            ;;
    esac
}

# Call main function with all script arguments
main "$@"
