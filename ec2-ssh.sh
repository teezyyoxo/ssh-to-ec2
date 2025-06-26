#!/bin/bash
# ec2-ssh.sh v1.4.1 - SSH into EC2 using name or ID, using a fixed AWS profile

# --- USER CONFIGURATION ---
INSTANCE_KEY_PATH=".pem"   # Path to your SSH private key
SSH_USER="ubuntu"                           # SSH login username
REGION="us-east-2"                          # AWS region
PROFILE="------"                         # Your AWS profile name (configured with aws configure sso. Review with 'aws configure list-profiles'.)

# --- USAGE FUNCTION ---
usage() {
  echo "Usage: $0 <instance-id or name-tag> [--dry-run]"
  echo "Example:"
  echo "  $0 i-0123456789abcdef0"
  echo "  $0 MyInstanceName"
  echo "  $0 MyInstanceName --dry-run"
  exit 1
}

# --- PARSE ARGUMENTS ---
if [ $# -lt 1 ]; then usage; fi

INPUT=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      ;;
    *)
      if [[ -z "$INPUT" ]]; then
        INPUT="$1"
      else
        echo "Unexpected argument: $1"
        usage
      fi
      shift
      ;;
  esac
done

# --- VALIDATION ---
if ! command -v aws &> /dev/null; then
  echo "❌ AWS CLI not installed."
  exit 1
fi

# --- DETERMINE INSTANCE FILTER ---
echo ""
if [[ "$INPUT" =~ ^i-[0-9a-f]{8,}$ ]]; then
  echo "🔍 Using instance ID: $INPUT"
  FILTER=(--instance-ids "$INPUT")
else
  echo "🔍 Searching for instance with Name tag: \"$INPUT\""
  FILTER=(--filters "Name=tag:Name,Values=$INPUT" "Name=instance-state-name,Values=running")
fi
echo ""
# --- GET PUBLIC IP ---
IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --profile "$PROFILE" \
  "${FILTER[@]}" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text 2>/dev/null)

if [[ -z "$IP" || "$IP" == "None" ]]; then
  echo "❌ No running instance found or instance has no public IP."
  exit 1
fi
echo ""
# --- CONNECT ---
SSH_CMD="ssh -i \"$INSTANCE_KEY_PATH\" $SSH_USER@$IP"
echo "=============================="
echo "✅ Found instance at $IP"
echo "Connecting with command: $SSH_CMD"
echo "=============================="

if [ "$DRY_RUN" = true ]; then
  echo "🔧 SSH command:"
  echo "$SSH_CMD"
else
  echo "[🔐 Connecting...]"
  echo "=============================="
  echo ""
  eval "$SSH_CMD"
  echo ""
  echo "[✅ SSH session ended]"
fi
