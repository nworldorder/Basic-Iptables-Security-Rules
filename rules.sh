#!/bin/bash

# Flush (nettoyer) les règles iptables existantes
iptables -F
iptables -X

# Définir la politique par défaut pour bloquer tout trafic
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Autoriser le trafic sur l'interface de bouclage (localhost)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Autoriser les connexions établies et liées
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Bloquer les scans de ports communs
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP       # NULL scans
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP        # XMAS scans
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP # SYN-FIN scans
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP # SYN-RST scans

# Bloquer le Ping - ICMP Echo Request
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# Limiter les nouvelles connexions TCP (contre DDoS)
iptables -A INPUT -p tcp --syn -m limit --limit 5/s --limit-burst 10 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j ACCEPT

# Détecter et bloquer les scans de ports suspects
# Ajustez ces valeurs selon vos besoins
iptables -A INPUT -p tcp -m recent --name portscan --rcheck --seconds 86400 --hitcount 20 -j DROP
iptables -A INPUT -p tcp -m recent --name portscan --set

# Limiter les connexions par nombre de requêtes /ip

iptables -A INPUT -p tcp --dport 80 -m hashlimit --hashlimit-name HTTP --hashlimit 50/minute --hashlimit-burst 120 --hashlimit-mode srcip --hashlimit-htable-expire 300000 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m hashlimit --hashlimit-name HTTPS --hashlimit 50/minute --hashlimit-burst 120 --hashlimit-mode srcip --hashlimit-htable-expire 300000 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -m hashlimit --hashlimit-name HTTPS --hashlimit 50/minute --hashlimit-burst 120 --hashlimit-mode srcip --hashlimit-htable-expire 300000 -j ACCEPT



# Fin du script
