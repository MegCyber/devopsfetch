# DevOps Fetch Tool (devopsfetch)
`devopsfetch` is a tool for DevOps to collect and display system information. It supports information retrieval for active ports, user logins, Nginx configurations, Docker images and containers, and monitoring/logging activities continuously using a systemd service.

## Installation

To install devopsfetch, run the following commands:

    ```bash
    git clone <repository_url>
    cd <repository_directory>
    chmod +x install.sh
    sudo ./install.sh
    

## Usage
The devopsfetch tool can be used with the following options:

-p, --port [port_number] Display all active ports or details of a specific port
-d, --docker [container_name] List all Docker images and containers or details of a specific container
-n, --nginx [domain] Display all Nginx domains and ports or details of a specific domain
-u, --users [username] List all users and their last login times or details of a specific user
-t, --time <start> <end> Display activities within a specified time range
-h, --help Display help message

## Examples

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
    devopsfetch -d <container_name>
    ```

- Display all Nginx domains and their ports:
    ```bash
    devopsfetch -n
    ```
    
- Get detailed information for a specific Nginx domain:
     ```bash
    devopsfetch -n example.com
    ```

- List all users and their last login times:
    ```bash
    devopsfetch -u
    ```

- Get detailed information for a specific user:
     ```bash
    devopsfetch -u <username>
    ```

- Display activities within a specified time range:
    ```bash
    devopsfetch -t "2023-07-23 10:00" "2023-07-23 12:00"
    ```
  
