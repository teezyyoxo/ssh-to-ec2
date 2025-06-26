# EC2 SSH Script

A simple Bash script to SSH into an AWS EC2 instance by **instance ID or Name tag**, using the AWS CLI and environment variables stored in a `.env` file.

## 🔧 Features

- Connect to an EC2 instance using either its **Name tag** or **Instance ID**
- Reads configuration from a `.env` file (for security and flexibility)
- Automatically fetches the public IP using AWS CLI
- Supports `--dry-run` mode to preview the SSH command
- Neatly formatted terminal output
- Zero `eval` usage for safety

## 🛡 Requirements
-	macOS or Linux with Bash
-	AWS CLI v2 installed and configured with an SSO or standard profile
-	Appropriate IAM permissions for:
    ```console
    ec2:DescribeInstances
    ec2:GetConsoleOutput if extended features are added (optional)
    ```
## 📁 Setup

### 1. Clone the repo or copy the script:
Save the script file as `ec2-ssh.sh` and make it executable:
```chmod +x ec2-ssh.sh```

### 2. Create your .env file.
In the **same directory**, create a file named `.env`:
```console
    INSTANCE_KEY_PATH="/full/path/to/your-key.pem"
    SSH_USER="ubuntu"  # or ec2-user, admin, etc.
    REGION="us-east-2"
    PROFILE="your-aws-cli-profile-name"
```
💡 You can list AWS profiles using:
`aws configure list-profiles`

# 🚀 Usage
Connect to an instance by Name tag:
```console
./ec2-ssh.sh MyInstanceName
```
Connect to an instance by Instance ID
```console
./ec2-ssh.sh i-0123456789abcdef0
```
Dry run (only show the SSH command):
```bash
./ec2-ssh.sh MyInstanceName --dry-run
```
---
## 🧼 Example Output
```bash
user@somecomputer ssh-to-ec2 % bash ec2-ssh.sh someEC2instance

🔍 Searching for instance with Name tag: "someEC2instance"

==============================
✅ Found instance at 1.234.123.210
Connecting with command:
ssh -i "<path-to-key>.pem" ubuntu@1.234.123.210
==============================

==============================
🔐 Connecting...
==============================

Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 6.8.0-1029-aws x86_64)

 System information as of Thu Jun 26 13:05:27 UTC 2025

  System load:  0.67               Processes:             308
  Usage of /:   72.8% of 96.73GB   Users logged in:       0
  Memory usage: 13%                IPv4 address for ens5: 172.31.17.209
  Swap usage:   0%

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update

🌐 Public IP Address: 1.234.123.210

Last login: Thu Jun 26 12:58:34 2025 from 123.234.234.123
```

## 🧠 Tips
To support multiple environments, create .env.dev, .env.prod, etc., and modify the script to select based on input.
Protect your .env and PEM files:
```bash
chmod 600 .env
chmod 400 /path/to/key.pem
```
## 📜 License
MIT — free for personal or commercial use. Attribution appreciated.