#/bin/bash
socks_port="1080"
socks_user="laiyutao"
socks_pass="laiyutaomm"
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
iptables-save
ips=(
$(hostname -I)
)
# Xray Installation
cd /home/ubuntu
wget  https://github.com/XTLS/Xray-core/releases/download/v24.12.31/Xray-linux-64.zip
unzip Xray-linux-64.zip

chmod +x /home/ubuntu/xray
cat <<EOF > /etc/systemd/system/xray.service
[Unit]
Description=The Xray Proxy Serve
After=network-online.target
[Service]
ExecStart=/home/ubuntu/xray -c /etc/xray/serve.toml
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=always
RestartSec=15s
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable xray
# Xray Configuration
mkdir -p /etc/xray
echo -n "" > /etc/xray/serve.toml
for ((i = 0; i < ${#ips[@]}; i++)); do
cat <<EOF >> /etc/xray/serve.toml
[[inbounds]]
listen = "${ips[i]}"
port = $socks_port
protocol = "socks"
tag = "$((i+1))"
[inbounds.settings]
auth = "password"
udp = true
ip = "${ips[i]}"
[[inbounds.settings.accounts]]
user = "$socks_user"
pass = "$socks_pass"
[[routing.rules]]
type = "field"
inboundTag = "$((i+1))"
outboundTag = "$((i+1))"
[[outbounds]]
sendThrough = "${ips[i]}"
protocol = "freedom"
tag = "$((i+1))"
EOF
done
systemctl stop xray
systemctl start xray
