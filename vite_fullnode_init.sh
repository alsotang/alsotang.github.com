## Before run this script, you should define $VITE_ADDR outside. Otherwise you would not receive fullnode rewards.

GVITE_VERSION=v2.2.0
VITE_DIR=$HOME/gvite
ETH0_IP=`/sbin/ifconfig eth0 | grep 'inet' | awk '{print $2}' | head -n1`

service vite stop

## download new version
mkdir -p $VITE_DIR
curl -L -o $VITE_DIR/gvite-${GVITE_VERSION}-linux.tar.gz "https://github.com/vitelabs/go-vite/releases/download/${GVITE_VERSION}/gvite-${GVITE_VERSION}-linux.tar.gz"
tar zxvf $VITE_DIR/gvite-${GVITE_VERSION}-linux.tar.gz -C $VITE_DIR

sed -i "s/\"Identity\".*/\"Identity\": \"alsofullnode-${ETH0_IP}\",/g" $VITE_DIR/gvite-${GVITE_VERSION}-linux/node_config.json
sed -i "s/\"RewardAddr\".*/\"RewardAddr\": \"$VITE_ADDR\"/g" $VITE_DIR/gvite-${GVITE_VERSION}-linux/node_config.json

## install boot script
cat << \EOF > $VITE_DIR/gvite-${GVITE_VERSION}-linux/install.sh
#!/bin/bash

set -e

CUR_DIR=`pwd`
CONF_DIR="/etc/vite"
BIN_DIR="/usr/local/vite"
LOG_DIR=$HOME/.gvite

echo "install config to "$CONF_DIR


sudo mkdir -p $CONF_DIR
sudo cp $CUR_DIR/node_config.json $CONF_DIR
ls  $CONF_DIR/node_config.json

echo "install executable file to "$BIN_DIR
sudo mkdir -p $BIN_DIR
mkdir -p $LOG_DIR
sudo cp $CUR_DIR/gvite $BIN_DIR

echo '#!/bin/bash
exec '$BIN_DIR/gvite' -pprof -config '$CONF_DIR/node_config.json' >> '$LOG_DIR/std.log' 2>&1' | sudo tee $BIN_DIR/gvited > /dev/null

sudo chmod +x $BIN_DIR/gvited

ls  $BIN_DIR/gvite
ls  $BIN_DIR/gvited

echo "config vite service boot."

echo '[Unit]
Description=GVite node service
After=network.target

[Service]
ExecStart='$BIN_DIR/gvited'
Restart=on-failure
User='`whoami`'

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/vite.service>/dev/null

sudo systemctl daemon-reload
EOF

cd $VITE_DIR/gvite-${GVITE_VERSION}-linux/ && chmod +x install.sh && ./install.sh

systemctl enable vite
service vite start

