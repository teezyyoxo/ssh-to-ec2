#!/bin/bash
# ec2-ssh.sh v1.2.0 - SSH into EC2 instance using Name tag or Instance ID from CLI args

# --- DEFAULT CONFIG ---
KEY_PATH="$HOME/.ssh/my-key.pem"  # Path to SSH key
USER="ubuntu"                     # SSH user (e.g., ubuntu, ec2-user)
REGION="us-east-1"               # AWS region

# --- USAGE ---
usage() {
  echo "Usage: $0 <instance-id or name-tag> [--dry-run]"
  echo "Example:"
  echo "  $0 i-0123456789abcdef0"
  echo "  $0 MyInstanceName --dry-run"
  exit 1
}

# --- PARSE ARGUMENTS ---
if [ $# -lt 1 ]; then usage; fi

INPUT="$1"
DRY_RUN=false
[[ "$2" == "--dry-run" ]] && DRY_RUN=true

# --- VALIDATION ---
if ! command -v aws &> /dev/null; then
  echo "❌ AWS CLI not installed."
  exit 1
fi

# --- DETECT INSTANCE ID OR NAME ---
if [[ "$INPUT" =~ ^i-[0-9a-f]{8,}$ ]]; then
  echo "🔍 Using instance ID: $INPUT"
  FILTER=(--instance-ids "$INPUT")
else
  echo "🔍 Searching for instance with Name tag: \"$INPUT\""
  FILTER=(--filters "Name=tag:Name,Values=$INPUT" "Name=instance-state-name,Values=running")
fi

# --- GET PUBLIC IP ---
IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  "${FILTER[@]}" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [[ -z "$IP" || "$IP" == "None" ]]; then
  echo "❌ No running instance found or instance has no public IP."
  exit 1
fi

# --- SSH ---
echo "✅ Found instance at $IP"
SSH_CMD="ssh -i \"$KEY_PATH\" $USER@$IP"

if [ "$DRY_RUN" = true ]; then
  echo "🔧 SSH command:"
  echo "$SSH_CMD"
else
  echo "🔐 Connecting..."
  eval "$SSH_CMD"
fi