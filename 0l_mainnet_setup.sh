#!/bin/bash

echo ""
# echo "";
echo "    ██████╗ ██████╗ ███████╗███╗   ██╗     ██╗     ██╗██████╗ ██████╗  █████╗  ";        
echo "   ██╔═══██╗██╔══██╗██╔════╝████╗  ██║     ██║     ██║██╔══██╗██╔══██╗██╔══██╗ ";        
echo "   ██║   ██║██████╔╝█████╗  ██╔██╗ ██║     ██║     ██║██████╔╝██████╔╝███████║ ";        
echo "   ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║     ██║     ██║██╔══██╗██╔══██╗██╔══██║ ";        
echo "   ╚██████╔╝██║     ███████╗██║ ╚████║     ███████╗██║██████╔╝██║  ██║██║  ██║ ";        
echo "    ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝     ╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ";
echo -e "                  A PERMISSIONLESS, TRANSPARENT, COMMUNITY-DRIVEN PROJECT ✊🔆";
echo "";

new=0
echo -e "\e[1m\e[32m1. Installing packages for libra node setup.\e[0m"

sleep 2
echo ""
cd ~
apt update
apt install sudo
sudo apt update
sudo apt install -y nano wget git
if [[ -f $HOME/github_token.txt ]]
then
    :
else
    echo "github token is not found in $HOME directory."
    echo ""
    echo "Input your github token."
    read -p "token : " token
    echo ""
    echo $token > $HOME/github_token.txt
fi

if [ -d "$HOME/libra-framework" ]; then
    export PATH="$HOME/.cargo/bin:$PATH" && rustup update && rustup default stable && cargo install cargo-nextest && cargo nextest --version
    cd ~/libra-framework
else
    git clone https://github.com/0LNetworkCommunity/libra-framework
fi
sudo apt update && sudo apt install -y bc tmux jq build-essential cmake clang llvm libgmp-dev pkg-config libssl-dev lld libpq-dev net-tools
cd ~/libra-framework
sudo apt install curl && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && source ~/.bashrc
cd ~
export PATH="$HOME/.cargo/bin:$PATH" && rustup update && rustup default stable && cargo install cargo-nextest && cargo nextest --version
cd ~/libra-framework
sudo apt install curl && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y && source ~/.bashrc

echo ""
echo "Input libra-framework release version(x.y.z)."
read -p "release : " release_version
echo ""
echo "libra-framework release version for setup is $release_version."
echo ""

git fetch --all
git checkout -f release-$release_version
git pull
git log -n 1 --pretty=format:"%H"
cd ~/libra-framework/util
echo "y" | bash dev_setup.sh
echo ""

echo -e "\e[1m\e[32m2. Building libra binary files.\e[0m"

sleep 2
echo ""
export PATH="$HOME/.cargo/bin:$PATH";
cd ~/libra-framework
if [[ -f ~/.cargo/bin/libra ]]
then
    SHA_check=$(~/.cargo/bin/libra version | grep "Git SHA" | awk '{print $3}')
fi

RUSTFLAGS="--cfg tokio_unstable" cargo build --release -p libra
sudo cp -f target/release/libra ~/.cargo/bin
SHA_check2=$(~/.cargo/bin/libra version | grep "Git SHA" | awk '{print $3}')
echo ""
libra version
echo ""
if [[ -z "$SHA_check" ]]; then SHA_check=none; fi
if [[ "$SHA_check2" != "$SHA_check" ]] && [[ "$SHA_check" == "none" ]]
then
    echo "libra binary file built successfully!"
    if [[ "$SHA_check2" != "$SHA_check" ]] && [[ "$SHA_check" != "none" ]]
    then
        echo "libra binary file updated successfully!"
    fi
fi
echo ""

echo -e "\e[1m\e[32m3. Generating account config files.\e[0m"

sleep 2
echo ""
rm -rf ~/.libra/data &> /dev/null
mkdir ~/.libra &> /dev/null; mkdir ~/.libra/genesis &> /dev/null
cp -f ~/github_token.txt ~/.libra &> /dev/null
# echo "Do you want to generate new wallet? (y/n)"
# read -p "y/n : " user_input
# if [[ $user_input == "y" ]]; then
#     echo ""
#     libra wallet keygen
# fi
libra config validator-init
libra config fullnode-init
echo ""

echo -e "\e[1m\e[32m4. Verifying the integrity of the network file.\e[0m"

sleep 2
echo ""
wget -O ~/.libra/genesis/genesis.blob https://github.com/AlanYoon71/OpenLibra_Mainnet/raw/main/genesis.blob
sleep 0.5
wget -O ~/.libra/genesis/waypoint.txt https://github.com/AlanYoon71/OpenLibra_Mainnet/raw/main/waypoint.txt
echo ""

echo -e "\e[1m\e[32m5. Updating network config files.\e[0m"

sleep 2
libra config fix --force-url https://rpc.openlibra.space:8080/v1
operator_update=$(grep full_node_network_public_key ~/.libra/public-keys.yaml)
sed -i "s/full_node_network_public_key:.*/$operator_update/" ~/.libra/operator.yaml &> /dev/null
sed -i 's/~$//' ~/.libra/operator.yaml &> /dev/null
echo "If you are VFN, type \"vfn\". If not VFN, just enter."
echo ""
read -p "This node's role : " role
echo ""
echo "If you have VFN now or you are VFN, input VFN's IP address."
echo "If you don't have VFN yet, just enter."
echo ""
read -p "VFN IP address : " vfn_ip
echo ""
if [[ -z $vfn_ip ]]; then
    echo "You need to set up VFN later for 0l network's stability and security."
    ip_update=$(grep "  host:" ~/.libra/operator.yaml)
    echo "$ip_update" >> ~/.libra/operator.yaml
    echo ""
