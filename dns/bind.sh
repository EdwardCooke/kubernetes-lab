#!/bin/bash

echo '
$ORIGIN .
$TTL 300        ; 5 minutes
122.168.192.in-addr.arpa  IN SOA  dns.k8s.lan. lab.k8s.lan. (
                                1      ; serial
                                604800     ; refresh (1 week)
                                86400      ; retry (1 day)
                                2419200    ; expire (4 weeks)
                                604800     ; minimum (1 week)
                                )
                        NS      services.k8s.lan.
$ORIGIN 122.168.192.in-addr.arpa.
1                       PTR     kubernetes.k8s.lan.
201                     PTR     kube1.k8s.lan.
202                     PTR     kube2.k8s.lan.
210                     PTR     kube1cp1.k8s.lan.
211                     PTR     kube1cp2.k8s.lan.
212                     PTR     kube1cp3.k8s.lan.
213                     PTR     kube1w1.k8s.lan.
214                     PTR     kube1w2.k8s.lan.
215                     PTR     kube1w3.k8s.lan.
220                     PTR     kube2cp1.k8s.lan.
221                     PTR     kube2cp2.k8s.lan.
222                     PTR     kube2cp3.k8s.lan.
223                     PTR     kube2w1.k8s.lan.
224                     PTR     kube2w2.k8s.lan.
225                     PTR     kube2w3.k8s.lan.
254                     PTR     dns.k8s.lan.
' > /etc/bind/db.192.168.122

echo '
$ORIGIN .
$TTL 300        ; 5 minutes
k8s.lan                 IN SOA  dns.k8s.lan. lab.k8s.lan. (
                                1          ; serial
                                60         ; refresh (1 minute)
                                60         ; retry (1 minute)
                                60         ; expire (1 minute)
                                60         ; minimum (1 minute)
                                )
                        NS      dns.k8s.lan.
$ORIGIN k8s.lan.
kubernetes              A       192.168.122.1
dns                     A       192.168.122.254
kube1                   A       192.168.122.201
kube2                   A       192.168.122.202
kube1cp1                A       192.168.122.210
kube1cp2                A       192.168.122.211
kube1cp3                A       192.168.122.212
kube1w1                 A       192.168.122.213
kube1w2                 A       192.168.122.214
kube1w3                 A       192.168.122.215
kube2cp1                A       192.168.122.220
kube2cp2                A       192.168.122.221
kube2cp3                A       192.168.122.222
kube2w1                 A       192.168.122.223
kube2w2                 A       192.168.122.224
kube2w3                 A       192.168.122.225
' > /etc/bind/db.k8s.lan

echo '
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

include "/etc/bind/rndc.key";

controls {
    inet 127.0.0.1 port 953 allow { 127.0.0.1; };
};

zone "k8s.lan" {
    type master;
    file "/etc/bind/db.k8s.lan";
    allow-update { key rndc-key; };
};

zone "122.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.122";
    allow-update { key rndc-key; };
};

zone "c.lan" {
    type forward;
    forward only;
    forwarders { 192.168.0.190; };
};

zone "0.168.192.in-addr.arpa" {
    type forward;
    forward only;
    forwarders { 192.168.0.190; };
};
' > /etc/bind/named.conf.local

echo '
options {
        directory "/var/cache/bind";
        dnssec-validation no;
        listen-on-v6 { any; };
};
' > /etc/bind/named.conf.options

systemctl restart named
touch /home/built
