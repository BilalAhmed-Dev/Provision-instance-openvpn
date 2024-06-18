# Linode Instance Provisioning and Setup

This script automates the provisioning and setup of a Linode instance for OpenVPN deployment. It creates a Linode instance, installs OpenVPN, configures automatic termination, and enhances security settings.

## Prerequisites

Before running this script, ensure you have:

1. **Linode Account**: You need an active Linode account with API access.
2. **API Token**: Obtain an API token from Linode with appropriate permissions.

## Configuration

Make sure to configure `config.sh` with the following variables:

- `API_TOKEN`: Your Linode API token.
- `LABEL`: A label for your Linode instance.
- `TYPE`: Linode instance type (e.g., `g6-nanode-1`).
- `REGION`: Linode region (e.g., `eu-west`).
- `IMAGE`: Linode image (e.g., `linode/ubuntu22.04`).
- `ROOT_PASS`: Root password for initial setup.
- `USER`: Your Linode account username.


# Linode Instance Deployment and OpenVPN Setup

This Bash script automates the deployment of a Linode instance and sets up OpenVPN on it securely.

## Usage

### Execution

To use the deployment script, follow these instructions:

1. **Run the Script**

   Execute the script `provision-linode.sh` with optional arguments:

   ```bash
   ./provision-linode.sh [OPEN_VPN_FILE]


2. **Import the OpenVPN Configuration:**
   - Import the generated OpenVPN configuration file (`[OPEN_VPN_FILE].ovpn`) into your OpenVPN client.


## Notes

- **Security**: Password authentication and root login are disabled for enhanced security.
- **Automated Termination**: To manage costs, the instance is automatically terminated after 2 hours by default.
