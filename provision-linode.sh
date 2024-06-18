#!/bin/bash



# Source the variables from configu.sh
source config.sh

retry_interval=5
OPEN_VPN_FILE=${1:-"client"}

# Function to check if a variable is empty and exit if it is
check_undefined() {
    if [ -z "$1" ]; then
        echo "Error: $2 is empty."
        exit 1
    fi
}

# Function to wait until Linode instance is running
check_linode_status() {
    local linode_id=$1
    local status

    while true; do
        status=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" https://api.linode.com/v4/linode/instances/$linode_id | jq -r '.status')
        if [ "$status" == "running" ]; then
            echo "Instance is running."
            break
        fi
        sleep 10
    done
}

# Create Linode instance
response=$(curl -s -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $API_TOKEN" \
     -d '{"authorized_users": [ "'$USER'" ], "private_ip": true, "type":"'$TYPE'","region":"'$REGION'","image":"'$IMAGE'","root_pass":"'$ROOT_PASS'","label":"'$LABEL'"}' \
     https://api.linode.com/v4/linode/instances)

# Extract Linode ID from response
linode_id=$(echo "$response" | jq -r '.id')

# Check if Linode ID is valid
check_undefined "$linode_id" "Linode ID"
echo "Linode instance created with ID: $linode_id"

# Wait until Linode instance is running

# Get Linode instance IP address
ip_address=$(curl -s -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" https://api.linode.com/v4/linode/instances/$linode_id | jq -r '.ipv4[0]')
check_undefined "$ip_address" "IP address"

# Create terminate script
cat << EOF > terminate.sh
#!/bin/bash
# Terminate Linode instance
curl -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" https://api.linode.com/v4/linode/instances/$linode_id
EOF

# Wait for Linode instance to provision
check_linode_status "$linode_id"


# Transfer and execute terminate script on Linode instance

# others NEED TO CREATE SSH KEYS AND GIVE U THE PUBLIC KEY SO U ADD IN LINODE and thats it and the script will work

copy_terminate_script() {
    scp -o StrictHostKeyChecking=no terminate.sh root@$ip_address:/root
}

# Attempt to copy terminate.sh and retry in a loop until success
while ! copy_terminate_script; do
    echo "Failed to copy terminate.sh. Retrying in $retry_interval seconds..."
    sleep $retry_interval
done

scp -o StrictHostKeyChecking=no openvpn-install.sh root@$ip_address:/root
ssh -o StrictHostKeyChecking=no root@$ip_address "chmod +x /root/terminate.sh"

# Schedule terminate script using crontab
ssh -o StrictHostKeyChecking=no root@$ip_address "echo '0 */2 * * * /root/terminate.sh' | crontab -"

ssh -o StrictHostKeyChecking=no root@$ip_address "chmod +x /root/openvpn-install.sh"
ssh -o StrictHostKeyChecking=no root@$ip_address /root/openvpn-install.sh $OPEN_VPN_FILE

# Remove local terminate script
rm terminate.sh

scp -o StrictHostKeyChecking=no root@$ip_address:/root/$OPEN_VPN_FILE.ovpn $OPEN_VPN_FILE.ovpn


# Disable VPN logs
ssh -o StrictHostKeyChecking=no root@$ip_address "sed -i 's/^log /;log /' /etc/openvpn/server/server.conf"
ssh -o StrictHostKeyChecking=no root@$ip_address "systemctl restart openvpn-server@server.service"

# Prevent password access
# Disable password authentication for SSH
ssh -o StrictHostKeyChecking=no root@$ip_address "sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"

# Prevent SSH access
ssh -o StrictHostKeyChecking=no root@$ip_address "sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config"
ssh -o StrictHostKeyChecking=no root@$ip_address "systemctl restart sshd.service"

echo "###########################################################"
echo "###########################################################"
echo "###########################################################"
echo "###########################################################"
echo
echo "Setup completed successfully."
echo
echo "###########################################################"
echo "###########################################################"
echo "###########################################################"
echo "###########################################################"