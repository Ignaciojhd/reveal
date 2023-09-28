# Reveal
A handy bash script designed to identify open ports and determine the operating system of a specified host by leveraging NMAP and analyzing TTL information.

![Reveal](Reveal.png)

## Usage

```bash
Usage: ./reveal.sh -t ip_address [-f output_file]
Options:
 -h, --help      Display this help message
 -v, --verbose   Enable verbose mode
 -f, --file      FILE Specify an output file
 -t, --target    Specify target ip address
 -U, --udp       Include UDP ports scan
```




