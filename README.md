# miele-network
My understanding of how a miele washing machine talk to the internet

## Setup

The washing machine is isolated in dedicated wifi network. The router uses openwrt to give me maximum control over the network flows.
All flows between this network and the other networks wan are rejected.

Washing machine requires usage of WPS to connect to the wifi. Documentation for WPS on openwrt is [here](https://openwrt.org/docs/guide-user/network/wifi/basic).

## Analysis of `washingmachine_part0.pcap`

First connection attempt is stored in `washingmachine_part0.pcap`

### DHCP

The washing machine uses `00:1d:63:36:21:44` as mac address (`00:1d:63` prefix is associated with Miele company).
It request an infinite lease and identify itself with the hostname `001D63362144-mysimplelink`.
My router answers, all good. At this point the washing machine displays "success" and consider itself connected, even though it has not talked home yet.

### MDNS

The machine starts with a bunch of MDNS requests to get all records related to its hostname `001D63362144-mysimplelink.local: type ANY, class IN, "QM"  question`. Of course nothing can answer apart from the machine itself. After 0.5s, the machine answers to itself with its own ip address (A record).

A bit later, it will also query `Miele-001D63FFFE362144.local`.
Then again, it will also query `Miele WCI960._mieleathome._tcp.local` SRV and TXT records:
- The answer for the TXT record (from the machine itself is `txtvers=1`, `group=`, `path=/`, `security=1`, `pairing=false`, `devicetype=1`, `con=0`, `subtype=0`, `s=0`
- The answer for the SRV record is `Miele-001D63FFFE362144.local` with port 80.


### DNS

The machine eventually tries to use DNS to resolve ntp servers `ntp.mcs2.miele.com`. Without answer, it tries several times per second.
  
With `nmap -A -v 20.224.173.25`:

```
Host is up (0.020s latency).
Not shown: 998 filtered tcp ports (no-response)
PORT    STATE SERVICE  VERSION
80/tcp  open  http     nginx (reverse proxy)
|_http-title: 404 Not Found
443/tcp open  ssl/http nginx (reverse proxy)
| tls-nextprotoneg: 
|_  http/1.1
| tls-alpn: 
|_  http/1.1
|_ssl-date: TLS randomness does not represent time
| ssl-cert: Subject: commonName=*.mcs2.miele.com
| Issuer: commonName=RootCA-mcs2.miele.com
| Public Key type: rsa
| Public Key bits: 2048
| Signature Algorithm: sha256WithRSAEncryption
| Not valid before: 2015-10-29T11:15:14
| Not valid after:  2045-09-01T11:15:14
| MD5:   64ca:45d2:c4a2:2473:55d8:54b0:47d2:c1c4
|_SHA-1: bf31:8af6:c008:335e:edb7:b3e0:dd7f:1ed2:d535:b4df
|_http-title: 404 Not Found
```

Once it has a dns answer, it tries to connect on port 80 to `ntp.mcs2.miele.com`.

## Interception

Using openwrt, we can force traffic going out of the washing machine to be redirected (at the ip layer) to a machine we control. This should be enough to intercept and manipulate http (not https) traffic.

Here is the firewall rule:
```
config redirect
	option target 'DNAT'
	option family 'ipv4'
	option src 'LowTrust'
	option src_dport '80'
	option dest_ip '192.168.0.137'
	option dest_port '8078'
```

`192.168.0.137` is the machine I'm using at the moment. We can use `nc -l -p 8078 -k` to make it at least accept httprequests.

### Initial http request `washingmachine_part1.pcap`

We can see (packet 17), connection is accepted. There is a simple http request:

```
GET http://ntp.mcs2.miele.com/V2/NTP/ HTTP/1.1
Host: ntp.mcs2.miele.com
Cache-Control: max-age=0
Content-Length:0
Accept: application/vnd.miele.v1+json
```

Doing this request ourselves, we can get the normal response:
```
curl http://ntp.mcs2.miele.com/V2/NTP/ -v
*   Trying 20.224.173.25:80...
* Connected to ntp.mcs2.miele.com (20.224.173.25) port 80
> GET /V2/NTP/ HTTP/1.1
> Host: ntp.mcs2.miele.com
> User-Agent: curl/8.3.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Date: Sun, 08 Oct 2023 15:33:51 GMT
< Content-Type: application/vnd.miele.v1+json;charset=UTF-8
< Content-Length: 19
< Connection: keep-alive
< X-Environment: mcs-eu-prod-default
< Vary: Accept-Encoding
< 
* Connection #0 to host ntp.mcs2.miele.com left intact
{"time":1696779231}
```

So we have NTP over http. Probably a way to work in more restricted networks where ntp port might not be opened.

We can now capture that request with a super simple fake http server to give the washing machine what it expects. I'm using [sinatra](https://sinatrarb.com/intro.html) with a simple server written in ruby. See `fake_miele.rb` file and launch it with `ruby fake_miele.rb`
