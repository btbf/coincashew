systemdサービススクリプト改修手順


##　2. ノードを停止する。

```text
sudo systemctl stop cardano-node
```
> tmux lsを実行し「no server running on～」になるかもしくは「cnode」が無いことを確認してください

##  2. ノード起動スクリプトを再作成する。

全行をコピーしコマンドラインに送信します。

{% hint style="info" %}
ポート番号を6000から任意のポートに変更している場合は、個別に修正してください
{% endhint %}

{% tabs %}
{% tab title="リレーノード1" %}
```bash
cat > $NODE_HOME/startRelayNode1.sh << EOF 
#!/bin/bash
DIRECTORY=$NODE_HOME
PORT=6000
HOSTADDR=0.0.0.0
TOPOLOGY=\${DIRECTORY}/${NODE_CONFIG}-topology.json
DB_PATH=\${DIRECTORY}/db
SOCKET_PATH=\${DIRECTORY}/db/socket
CONFIG=\${DIRECTORY}/${NODE_CONFIG}-config.json
/usr/local/bin/cardano-node run --topology \${TOPOLOGY} --database-path \${DB_PATH} --socket-path \${SOCKET_PATH} --host-addr \${HOSTADDR} --port \${PORT} --config \${CONFIG}
EOF
```
{% endtab %}

{% tab title="ブロックプロデューサーノード" %}
```bash
cat > $NODE_HOME/startBlockProducingNode.sh << EOF 
DIRECTORY=$NODE_HOME
PORT=6000
HOSTADDR=0.0.0.0
TOPOLOGY=\${DIRECTORY}/${NODE_CONFIG}-topology.json
DB_PATH=\${DIRECTORY}/db
SOCKET_PATH=\${DIRECTORY}/db/socket
CONFIG=\${DIRECTORY}/${NODE_CONFIG}-config.json
KES=\${DIRECTORY}/kes.skey
VRF=\${DIRECTORY}/vrf.skey
CERT=\${DIRECTORY}/node.cert
cardano-node run --topology \${TOPOLOGY} --database-path \${DB_PATH} --socket-path \${SOCKET_PATH} --host-addr \${HOSTADDR} --port \${PORT} --config \${CONFIG} --shelley-kes-key \${KES} --shelley-vrf-key \${VRF} --shelley-operational-certificate \${CERT}
EOF
```
{% endtab %}
{% endtabs %}


##  1. サービスファイルを再構成する。

### 1-1. 既存のサービスファイルを無効化する
```
sudo systemctl disable cardano-node
```

### 1-2. サービスファイルを再作成する
{% tabs %}
{% tab title="リレーノード1" %}
```bash
cat > $NODE_HOME/cardano-node.service << EOF 
# The Cardano node service (part of systemd)
# file: /etc/systemd/system/cardano-node.service 

[Unit]
Description     = Cardano node service
Wants           = network-online.target
After           = network-online.target 

[Service]
User            = ${USER}
Type            = simple
WorkingDirectory= ${NODE_HOME}
ExecStart       = /bin/bash -c '${NODE_HOME}/startRelayNode1.sh'
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=2
LimitNOFILE=32768
Restart=always
RestartSec=5
SyslogIdentifier=cardano-node

[Install]
WantedBy	= multi-user.target
EOF
```
{% endtab %}

{% tab title="ブロックプロデューサーノード" %}
```bash
cat > $NODE_HOME/cardano-node.service << EOF 
# The Cardano node service (part of systemd)
# file: /etc/systemd/system/cardano-node.service 

[Unit]
Description     = Cardano node service
Wants           = network-online.target
After           = network-online.target 

[Service]
User            = ${USER}
Type            = simple
WorkingDirectory= ${NODE_HOME}
ExecStart       = /bin/bash -c '${NODE_HOME}/startBlockProducingNode.sh'
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=2
LimitNOFILE=32768
Restart=always
RestartSec=5
SyslogIdentifier=cardano-node

[Install]
WantedBy	= multi-user.target
EOF
```
{% endtab %}
{% endtabs %}

`/etc/systemd/system`にユニットファイルをコピーして、権限を付与します。

```bash
sudo cp $NODE_HOME/cardano-node.service /etc/systemd/system/cardano-node.service
```

```bash
sudo chmod 644 /etc/systemd/system/cardano-node.service
```

次のコマンドを実行して、OS起動時にサービスの自動起動を有効にします。

```text
sudo systemctl daemon-reload
sudo systemctl enable cardano-node
sudo systemctl start cardano-node
```

{% hint style="danger" %}
以下は、systemdを有効活用するためのコマンドです。  
必要に応じで実行するようにし、一連の流れで実行しないでください
{% endhint %}

\*\*\*\*⛓ **システム起動後に、ログモニターを表示するコマンド**

```text
journalctl --unit=cardano-node --follow
```
> コマンド入力に戻る場合は「Ctrl＋C」（この場合ノードは終了しません）
#### 🔄 ノードサービスを再起動するコマンド

```text
sudo systemctl reload-or-restart cardano-node
```

#### 🛑 ノードサービスを停止するコマンド

```text
sudo systemctl stop cardano-node
```

#### 🗄 ログのフィルタリング

昨日のログ
```bash
journalctl --unit=cardano-node --since=yesterday
```
> コマンド入力に戻る場合は「Ctrl＋C」（この場合ノードは終了しません）
今日のログ
```bash
journalctl --unit=cardano-node --since=today
```
> コマンド入力に戻る場合は「Ctrl＋C」（この場合ノードは終了しません）
期間指定
```bash
journalctl --unit=cardano-node --since='2020-07-29 00:00:00' --until='2020-07-29 12:00:00'
```
> コマンド入力に戻る場合は「Ctrl＋C」（この場合ノードは終了しません）
