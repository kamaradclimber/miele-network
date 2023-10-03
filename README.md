# miele-network
My understanding of how a miele washing machine talk to the internet

## Setup

The washing machine is isolated in dedicated wifi network. The router uses openwrt to give me maximum control over the network flows.
All flows between this network and the other networks wan are rejected.

Washing machine requires usage of WPS to connect to the wifi. Documentation for WPS on openwrt is [here](https://openwrt.org/docs/guide-user/network/wifi/basic).

## Analysis

### DHCP

The washing machine uses `00:1d:63:36:21:44` as mac address (`00:1d:63` prefix is associated with Miele company).
It request an infinite lease and identify itself with the hostname `001D63362144-mysimplelink`.
My router answers, all good. At this point the washing machine displays "success" and consider itself connected, even though it has not talked home yet.
