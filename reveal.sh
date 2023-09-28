#!/bin/bash

# Default variable values
verbose_mode=false
output_file="reveal_out"
scan_udp=false
ports=""
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
# Function to display script usage
usage() {
 echo "Usage: $0 -t ip_address [-f output_file]"
 echo "Options:"
 echo " -h, --help      Display this help message"
 echo " -v, --verbose   Enable verbose mode"
 echo " -f, --file      FILE Specify an output file"
 echo " -t, --target    Specify target ip address"
 echo " -U, --udp       Include UDP ports scan"
}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

# Function to handle options and arguments
handle_options() {
  
  if [ $# -eq 0 ]; then
    echo -e "${RED}[-]${NC} No parameters specified"
    usage
    exit 1
  fi

  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      -v | --verbose)
        verbose_mode=true
        ;;
      -U | --udp)
        scan_udp=true
        ;;
      -f | --file*)
        if ! has_argument $@; then
          echo "${RED}[-]${NC} File not specified." >&2
          usage
          exit 1
        fi

        output_file=$(extract_argument $@)

        shift
        ;;
      -t | --target)
        if ! has_argument $@; then
          echo "${RED}[-]${NC} Target not specified." >&2
          usage
          exit 1
        fi
        
        target=$(extract_argument $@)

        shift
        ;;
      *)
        echo "${RED}[-]${NC} Invalid option: $1" >&2
        usage
        exit 1
        ;;

    esac
    shift
  done
}

tcpScan(){
 echo -e "${CYAN}[+]${NC} Starting TCP SYN Scan..."
  
 
  if [ "$verbose_mode" = true ]; then
    nmap -p- --open --min-rate 5000 -sS -n -vvv -Pn $target -oG portsInfo 
  else
    nmap -p- --open --min-rate 5000 -sS -n -Pn $target -oG portsInfo > /dev/null
  fi
  

  ports="$(cat ./portsInfo | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"

  
  
  if [ -n "$ports" ]; then
    echo -e "${CYAN}[+]${NC} TCP Open ports: ${PURPLE}$ports${NC}"
    echo -e "${CYAN}[+]${NC} Launching common nmap scripts...\n"
    nmap -p$ports -sCV -Pn -n $target -oN $output_file.tcp 2>/dev/null
  else
    echo -e "${RED}[-]${NC} No TCP ports detected \n"
  fi

  rm portsInfo

}

udpScan(){
 echo -e "${CYAN}[+]${NC} Starting UDP Scan..."
  
 
  if [ "$verbose_mode" = true ]; then
    nmap -p- --open --min-rate 5000 -sU -n -vvv -Pn $target -oG portsInfo 
  else
    nmap -p- --open --min-rate 5000 -sU -n -Pn $target -oG portsInfo > /dev/null
  fi
  

  ports="$(cat ./portsInfo | grep -oP '\d{1,5}/open/udp' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"

  
  
  if [ -n "$ports" ]; then
    echo -e "${CYAN}[+]${NC} UDP Open ports: ${PURPLE}$ports${NC}"
    echo -e "${CYAN}[+]${NC} Launching common nmap scripts...\n"
    nmap -p$ports -sCVU -Pn -n --min-rate 5000 $target -oN $output_file.udp 2>/dev/null
  else
    echo -e "${RED}[-]${NC} No UDP ports detected \n"
  fi

  rm portsInfo

}


# Main script execution
handle_options "$@"
printf "$CYAN"; figlet -f slant REVEAL 2>/dev/null; printf "$NC"

# Perform the desired actions based on the provided flags and arguments
if [ "$verbose_mode" = true ]; then
 echo -e "${CYAN}[+]${NC} Verbose mode enabled."
fi

if [ -n "$output_file" ]; then
 echo -e "${CYAN}[+]${NC} Output file name: $output_file \n"
fi

# Detect OS based on TTL 
ttl="$(ping -c 1 $target | grep -oP 'ttl=\d{1,3}' | tr -d 'ttl=')"


if [ "$ttl" -le 64 ] 2>/dev/null && [ "$ttl" -gt 0 ] 2>/dev/null; then
  echo -e "${CYAN}[+]${NC} Detected OS ----> ${PURPLE}Linux${NC}"
elif [ "$ttl" -gt 64 ] 2>/dev/null && [ "$ttl" -le 128 ] 2>/dev/null; then
  echo -e "${CYAN}[+]${NC} Detected OS ----> ${PURPLE}Windows${NC}"
else
  echo -e "${RED}[-]${NC} No OS detected"
fi

# Start TCP SYN Scan
tcpScan

# Start UDP Scan if specified
if [ "$scan_udp" = true ]; then
  udpScan
fi



