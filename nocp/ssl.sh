#!/usr/bin/env bash
#
# issue-ssl.sh
#
# Usage: ./issue-ssl.sh <domain>
#
# A Bash script that:
#   - Accepts a domain name from the command line (no prompting for domain).
#   - Asks whether to use Cloudflare DNS plugin (y/N).
#   - If yes, prompts for Cloudflare email and Cloudflare API token (you can paste the token).
#   - Issues an SSL certificate with Certbot.
#   - Installs the certificate in Apache at the end.

set -euo pipefail

# -------------------------
# Color and Style Variables
# -------------------------
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_CYAN="\033[36m"
COLOR_RED="\033[31m"
COLOR_BOLD="\033[1m"
COLOR_RESET="\033[0m"

# A small helper function to print a bold colored line
pretty_line() {
  local char="${1:-=}"
  local length="${2:-50}"
  printf "%${length}s\n" | tr ' ' "${char}"
}

# -------------------------
# Fancy Header
# -------------------------
clear
pretty_line "=" 60
echo -e "${COLOR_BOLD}${COLOR_CYAN}     Let's Encrypt SSL Certificate Issuance     ${COLOR_RESET}"
pretty_line "=" 60
echo

# -------------------------
# 1) Check if domain arg was supplied
# -------------------------
if [[ $# -lt 1 ]]; then
  echo -e "${COLOR_BOLD}${COLOR_RED}Error:${COLOR_RESET} No domain provided."
  echo "Usage: $0 <domain>"
  exit 1
fi

DOMAIN="$1"

# -------------------------
# 2) Check if certbot exists
# -------------------------
if ! command -v certbot >/dev/null 2>&1; then
  echo -e "${COLOR_BOLD}${COLOR_RED}Error:${COLOR_RESET} 'certbot' is not installed or not in PATH."
  echo "Please install certbot first (e.g., 'sudo apt-get install certbot')."
  exit 1
fi

# Optional: Check if the Cloudflare plugin is recognized by certbot
if certbot plugins 2>/dev/null | grep -q 'dns-cloudflare'; then
  CLOUDFLARE_PLUGIN_AVAILABLE=true
else
  CLOUDFLARE_PLUGIN_AVAILABLE=false
fi

# -------------------------
# 3) Ask if we want Cloudflare
# -------------------------
echo -e "${COLOR_BOLD}You entered domain:${COLOR_RESET} ${COLOR_GREEN}${DOMAIN}${COLOR_RESET}"
echo -e "${COLOR_BOLD}Step 1:${COLOR_RESET} Do you want to use the Cloudflare DNS plugin? (y/N)"
read -p "$(echo -e "${COLOR_GREEN}Use Cloudflare [y/N]:${COLOR_RESET} ")" USE_CLOUDFLARE
USE_CLOUDFLARE="${USE_CLOUDFLARE,,}"  # convert to lowercase
echo

# -------------------------
# 4) If yes -> get Cloudflare email & token
# -------------------------
if [[ "$USE_CLOUDFLARE" == "y" || "$USE_CLOUDFLARE" == "yes" ]]; then
  
  if [ "$CLOUDFLARE_PLUGIN_AVAILABLE" = false ]; then
    echo -e "${COLOR_BOLD}${COLOR_RED}Cloudflare plugin is not installed or not recognized by certbot.${COLOR_RESET}"
    echo "Please install it. For Debian/Ubuntu-based systems, for example:"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install python3-certbot-dns-cloudflare"
    echo "Or install via pip (and ensure certbot sees the plugin)."
    exit 1
  fi

  # Ask user for Cloudflare token
  echo -e "${COLOR_BOLD}Step 3:${COLOR_RESET} Please enter/paste your Cloudflare API token (then press Enter)."
  read -p "$(echo -e "${COLOR_GREEN}Cloudflare API Token:${COLOR_RESET} ")" CF_API_TOKEN
  if [[ -z "$CF_API_TOKEN" ]]; then
    echo -e "${COLOR_BOLD}${COLOR_RED}No Cloudflare API token entered. Exiting...${COLOR_RESET}"
    exit 1
  fi

  # Write it into /root/.cloudflare.ini (or another secure path)
  CRED_FILE="/root/.cloudflare.ini"
  sudo bash -c "cat <<EOF > '$CRED_FILE'
# Cloudflare credentials
dns_cloudflare_api_token = $CF_API_TOKEN
EOF"
  sudo chmod 600 "$CRED_FILE"

  # Issue certificate using DNS Cloudflare
  echo -e "${COLOR_BOLD}Issuing certificate using Cloudflare DNS plugin for domain:${COLOR_RESET} $DOMAIN"
  sudo certbot certonly \
    --non-interactive \
    --agree-tos \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CRED_FILE" \
    -d "$DOMAIN"

else
  # No Cloudflare -> fallback to standalone
  echo -e "${COLOR_BOLD}Issuing certificate using the standalone method for domain:${COLOR_RESET} $DOMAIN"
  sudo certbot certonly \
    --non-interactive \
    --agree-tos \
    --standalone \
    -d "$DOMAIN"
fi

# -------------------------
# 5) Install the certificate for Apache
# -------------------------
echo
pretty_line "-" 60
echo -e "${COLOR_BOLD}Installing the SSL certificate in Apache...${COLOR_RESET}"
echo

# We assume the cert name is the same as the domain used above.
# If your certificate name differs, adjust accordingly.
sudo certbot --apache \
  --cert-name "$DOMAIN" \
  --non-interactive

# -------------------------
# 6) Done
# -------------------------
echo
pretty_line "-" 60
echo -e "${COLOR_BOLD}${COLOR_YELLOW}Certificate issuance and Apache installation completed for domain:${COLOR_RESET} ${DOMAIN}"
echo "You can find your certificate in /etc/letsencrypt/live/$DOMAIN/"
pretty_line "-" 60
echo
