---
description: >-
  このマニュアルでは、海外ギルドオペレーター制作のツールを組み合わせてブロックログを表示させるプログラムとなっております。  
---

{% hint style="danger" %}
🛑 **2020/12/27　まだ製作中です** 🚧
{% endhint %}

# ステークプールブロックログ導入手順

## 🎉 ∞ お知らせ

{% hint style="info" %}
このツールは海外ギルドオペレーター制作の[CNCLI By AndrewWestberg](https://github.com/AndrewWestberg/cncli)、[logmonitor by Guild Operators](https://cardano-community.github.io/guild-operators/#/Scripts/logmonitor)、[Guild LiveView](https://cardano-community.github.io/guild-operators/#/Scripts/gliveview)、[BLOCK LOG for CNTools](https://cardano-community.github.io/guild-operators/#/Scripts/cntools)を組み合わせたツールとなっております。カスタマイズするにあたり、開発者の[AHLNET(AHL)](https://twitter.com/olaahlman)にご協力頂きました。ありがとうございます。
{% endhint %}


## 🏁 0. 前提条件
### 稼働ノード
* **BPノード限定**

### 稼働要件
* ４つのサービス(プログラム)をsystemd × tmuxにて常駐させます。
* ブロックチェーン同期用DBを新しく設置します(sqlite3)
* 日本語マニュアルのフォルダ構成に合わせて作成されています。

### ハードウェア最小構成
* **オペレーティング・システム:** 64-bit Linux \(Ubuntu 20.04 LTS\)
* **プロセッサー:** 1.6GHz以上(ステークプールまたはリレーの場合は2Ghz以上)の2つ以上のコアを備えたIntelまたはAMD x86プロセッサー
* **メモリ**：8GB  
* **SSD**：50GB以上

### インストール及びダウンロードツール内容

* **CNCLI (依存プログラム含む)**
* **sqlite3**
* **logmonitor.sh**
* **block.sh**
* **cncli.sh**
* **cntools.config**
* **cntools.library**
* **env**
* **service.sh**

## 🏁 1. CNCLIをインストールする

{% hint style="info" %}
[AndrewWestberg](https://twitter.com/amw7)さんによって開発された[CNCLI](https://github.com/AndrewWestberg/cncli)はプールのブロック生成スケジュールを算出ツールを開発し、Shelley期におけるSPOに革命をもたらしました。
{% endhint %}
  
RUST環境を準備します

```bash
mkdir $HOME/.cargo && mkdir $HOME/.cargo/bin
chown -R $USER $HOME/.cargo
touch $HOME/.profile
chown $USER $HOME/.profile
```

rustupをインストールします-デフォルトのインストールを続行します（オプション1）
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

```bash
source $HOME/.cargo/env
rustup install stable
rustup default stable
rustup update
```

依存関係をインストールし、cncliをビルドします

```bash
source $HOME/.cargo/env
sudo apt-get update -y
sudo apt-get install automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf -y
cd $HOME/git
git checkout <最新タグ名>
cargo install --path . --force
cncli --version
```

{% hint style="info" %}
**以下は最新版がリリースされた場合に実行してください**  

cncli旧バージョンからの更新手順

```bash
rustup update
cd $HOME/git
git fetch --all --prune
git checkout <最新タグ名>
cargo install --path . --force
cncli --version
```
{% endhint %}

## 🏁 2. sqlite3をインストールする
```bash
sudo apt install sqlite3
sqlite3 --version
```
3.31.1以上のバージョンがインストールされたらOKです。


## 🏁 3. 各種ファイルをダウンロードする

依存関係のあるプログラムをダウンロードします。

{% hint style="info" %}
海外のギルドオペレーターによって開発された革新的な各種ツールです。
{% endhint %}

```bash
cd $NODE_HOME
mkdir scripts
wget -N https://raw.githubusercontent.com/cardano-community/guild-operators/alpha/scripts/cnode-helper-scripts/cncli.sh
wget -N https://raw.githubusercontent.com/cardano-community/guild-operators/alpha/scripts/cnode-helper-scripts/cntools.config
wget -N https://raw.githubusercontent.com/cardano-community/guild-operators/alpha/scripts/cnode-helper-scripts/cntools.library
wget -N https://raw.githubusercontent.com/cardano-community/guild-operators/alpha/scripts/cnode-helper-scripts/env
wget -N https://raw.githubusercontent.com/cardano-community/guild-operators/alpha/scripts/cnode-helper-scripts/logMonitor.sh
wget -N https://raw.githubusercontent.com/btbf/coincashew/master/guild-tools/blocks.sh
```

### パーミッションを設定する
```bash
chmod 755 cncli.sh
chmod 755 logMonitor.sh
chmod 755 blocks.sh
```

### 設定ファイルを編集する

```bash
nano env
```

ファイル内上部にある設定値を変更します。  
先頭の **#** を外し、ご自身の環境に合わせパスやファイル名、ポート番号を設定します。  
下記以外の**#**がついている項目はそのままで良い、または今回のプログラムでは使わないです。
```bash
CCLI="/usr/local/bin/cardano-cli"
CNODE_HOME=/home/<user_name>/cardano-my-node
CNODE_PORT=6000
CONFIG="${CNODE_HOME}/mainnet-config.json"
SOCKET="${CNODE_HOME}/db/socket"
TOPOLOGY="${CNODE_HOME}/mainnet-topology.json"
LOG_DIR="${CNODE_HOME}/logs"
DB_DIR="${CNODE_HOME}/db"
EKG_HOST=127.0.0.1
EKG_PORT=12788
BLOCKLOG_DIR="${CNODE_HOME}/guild-db/blocklog"
BLOCKLOG_TZ="Asia/Tokyo"
POOL_FOLDER="${CNODE_HOME}"
POOL_ID_FILENAME="stakepoolid.txt"
POOL_HOTKEY_VK_FILENAME="kes.vkey"
POOL_HOTKEY_SK_FILENAME="kes.skey"
POOL_VRF_VK_FILENAME="vrf.vkey"
POOL_VRF_SK_FILENAME="vrf.skey"
```


```bash
nano cncli.sh
```

ファイル内上部にある設定値を変更します。  
先頭の **#** を外し、ご自身の環境に合わせプールIDやファイル名を設定します。

```bash
[[ -z "${CNODE_HOME}" ]] && CNODE_HOME="/home/<user_name>/cardano-my-node"

POOL_ID=""
POOL_VRF_SKEY="${CNODE_HOME}/vrf.skey"
POOL_VRF_VKEY="${CNODE_HOME}/vrf.vkey"
```

```bash
nano blocks.sh
```
ファイル内上部にある**user_name**を変更します。
```bash
. /home/<user_name>/cardano-my-node/scripts/env
```

## 4.サービスファイル4種類を作成・登録します。

```bash
cd $NODE_HOME
mkdir service
```

{% tabs %}
{% tab title="cncli" %}
```bash
cat > $NODE_HOME/service/cnode-cncli-sync.service << EOF 
# file: /etc/systemd/system/cnode-cncli-sync.service

[Unit]
Description=Cardano Node - CNCLI sync
BindsTo=cnode-cncli-sync.service
After=cnode-cncli-sync.service

[Service]
Type=oneshot
RemainAfterExit=yes
Restart=on-failure
RestartSec=20
User=$(whoami)
WorkingDirectory=$NODE_HOME
ExecStart=/usr/bin/tmux new -d -s cncli
ExecStartPost=/usr/bin/tmux send-keys -t cncli $NODE_HOME/scripts/cncli.sh Space sync Enter
ExecStop=/usr/bin/tmux kill-session -t cncli
KillSignal=SIGINT
RestartKillSignal=SIGINT
SuccessExitStatus=143
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cnode-cncli-sync
TimeoutStopSec=5

[Install]
WantedBy=cnode-cncli-sync.service
EOF
```
{% endtab %}

{% tab title="validate" %}
```bash
cat > $NODE_HOME/service/cnode-cncli-validate.service << EOF 
# file: /etc/systemd/system/cnode-cncli-validate.service

[Unit]
Description=Cardano Node - CNCLI validate
BindsTo=cnode-cncli-validate.service
After=cnode-cncli-validate.service

[Service]
Type=oneshot
RemainAfterExit=yes
Restart=on-failure
RestartSec=20
User=$(whoami)
WorkingDirectory=$NODE_HOME
ExecStart=/usr/bin/tmux new -d -s validate
ExecStartPost=/usr/bin/tmux send-keys -t validate $NODE_HOME/scripts/cncli.sh Space validate Enter
ExecStop=/usr/bin/tmux kill-session -t validate
KillSignal=SIGINT
RestartKillSignal=SIGINT
SuccessExitStatus=143
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cnode-cncli-validate
TimeoutStopSec=5

[Install]
WantedBy=cnode-cncli-validate.service
EOF
```
{% endtab %}

{% tab title="leaderlog" %}
```bash
cat > $NODE_HOME/service/cnode-cncli-leaderlog.service << EOF 
# file: /etc/systemd/system/cnode-cncli-leaderlog.service

[Unit]
Description=Cardano Node - CNCLI Leaderlog
BindsTo=cnode-cncli-leaderlog.service
After=cnode-cncli-leaderlog.service

[Service]
Type=oneshot
RemainAfterExit=yes
Restart=on-failure
RestartSec=20
User=$(whoami)
WorkingDirectory=$NODE_HOME
ExecStart=/usr/bin/tmux new -d -s leaderlog
ExecStartPost=/usr/bin/tmux send-keys -t leaderlog $NODE_HOME/scripts/cncli.sh Space leaderlog Enter
ExecStop=/usr/bin/tmux kill-session -t leaderlog
KillSignal=SIGINT
RestartKillSignal=SIGINT
SuccessExitStatus=143
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cnode-cncli-leaderlog
TimeoutStopSec=5

[Install]
WantedBy=cnode-cncli-leaderlog.service
EOF
```
{% endtab %}

{% tab title="logmonitor" %}
```bash
cat > $NODE_HOME/service/cnode-logmonitor.service << EOF 
# file: /etc/systemd/system/cnode-logmonitor.service

[Unit]
Description=Cardano Node - CNCLI Leaderlog
BindsTo=cnode-logmonitor.service
After=cnode-logmonitor.service

[Service]
Type=oneshot
RemainAfterExit=yes
Restart=on-failure
RestartSec=20
User=$(whoami)
WorkingDirectory=$NODE_HOME
ExecStart=/usr/bin/tmux new -d -s logmonitor
ExecStartPost=/usr/bin/tmux send-keys -t logmonitor $NODE_HOME/scripts/logmonitor.sh Enter
ExecStop=/usr/bin/tmux kill-session -t logmonitor
KillSignal=SIGINT
RestartKillSignal=SIGINT
SuccessExitStatus=143
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cnode-logmonitor
TimeoutStopSec=5

[Install]
WantedBy=cnode-logmonitor.service
EOF
```
{% endtab %}
{% endtabs %}

### サービスファイルをシステムフォルダにコピーして権限を付与します。
```bash
sudo cp $NODE_HOME/service/cnode-cncli-sync.service /etc/systemd/system/cnode-cncli-sync.service
sudo cp $NODE_HOME/service/cnode-cncli-validate.service /etc/systemd/system/cnode-cncli-validate.service
sudo cp $NODE_HOME/service/cnode-cncli-leaderlog.service /etc/systemd/system/cnode-cncli-leaderlog.service
sudo cp $NODE_HOME/service/cnode-logmonitor.service /etc/systemd/system/cnode-logmonitor.service
```

```bash
sudo chmod 644 /etc/systemd/system/cnode-cncli-sync.service
sudo chmod 644 /etc/systemd/system/cnode-cncli-validate.service
sudo chmod 644 /etc/systemd/system/cnode-cncli-leaderlog.service
sudo chmod 644 /etc/systemd/system/cnode-logmonitor.service
```

### サービスファイルを有効化します

```bash
sudo systemctl daemon-reload
sudo systemctl enable cnode-cncli-sync.service
sudo systemctl enable cnode-cncli-validate.service
sudo systemctl enable cnode-cncli-leaderlog.service
sudo systemctl enable cnode-logmonitor.service
```

## 5.ブロックチェーンとDBを同期する

**cncli-sync**サービスを開始し、ログ画面を表示します
```bash
sudo systemctl start cnode-cncli-sync.service
tmux a -t cncli
```

{% hint style="info" %}
「100.00% synced」になるまで待ちます。  
元の画面に戻る場合(デタッチ)は、Ctrl+bを押した後に d を押します
{% endhint %}

## 6.過去のブロック生成実績をDBに登録します。

```bash
cd $NODE_HOME/scripts
./cncli.sh init
```

## 7.残りのサービスをスタートします
```bash
sudo systemctl start cnode-cncli-validate.service
sudo systemctl start cnode-cncli-leaderlog.service
sudo systemctl start cnode-logmonitor.service
```
### 各種ログ画面を表示する方法

```bash
tmux a -t cncli
tmux a -t validate
tmux a -t leaderlog
tmux a -t logmonitor
```
### 各種サービスをストップする方法

```bash
sudo systemctl stop cnode-cncli-sync.service
sudo systemctl stop cnode-cncli-validate.service
sudo systemctl stop cnode-cncli-leaderlog.service
sudo systemctl stop cnode-logmonitor.service
```

## 8.ブロックログを表示する

```bash
cd $NODE_HOME/scripts
./blocks.sh
```
