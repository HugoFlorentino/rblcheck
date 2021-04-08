#! /bin/sh

which iprange > /dev/null
if [ $? -ne 0 ]; then
  echo "You must install the iprange package."
  echo
  exit
fi

which dnsbl_checker > /dev/null
if [ $? -ne 0 ]; then
  echo "Executable dnsbl_checker was not found."
  echo "Visit https://github.com/maticmeznar/dnsbl_checker/releases and download."
  echo "Extract the file, rename to dnsbl_checker and assign executable permissions."
  echo
  exit
fi

if [ $# -ne 1 ]; then
  echo "You must use as only argument a file with IP addresses or CIDR blocks."
  echo
  exit
elif [ ! -f "${1}" ]; then
  echo "File ${1} not found."
  exit
fi

CHECK=input.txt
cat "${1}" | sort -uV | iprange -1 > "${CHECK}"

RBL=blacklist.txt
rm -f "${RBL}"

echo "Fetching dnsbl-1.uceprotect.net.gz ..."
echo
wget -qO- 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-1.uceprotect.net.gz' | gzip -dc | grep -vE '^[^0-9]' | tr -s [:blank:] | cut -f1 -d ' ' | iprange -1 > "${RBL}"
if [ $? -ne 0 ]; then
  echo "An error was found while downloading the list to a file in current location."
  echo
  exit
fi

echo "Checking for coincidences ..."
echo

RESULTS=$(iprange --intersect -1 "${CHECK}" "${RBL}")

if [ -z "${RESULTS}" ]; then
  echo "No coincidences found."
  echo
  exit
else
  echo "IP addresses found in blacklist:"
  echo "${RESULTS}"
  echo
fi

for IP in ${RESULTS}; do
  echo "Checking ${IP} in several blacklists ..."
  dnsbl_checker --speed=100 ip ${IP}
  sleep 20
done

exit
