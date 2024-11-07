#!/bin/sh
################################################################################
# Script to setup acess to the mergdev apt repository
#
#   07 November, 2023 - E M Thornber
#   Created from kitware-archive.sh (authors of CMake)
#
#   30 August, 2023 - E M Thornber
#   Updated Raspbian release to Bookworm
#
#   03 November, 2024 - E M Thornber
#   Corrected repo URL
#
################################################################################

# -e - exit immediately if a command exits with non-zero status
# -u - treat unset variables as an error when substituting
set -eu

help() {
  echo "Usage: $0 [--release <raspbian-release>]" > /dev/stderr
}

doing=
rc=
release=
help=
for opt in "$@"
do
  case "${doing}" in
  release)
    release="${opt}"
    doing=
    ;;
  "")
    case "${opt}" in
    --release)
      doing=release
      ;;
    --help)
      help=1
      ;;
    esac
    ;;
  esac
done

if [ -n "${doing}" ]
then
  echo "--${doing} option given no argument." > /dev/stderr
  echo > /dev/stderr
  help
  exit 1
fi

if [ -n "${help}" ]
then
  help
  exit
fi

if [ -z "${release}" ]
then
  unset VERSION_CODENAME
  unset ID
  . /etc/os-release

  if [ "${ID}" != "raspbian" ]
  then
    echo "This is not a Raspbian system. Aborting." > /dev/stderr
    exit 1
  fi

  release="${VERSION_CODENAME}"
fi

case "${release}" in
bookworm)
  packages=
  keyring_packages="ca-certificates gpg wget"
  ;;
*)
  echo "Only Raspbian bookworm is supported. Aborting." > /dev/stderr
  exit 1
  ;;
esac

get_keyring=
if [ ! -f /usr/share/keyrings/mergdev-archive-keyring.gpg ]
then
  packages="${packages} ${keyring_packages}"
  get_keyring=1
fi

# Start the real work
set -x

apt-get update
# shellcheck disable=SC2086
apt-get install -y ${packages}

test -n "${get_keyring}" && (wget -O - https://repo.littlegarth.org.uk/raspbian/gpg-pubkey.asc 2>/dev/null | gpg --dearmor - > /usr/share/keyrings/mergdev-archive-keyring.gpg)

echo "deb [signed-by=/usr/share/keyrings/mergdev-archive-keyring.gpg] https://repo.littlegarth.org.uk/raspbian/ ${release} main" > /etc/apt/sources.list.d/mergdev.list

apt-get update
