#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# ASCII Display
print_ascii() {
    echo -e "    ${RED}    _    _   _   _   _   _   ___   ____   _____ ${RESET}"
    echo -e "    ${GREEN}   / \\  | \\ | | | \\ | | / _ \\ |  _ \\ | ____|${RESET}"
    echo -e "    ${BLUE}  / _ \\ |  \\| | |  \\| || | | || | | ||  _|  ${RESET}"
    echo -e "    ${YELLOW} / ___ \\| |\\  | | |\\  || |_| || |_| || |___ ${RESET}"
    echo -e "    ${MAGENTA}/_/   \\\\_| \\_| |_| \\_| \\___/ |____/ |_____|${RESET}"
}

# Function to get IP address
get_ip_address() {
    ip_address=$(hostname -I | awk '{print $1}')
    if [[ -z "$ip_address" ]]; then
        echo -ne "${YELLOW}Unable to determine IP address automatically. Please enter:${RESET} "
        read ip_address
    fi
    echo "$ip_address"
}

# Install dependencies using YUM
install_dependencies() {
    echo -e "${CYAN}Installing dependencies...${RESET}"
    sudo yum update -y
    sudo yum install -y git docker python3 python3-pip cronie
    sudo systemctl enable --now docker
    sudo systemctl enable --now crond

    if ! command -v docker-compose &>/dev/null; then
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    pip3 install --upgrade pip
    pip3 install eth_account requests
}

# Install node function
install_node() {
    install_dependencies
    echo -ne "${YELLOW}Enter number of nodes:${RESET} "
    read num_nodes
    ip_address=$(get_ip_address)

    python3 script.py "$ip_address" "$num_nodes"
    docker network create ocean_network || true

    for ((i=1; i<=num_nodes+1; i++)); do
        docker-compose -f docker-compose$i.yaml up -d
    done

    (crontab -l 2>/dev/null; echo "0 * * * * python3 $(pwd)/req.py $ip_address $(pwd)") | crontab -
    echo -e "${GREEN}? Node installation complete.${RESET}"
    read -p "Press Enter to return to menu..."
}

# View logs
view_logs() {
    echo -ne "${YELLOW}Enter node number:${RESET} "
    read num
    docker logs ocean-node-$num
    read -p "Press Enter to continue..."
}

# View Typesense logs
view_typesense_logs() {
    docker logs typesense
    read -p "Press Enter to continue..."
}

# Stop node
stop_node() {
    echo -ne "${YELLOW}Enter number of nodes:${RESET} "
    read num_nodes
    for ((i=1; i<=num_nodes+1; i++)); do
        docker-compose -f docker-compose$i.yaml down
    done
    crontab -l | grep -v "req.py" | crontab -
    echo -e "${GREEN}? Stopped all nodes.${RESET}"
    read -p "Press Enter to continue..."
}

# Start node
start_node() {
    echo -ne "${YELLOW}Enter number of nodes:${RESET} "
    read num_nodes
    ip_address=$(get_ip_address)
    for ((i=1; i<=num_nodes+1; i++)); do
        docker-compose -f docker-compose$i.yaml up -d
    done
    (crontab -l 2>/dev/null; echo "0 * * * * python3 $(pwd)/req.py $ip_address $(pwd)") | crontab -
    echo -e "${GREEN}? Started all nodes.${RESET}"
    read -p "Press Enter to continue..."
}

# Restart node
restart_node() {
    stop_node
    start_node
}

# View wallets
view_wallets() {
    cat wallets.json
    read -p "Press Enter to continue..."
}

# Change RPC
change_rpc() {
    pip3 install pyyaml
    wget -O RPC.py https://raw.githubusercontent.com/dknodes/ocean/master/RPC.py
    python3 RPC.py
    read -p "Press Enter to continue..."
}

# Menu
while true; do
    clear
    print_ascii
    echo -e "\n${CYAN}Ocean Node Installer - YUM Edition${RESET}"
    echo "1. Install Node"
    echo "2. View Typesense Logs"
    echo "3. View Ocean Node Logs"
    echo "4. Stop Node"
    echo "5. Start Node"
    echo "6. View Wallets"
    echo "7. Change RPC"
    echo "8. Restart Node"
    echo "0. Exit"
    echo -ne "${YELLOW}Enter choice: ${RESET}"
    read choice
    case $choice in
        1) install_node;;
        2) view_typesense_logs;;
        3) view_logs;;
        4) stop_node;;
        5) start_node;;
        6) view_wallets;;
        7) change_rpc;;
        8) restart_node;;
        0) echo -e "${GREEN}Exiting...${RESET}"; exit 0;;
        *) echo -e "${RED}Invalid option${RESET}"; read -p "Press Enter...";;
    esac
done
