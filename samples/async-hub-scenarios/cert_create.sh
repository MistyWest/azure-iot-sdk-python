#!/bin/bash

# Script to generate an X.509 certificate for a device with customizable validity period.

# Function to display usage information
usage() {
    echo "Usage: $0 <device-name> <days-valid>"
    echo ""
    echo "Description:"
    echo "  the script will create a X.509 certificate and key with the common name set to <device-name>"
    echo "  it also provides a .env-<device-name> file to set the environment that's used to provision"
    echo "  the device according to the enrolment set in vr05-deviceprovisioningservice with the provided"
    echo "  provision_x509.py python script."
    echo "Arguments:"
    echo "  <device-name>  The name of the device for which the certificate is generated."
    echo "  <days-valid>   The number of days the certificate should remain valid."
    echo ""
    echo "Example:"
    echo "  $0 device-name 365"
    exit 0
}

# Check if -h or --help is passed
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# Check if the correct number of arguments is provided
if [[ $# -ne 2 ]]; then
    echo "Error: Invalid number of arguments."
    usage
fi

# Assign command-line arguments to variables
DEVICE_NAME=$1
VALIDITY_DAYS=$2

# Validate if days is a number
if ! [[ "$VALIDITY_DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: <days-valid> must be a positive integer."
    exit 1
fi

# File names based on device name
KEY_FILE="${DEVICE_NAME}-key.pem"
CERT_FILE="${DEVICE_NAME}-cert.pem"

# Generate the X.509 certificate
openssl req -outform PEM -x509 -sha256 -newkey rsa:4096 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days "$VALIDITY_DAYS" \
    -extensions usr_cert \
    -addext extendedKeyUsage=clientAuth \
    -subj "/CN=${DEVICE_NAME}"

# Check if the certificate was created successfully
if [[ $? -eq 0 ]]; then
    echo "Certificate and key files have been created:"
    echo "  Private Key: $KEY_FILE"
    echo "  Certificate: $CERT_FILE"
else
    echo "Error: Failed to generate the certificate."
    exit 1
fi
# Write env file to be able to easily configure the environment for YVR05 DPS before provisioning
cat << EOF > .env_${DEVICE_NAME}
export PROVISIONING_HOST=global.azure-devices-provisioning.net
export PROVISIONING_IDSCOPE=0ne00E09BB1
export DPS_X509_REGISTRATION_ID=${DEVICE_NAME}
export X509_CERT_FILE=./${CERT_FILE}
export X509_KEY_FILE=./${KEY_FILE}
export X509_PASS_PHRASE=1234
EOF

