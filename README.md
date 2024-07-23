# devopsfetch
# DevOpsFetch

`devopsfetch` is a tool for DevOps to collect and display system information. It supports information retrieval for active ports, user logins, Nginx configurations, Docker images and containers, and monitoring/logging activities continuously using a systemd service.

## Installation

1. Clone the repository or download the script files.
2. Run the installation script:

    ```bash
    chmod +x install_devopsfetch.sh
    sudo ./install_devopsfetch.sh
    ```

## Usage

- Display all active ports and services:
    ```bash
    devopsfetch -p
    ```

- Provide detailed information about a specific port:
    ```bash
    devopsfetch -p 80
    ```

- List all Docker images and containers:
    ```bash
    devopsfetch -d
    ```

- Provide detailed information about a specific container:
    ```bash
    devopsfetch -d container_name
    ```

- Display all Nginx domains and their ports:
    ```bash
    devopsfetch -n
    ```

- Display activities within a specified time range:
    ```bash
    devopsfetch -t "2023-07-23 10:00" "2023-07-23 12:00"
    ```
  
