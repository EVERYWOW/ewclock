# shellcheck shell=bash
# Signs local Debug builds ad hoc, so tests and local runs need no development
# certificate in the keychain. Ad hoc signing keeps the Mac sandbox entitlement.
# Release signing happens in script/archive.sh through the App Store Connect API key.
LOCAL_SIGNING_ARGS=(
  CODE_SIGN_STYLE=Manual
  CODE_SIGN_IDENTITY=-
  PROVISIONING_PROFILE_SPECIFIER=
)
