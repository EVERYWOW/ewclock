# shellcheck shell=bash
# Loads App Store Connect API key settings for release scripts.
#
# Values come from the environment or, if unset, from the untracked file
# ~/.appstoreconnect/ewclock.env (override with ASC_ENV_FILE):
#
#   ASC_KEY_ID=<key id>
#   ASC_ISSUER_ID=<issuer id>
#
# The private key is read from ~/.appstoreconnect/private_keys/AuthKey_<key id>.p8
# unless ASC_KEY_PATH is set. Never commit these values or the key file.

ASC_ENV_FILE="${ASC_ENV_FILE:-$HOME/.appstoreconnect/ewclock.env}"
if [[ -f "$ASC_ENV_FILE" ]]; then
  while IFS='=' read -r name value; do
    case "$name" in
      ASC_KEY_ID|ASC_ISSUER_ID|ASC_KEY_PATH)
        if [[ -z "${!name:-}" ]]; then
          export "$name=$value"
        fi
        ;;
    esac
  done < "$ASC_ENV_FILE"
fi

if [[ -z "${ASC_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" ]]; then
  echo "Missing App Store Connect API key settings." >&2
  echo "Set ASC_KEY_ID and ASC_ISSUER_ID or create $ASC_ENV_FILE." >&2
  exit 1
fi

export ASC_KEY_PATH="${ASC_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8}"
if [[ ! -f "$ASC_KEY_PATH" ]]; then
  echo "Missing App Store Connect API key: $ASC_KEY_PATH" >&2
  exit 1
fi

ASC_AUTH_ARGS=(
  -authenticationKeyPath "$ASC_KEY_PATH"
  -authenticationKeyID "$ASC_KEY_ID"
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
)
