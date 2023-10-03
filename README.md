# miele-network
My understanding of how a miele washing machine talk to the internet

## Setup

The washing machine is isolated in dedicated wifi network. The router uses openwrt to give me maximum control over the network flows.
All flows between this network and the other networks wan are rejected.

Washing machine requires usage of WPS to connect to the wifi. Documentation for WPS on openwrt is [here](https://openwrt.org/docs/guide-user/network/wifi/basic).

## Analysis of washingmachine_part0.pcap

First connection attempt is stored in `washingmachine_part0.pcap`

### DHCP

The washing machine uses `00:1d:63:36:21:44` as mac address (`00:1d:63` prefix is associated with Miele company).
It request an infinite lease and identify itself with the hostname `001D63362144-mysimplelink`.
My router answers, all good. At this point the washing machine displays "success" and consider itself connected, even though it has not talked home yet.

## MDNS

The machine starts with a bunch of MDNS requests to get all records related to its hostname `001D63362144-mysimplelink.local: type ANY, class IN, "QM"  question`. Of course nothing can answer apart from the machine itself. After 0.5s, the machine answers to itself with its own ip address (A record).

A bit later, it will also query `Miele-001D63FFFE362144.local`.
Then again, it will also query `Miele WCI960._mieleathome._tcp.local` SRV and TXT records:
- The answer for the TXT record (from the machine itself is `txtvers=1`, `group=`, `path=/`, `security=1`, `pairing=false`, `devicetype=1`, `con=0`, `subtype=0`, `s=0`
- The answer for the SRV record is `Miele-001D63FFFE362144.local` with port 80.


## DNS

The machine eventually tries to use DNS to resolve ntp servers `ntp.mcs2.miele.com`. Without answer, it tries several times per second.
  
