#!/bin/bash

# Function to check service status
check_service_status() {
    local service_name=$1
    systemctl is-active --quiet "$service_name"
    if [[ $? -eq 0 ]]; then
        echo "Running"
    else
        echo "Not Running"
    fi
}

# Function to display system information
display_system_info() {
    HOSTNAME=$(hostname)
    UPTIME=$(uptime -p)
    MEMORY=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
    DISK=$(df -h / | awk '/\// {print $3 "/" $2 " (" $5 " used)"}')

    # Display system information using dialog
    dialog --title "System Information" --msgbox \
        "Hostname: $HOSTNAME\nUptime: $UPTIME\nMemory Usage: $MEMORY\nDisk Usage: $DISK" 12 50
}

# Function to check and display service statuses
display_service_status() {
    APACHE_STATUS=$(check_service_status apache2)
    MYSQL_STATUS=$(check_service_status mysql)

    # Display service statuses using dialog
    dialog --title "Service Status" --msgbox \
        "Apache: $APACHE_STATUS\nMySQL: $MYSQL_STATUS" 10 40
}

# Main menu
while true; do
    CHOICE=$(dialog --clear --title "System Status Menu" \
        --menu "Choose an option:" 15 50 3 \
        1 "View System Information" \
        2 "Check Apache and MySQL Status" \
        3 "Exit" \
        3>&1 1>&2 2>&3)

    # Exit status
    EXIT_STATUS=$?
    if [[ $EXIT_STATUS -ne 0 ]]; then
        clear
        exit 0
    fi

    case $CHOICE in
        1)
            display_system_info
            ;;
        2)
            display_service_status
            ;;
        3)
            clear
            exit 0
            ;;
        *)
            dialog --msgbox "Invalid choice, try again!" 8 40
            ;;
    esac
done
