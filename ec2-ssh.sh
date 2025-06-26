#!/bin/bash
# ec2-ssh.sh v1.0.0 - Auto SSH into EC2 instance using Name tag

# --- CONFIGURATION ---
INSTANCE_NAME="MyInstanceName"         # Name tag of the EC2 instance
KEY_PATH="$HOME/.ssh/my-key.pem"       # Path to your SSH key
USER="ubuntu"                          # SSH username (ec2-user, ubuntu, admin, etc.)
REGION="us-east-1"                     # AWS region
DRY_RUN=false                          # Set to true to print command only

# --- VALIDATE ---
if ! command -v aws &> /dev/null; then
  echo "❌ AWS CLI not installed."
  exit 1
fi

echo "🔍 Looking for EC2 instance named \"$INSTANCE_NAME\"..."

IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=$INSTANCE_NAME" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [[ -z "$IP" || "$IP" == "None" ]]; then
  echo "❌ Could not find a running EC2 instance with name \"$INSTANCE_NAME\"."
  exit 1
fi

echo "✅ Found public IP: $IP"

SSH_CMD="ssh -i \"$KEY_PATH\" $USER@$IP"

if [ "$DRY_RUN" = true ]; then
  echo "🔧 SSH command: $SSH_CMD"
else
  echo "🔐 Connecting..."
  eval "$SSH_CMD"
fi