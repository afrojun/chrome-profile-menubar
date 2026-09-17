#!/bin/zsh
set -euo pipefail

identity_name="ProfileBar Local Signing"
login_keychain="$(security default-keychain -d user | tr -d '"[:space:]')"
valid_identities="$(security find-identity -v -p codesigning "$login_keychain" 2>/dev/null || true)"

if [[ "$valid_identities" == *"\"$identity_name\""* ]]; then
    print "Local signing identity is already set up."
    exit 0
fi

if security find-certificate -c "$identity_name" "$login_keychain" >/dev/null 2>&1; then
    print -u2 "A certificate named '$identity_name' exists but is not valid for code signing."
    print -u2 "Inspect it in Keychain Access before trying again."
    exit 1
fi

temporary_dir="$(mktemp -d /private/tmp/profilebar-signing.XXXXXX)"
cleanup() {
    rm -rf -- "$temporary_dir"
}
trap cleanup EXIT
umask 077

certificate="$temporary_dir/certificate.pem"
private_key="$temporary_dir/private-key.pem"
identity="$temporary_dir/identity.p12"
serial_number="0x$(/usr/bin/openssl rand -hex 16)"
identity_password="$(/usr/bin/openssl rand -hex 24)"

/usr/bin/openssl req -x509 -newkey rsa:3072 -sha256 -nodes -days 3650 \
    -subj "/CN=$identity_name" \
    -set_serial "$serial_number" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -keyout "$private_key" \
    -out "$certificate" >/dev/null 2>&1

/usr/bin/openssl pkcs12 -export \
    -name "$identity_name" \
    -inkey "$private_key" \
    -in "$certificate" \
    -out "$identity" \
    -passout "pass:$identity_password"

security import "$identity" \
    -k "$login_keychain" \
    -P "$identity_password" \
    -T /usr/bin/codesign >/dev/null

security add-trusted-cert \
    -r trustRoot \
    -p codeSign \
    -k "$login_keychain" \
    "$certificate"

valid_identities="$(security find-identity -v -p codesigning "$login_keychain" 2>/dev/null || true)"
if [[ "$valid_identities" != *"\"$identity_name\""* ]]; then
    print -u2 "The certificate exists but macOS still does not accept it for code signing."
    print -u2 "Inspect its trust settings and Code Signing usage in Keychain Access."
    exit 1
fi

print "Local signing identity '$identity_name' is ready."
