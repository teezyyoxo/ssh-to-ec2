#!/bin/bash
# ec2-ssh.sh v1.1.0 - SSH into EC2 using either Name tag or Instance ID

# --- CONFIGURATION ---
INSTANCE_ID_OR_NAME="i-0abcdef1234567890"  # Can be instance ID or Name tag
KEY_PATH="$HOME/.ssh/my-key.pem"           # Path to your SSH key
USER="ubuntu"                              # SSH username (ec2-user, ubuntu, admin, etc.)
REGION="us-east-1"                         # AWS region
DRY_RUN=false                              # true = only print SSH command

# --- VALIDATION ---
if ! command -v aws &> /dev/null; then
  echo "❌ AWS CLI is not installed."
  exit 1
fi

# --- DETERMINE FILTER TYPE ---
if [[ "$INSTANCE_ID_OR_NAME" =~ ^i-[0-9a-f]{8,}$ ]]; then
  echo "🔍 Using instance ID: $INSTANCE_ID_OR_NAME"
  FILTER=(--instance-ids "$INSTANCE_ID_OR_NAME")
else
  echo "🔍 Looking for instance with tag Name=$INSTANCE_ID_OR_NAME"
  FILTER=(--filters "Name=tag:Name,Values=$INSTANCE_ID_OR_NAME" "Name=instance-state-name,Values=running")
fi

# --- FETCH PUBLIC IP ---
IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  "${FILTER[@]}" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [[ -z "$IP" || "$IP" == "None" ]]; then
  echo "❌ Could not find a running EC2 instance with that ID or name."
  exit 1
fi

# --- SSH COMMAND ---
echo "✅ Found public IP: $IP"
SSH_CMD="ssh -i \"$KEY_PATH\" $USER@$IP"

if [ "$DRY_RUN" = true ]; then
  echo "🔧 SSH command: $SSH_CMD"
else
  echo "🔐 Connecting..."
  eval "$SSH_CMD"
fi