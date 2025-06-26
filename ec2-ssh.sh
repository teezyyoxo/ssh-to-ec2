#!/bin/bash
# ec2-ssh.sh v1.5.1 - SSH into EC2 using name or ID, now with .env support

# --- LOAD .ENV BECAUSE PRIVACYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ .env file not found at $ENV_FILE"
  exit 1
fi

# Load the .env
set -a
source "$ENV_FILE"
set +a

# Validate variables in .env
REQUIRED_VARS=(INSTANCE_KEY_PATH SSH_USER REGION PROFILE)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var}" ]]; then
    echo "❌ Missing required variable: $var in .env"
    exit 1
  fi
done

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
echo "=============================="
echo "✅ Found instance at $IP"
echo "Connecting with command:"
echo "ssh -i \"$INSTANCE_KEY_PATH\" $SSH_USER@$IP"
echo "=============================="

if [ "$DRY_RUN" = true ]; then
  echo "🔧 DRY RUN MODE — no connection attempted."
else
  echo -e "\n=============================="
  echo "🔐 Connecting..."
  echo "=============================="
  echo ""
  ssh -i "$INSTANCE_KEY_PATH" "$SSH_USER@$IP"
  echo ""
  echo "[✅ SSH session ended]"
fi