else
    echo "  host: $vfn_ip" >> ~/.libra/operator.yaml
    if [[ -f ~/.libra/vfn.yaml ]]
    then
        echo "You should input your Validator's IP address for setting ~/.libra/vfn.yaml." 
        echo ""
        read -p "Validator IP address : " VAL_IP
        sed -i 's/\/ip4\/[^\/]*\/tcp\/6181\/noise-ik\//\/ip4\/$VAL_IP\/tcp\/6181\/noise-ik\//g' ~/.libra/vfn.yaml
        echo ""
        echo "~/.libra/vfn.yaml updated."
    fi
fi
port_update=$(grep "  port:" ~/.libra/operator.yaml)
port_update=$(echo "$port_update" | sed 's/6180/6182/')
echo "$port_update" >> ~/.libra/operator.yaml
echo "~/.libra/operator.yaml updated."
echo ""
echo "You should copy your vfn.yaml and operator.yaml on the validator to your VFN if you have."
echo ""

echo -e "\e[1m\e[32m6. Setting firewall and running libra with tmux.\e[0m"

sleep 2
echo ""
if [[ -z "$role" ]]
then
    sudo ufw allow 3000; ufw allow 6180; sudo ufw allow 6181; sudo ufw enable;
    echo "Your firewall rule(ufw) has changed to open 6180 and 6181 ports."
else
    sudo ufw allow 6180; sudo ufw allow 6182; sudo ufw allow 8080; sudo ufw enable;
    echo "Your firewall rule (ufw) now opens ports 3000, 6180, 6182, and 8080 for Docker traffic and grafana."
fi
echo "checking tmux sessions..."
echo ""
tmux send-keys -t node:0 "exit" C-m &> /dev/null;
session="node"
tmux new-session -d -s $session
window=0
tmux rename-window -t $session:$window 'node'
echo ""
if [[ -z "$role" ]]
then
    echo "Validator is getting ready to start."
    tmux send-keys -t node:0 "RUST_LOG=info libra node" C-m
else
    echo "VFN is getting ready to start."
    tmux send-keys -t node:0 "RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
fi
echo ""
sleep 10
echo "Started."
echo ""
SYNC1=$(curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*')

animation() {
    local status="$1"
    local command="$2"
    local dots="."

    while :; do
        for (( i = 0; i < 10; i++ )); do
            echo -ne "$status $dots\033[K"
            sleep 0.2
            echo -en "\r"
            dots=".$dots"
        done
        dots="."
    done &
    local animation_pid=$!

    eval "$command"

    kill $animation_pid
    status=" Done"
    echo -e "$status \e[1m\e[32m ✓\e[0m"
}
animation "Checking sync status now" "sleep 80"
SYNC2=$(curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*')

if [[ $SYNC1 -eq $SYNC2 ]]
then
    echo ""
    echo "It appears that node is not syncing."
    echo "When you run the node for the first time, it may stop occasionally."
    echo "Don't worry. Try again now.."
    echo ""
    echo "checking tmux sessions..."
    echo ""
    tmux send-keys -t node:0 "exit" C-m &> /dev/null;
    session="node"
    tmux new-session -d -s $session
    window=0
    tmux rename-window -t $session:$window 'node'
    if [[ -z "$role" ]]
    then
        tmux send-keys -t node:0 "RUST_LOG=info libra node" C-m
    else
        tmux send-keys -t node:0 "RUST_LOG=info libra node --config-path ~/.libra/vfn.yaml" C-m
    fi
    echo ""
    sleep 10
    echo "Restarted."
    echo ""
    SYNC1=$(curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*')

    animation() {
        local status="$1"
        local command="$2"
        local dots="."

        while :; do
            for (( i = 0; i < 10; i++ )); do
                echo -ne "$status $dots\033[K"
                sleep 0.2
                echo -en "\r"
                dots=".$dots"
            done
            dots="."
        done &
        local animation_pid=$!

        eval "$command"

        kill $animation_pid
        status=" Done"
        echo -e "$status \e[1m\e[32m ✓\e[0m"
}
    animation "Checking sync status now" "sleep 80"
    SYNC2=$(curl -s 127.0.0.1:9101/metrics 2> /dev/null | grep diem_state_sync_version{type=\"synced\"} | grep -o '[0-9]*')

    if [[ $SYNC1 -eq $SYNC2 ]]
    then
        echo "Node can't sync. Installation failed!"
        echo "Node can't sync. Installation failed!"
        echo ""
        echo "You can check log in tmux session named node."
        echo "Exiting script..."
        echo ""
        sleep 2
        exit
    fi
fi
echo ""
if [[ -z "$role" ]]
then
    echo "Validator is running and syncing now! Installed successfully."
else
    echo "VFN is running and syncing now! Installed successfully."
fi
echo ""
curl -s localhost:8080/v1/ | jq
echo ""
tmux ls
echo ""
echo "Done."
echo ""
