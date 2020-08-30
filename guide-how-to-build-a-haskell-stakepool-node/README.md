---
description: >-
  On Ubuntu/Debian, this guide will illustrate how to install and configure a
  Cardano stake pool from source code on a two node setup with 1 block producer
  node and 1 relay node.
---

# カルダノステークプール構築手順

## 🎉 ∞ お知らせ

{% hint style="info" %}
このマニュアルは「CoinCashew」制作のマニュアルを許可を経て、日本語翻訳しております。
{% endhint %}

{% hint style="success" %}
このマニュアルはCardano-nodeバージョン1.19.0を用いて作成されています。
{% endhint %}

## 🏁 0. 前提条件

### 🧙♂ ステークプールオペレータの必須スキル

カルダノステークプールを運営するには、以下のスキルを必要とします。

* カルダノノードを継続的にセットアップ、実行、維持する運用スキル
* 24時間365日ノードを維持することへの取り組み
* システム運用スキル
* サーバ管理スキル \(運用および保守\).
* 開発と運用経験 \(DevOps\)
* サーバ強化とセキュリティに関する知識
* カルダノ財団公式ステークプールセットアップコース受講

{% hint style="danger" %}
🛑 **このマニュアルを進めるには、上記のスキル要件を必要とします** 🚧
{% endhint %}

### 🎗 ステークプールハードウェア要件\(最小構成\)

* **２つのサーバー:** ブロックプロデューサーノード用1台、 リレーノード用2台
* **エアギャップオフラインマシン1台 \(コールド環境\)**
* **オペレーティング・システム:** 64-bit Linux \(i.e. Ubuntu 20.04 LTS\)
* **プロセッサー:** 2 core CPU
* **メモリー:** 4GB RAM, 4GB swap file
* **ストレージ:** 20GB SSD
* **インターネット:** 10 Mbps以上のブロードバンド回線.
* **データプラン**: 1時間あたり1GBの帯域. 1ヶ月あたり720GB.
* **電力:** 安定供給された電力
* **ADA残高:** 505 ADA以上

### 🏋♂ ステークプールハードウェア要件\(推奨構成\)

* **３つのサーバー:** ブロックプロデューサーノード用1台、 リレーノード用2台
* **エアギャップオフラインマシン1台 \(コールド環境\)**
* **オペレーティング・システム:** 64-bit Linux \(i.e. Ubuntu 20.04 LTS\)
* **プロセッサー:** 4 core or higher CPU
* **メモリー:** 8GB+ RAM
* **ストレージ:** 256GB+ SSD
* **インターネット:** 100 Mbps以上のブロードバンド回線
* **データプラン**: 無制限
* **電力:** 無停電電源装置(UPS)による電源管理
* **ADA残高:** ステークプールに対する保証金をご自身で定める分

### 🔓 ステークプールの推奨セキュリティ設定

If you need ideas on how to harden your stake pool's nodes, refer to

{% page-ref page="how-to-harden-ubuntu-server.md" %}

### 🛠 Ubuntuセットアップガイド

For instructions on installing **Ubuntu**, refer to the following:

### 🧱 ノードの再構築

If you are rebuilding or reusing an existing `cardano-node` installation, refer to [section 18.2 on how to reset the installation.](./#18-2-resetting-the-installation)

## 🏭 1. CabalとGHCをインストールします

ターミナルを起動し、以下のコマンドを入力しましょう！

まずはじめに、パッケージを更新しUbuntuを最新の状態に保ちます。

```bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install git make tmux rsync htop curl build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf -y
```

次に、Libsodiumをインストールします。

```bash
mkdir $HOME/git
cd $HOME/git
git clone https://github.com/input-output-hk/libsodium
cd libsodium
git checkout 66f017f1
./autogen.sh
./configure
make
sudo make install
```

Cabalをインストールします。

```bash
cd
wget https://downloads.haskell.org/~cabal/cabal-install-3.2.0.0/cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz
tar -xf cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz
rm cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz cabal.sig
mkdir -p $HOME/.local/bin
mv cabal $HOME/.local/bin/
```

GHCをインストールします。

```bash
wget https://downloads.haskell.org/~ghc/8.6.5/ghc-8.6.5-x86_64-deb9-linux.tar.xz
tar -xf ghc-8.6.5-x86_64-deb9-linux.tar.xz
rm ghc-8.6.5-x86_64-deb9-linux.tar.xz
cd ghc-8.6.5
./configure
sudo make install
```

環境変数を設定しパスを通します。 ノードの場所は **$NODE\_HOME** に設定されます。
最新のノード設定ファイルは**$NODE\_CONFIG** and **$NODE\_BUILD\_NUM**によって取得されます。

```bash
echo PATH="$HOME/.local/bin:$PATH" >> $HOME/.bashrc
echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc
echo export NODE_HOME=$HOME/cardano-my-node >> $HOME/.bashrc
echo export NODE_CONFIG=mainnet>> $HOME/.bashrc
echo export NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g') >> $HOME/.bashrc
source $HOME/.bashrc
```

Cabalを更新し、正しいバージョンが正常にインストールされたことを確認して下さい。

```bash
cabal update
cabal -V
ghc -V
```

{% hint style="info" %}
Cabalのライブラリーバージョンは「3.2.0.0」で GHCのバージョンは「8.6.5」であることを確認してください。
{% endhint %}

## 🏗 2. ソースコードからノードを構築する。

Gitからソースコードをダウンロードし、最新のタグに切り替えます。

```bash
cd $HOME/git
git clone https://github.com/input-output-hk/cardano-node.git
cd cardano-node
git fetch --all
git checkout tags/1.19.0
```

Cabal構成、プロジェクト設定を更新し、ビルドフォルダーをリセットします。

```bash
echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
sed -i $HOME/.cabal/config -e "s/overwrite-policy:/overwrite-policy: always/g"
rm -rf $HOME/git/cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.6.5
```

カルダノノードをビルドします）

```text
cabal build cardano-cli cardano-node
```

{% hint style="info" %}
サーバスペックによって、ビルド完了までに数分から数時間かかる場合があります。
{% endhint %}

**cardano-cli**ファイルと **cardano-node**ファイルをbinディレクトリにコピーします。

```bash
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node
```

**cardano-cli** と **cardano-node**がタグ設定したバージョンであることを確認してください。

```text
cardano-node version
cardano-cli version
```

## 📐 3. ノードを構成する

ノード構成に必要な config.json, genesis.json, 及び topology.json ファイルを取得します。

```bash
mkdir $NODE_HOME
cd $NODE_HOME
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-byron-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-topology.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-shelley-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-config.json
```

以下のコードを実行し **config.json**ファイルを更新します。

* ViewModeを「LiveView」に変更します。
* TraceBlockFetchDecisionsを「true」に変更します。

```bash
sed -i ${NODE_CONFIG}-config.json \
    -e "s/SimpleView/LiveView/g" \
    -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g"
```

環境変数を追加し、更新します。

```bash
echo export CARDANO_NODE_SOCKET_PATH="$NODE_HOME/db/socket" >> $HOME/.bashrc
source $HOME/.bashrc
```

## 🔮 4. ブロックプロデューサーノードを構築する

{% hint style="info" %}
ブロックプロデューサーノードは、ブロック生成に必要なペアキー \(cold keys, KES hot keys and VRF hot keys\)を用いて起動します。リレーノードのみに接続してください。
{% endhint %}

{% hint style="info" %}
一方で、リレーノードはキーを所有していないため、ブロック生成はできません。その代わり、他のリレーノードとの繋がりを持ち最新スロットを取得します。
{% endhint %}

![](../.gitbook/assets/producer-relay-diagram.png)

{% hint style="success" %}
このマニュアルでは、2つのサーバー上に1ノードづつ構築します。1つのノードはブロックプロデューサーノード、もう１つのノードはreleynode1という名前のリレーノードになります。
{% endhint %}

{% hint style="danger" %}
**topology.json** ファイルの構成について

* リレーノードでは、パプリックノード \(IOHKや他のリレーノード\) 及び、自身の
  ブロックプロデューサーノード情報を記述します。
* ブロックプロデューサーノードでは、自身のリレーノード情報のみ記述します。
{% endhint %}

自身のブロックプロデューサーノード上で以下のコマンドを実行します。
「addr」にはリレーノードのパプリックIPアドレスを記述します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF 
 {
    "Producers": [
      {
        "addr": "<RELAYNODE1'S PUBLIC IP ADDRESS>",
        "port": 6000,
        "valency": 1
      }
    ]
  }
EOF
```
{% endtab %}
{% endtabs %}

## 🛸 5. リレーノードを構築します。

{% hint style="warning" %}
🚧 リレーサーバを増設する場合は、**relaynodeN**として1～3の手順を同様にセットアップします。
{% endhint %}

自身のリレーノード上で以下のコマンドを実行します。
「addr」には自身のブロックプロデューサーノードのパプリックIPアドレスを記述します。
**IOHK**情報は削除しないで下さい。

{% tabs %}
{% tab title="relaynode1" %}
```bash
cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF 
 {
    "Producers": [
      {
        "addr": "<ブロックプロデューサーノード パブリックIPアドレス>",
        "port": 6000,
        "valency": 1
      },
      {
        "addr": "relays-new.cardano-mainnet.iohk.io",
        "port": 3001,
        "valency": 2
      }
    ]
  }
EOF
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
Valency tells the node how many connections to keep open. Only DNS addresses are affected. If value is 0, the address is ignored.
{% endhint %}

{% hint style="danger" %}
\*\*\*\*✨ **ポート開放について:** ブロックプロデューサーノード上で、ここで設定したポート番号を開放してください。
{% endhint %}

## 🔏 6. エアギャップオフラインマシンを構成する

{% hint style="info" %}
エアギャップオフラインマシンは「コールド環境」と呼ばれ、インターネットに接続しない独立したオフライン環境のことです。

* キーロギング攻撃、マルウエア／ウイルスベースの攻撃、その他ファイアウォールやセキュリティーの悪用から保護します。
* 有線・無線のインターネットには接続しないでください。
* ネットワーク上にあるVMマシンではありません。
* エアギャップについて更に詳しく知りたい場合は、こちらを参照下さい。
{% endhint %}

手順1～3をセットアップし、以下のパスを環境変数にセットします。
{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
echo export NODE_HOME=$HOME/cardano-my-node >> $HOME/.bashrc
source $HOME/.bashrc
mkdir -p $NODE_HOME
```
{% endtab %}
{% endtabs %}

{% hint style="danger" %}
最も安全な構成を維持するには、USBなどを利用してホット環境とコールド環境間でファイルを物理的に移動することが望ましいです。
{% endhint %}

## 🤖 7. ノード起動スクリプトを作成する。

起動スクリプトには、ディレクトリ、ポート番号、DBパス、構成ファイルパス、トポロジーファイルパスなど、カルダノノードを実行するために必要な変数が含まれています。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cat > $NODE_HOME/startBlockProducingNode.sh << EOF 
#!/bin/bash
DIRECTORY=\$NODE_HOME
PORT=6000
HOSTADDR=0.0.0.0
TOPOLOGY=\${DIRECTORY}/${NODE_CONFIG}-topology.json
DB_PATH=\${DIRECTORY}/db
SOCKET_PATH=\${DIRECTORY}/db/socket
CONFIG=\${DIRECTORY}/${NODE_CONFIG}-config.json
cardano-node run --topology \${TOPOLOGY} --database-path \${DB_PATH} --socket-path \${SOCKET_PATH} --host-addr \${HOSTADDR} --port \${PORT} --config \${CONFIG}
EOF
```
{% endtab %}

{% tab title="relaynode1" %}
```bash
cat > $NODE_HOME/startRelayNode1.sh << EOF 
#!/bin/bash
DIRECTORY=\$NODE_HOME
PORT=6000
HOSTADDR=0.0.0.0
TOPOLOGY=\${DIRECTORY}/${NODE_CONFIG}-topology.json
DB_PATH=\${DIRECTORY}/db
SOCKET_PATH=\${DIRECTORY}/db/socket
CONFIG=\${DIRECTORY}/${NODE_CONFIG}-config.json
cardano-node run --topology \${TOPOLOGY} --database-path \${DB_PATH} --socket-path \${SOCKET_PATH} --host-addr \${HOSTADDR} --port \${PORT} --config \${CONFIG}
EOF
```
{% endtab %}
{% endtabs %}

## ✅ 8. ノードを起動します。

ターミナルウィンドウを新規に立ち上げます。

起動スクリプトに実行権限を付与し、ブロックチェーンの同期を開始します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cd $NODE_HOME
chmod +x startBlockProducingNode.sh
./startBlockProducingNode.sh
```
{% endtab %}

{% tab title="relaynode1" %}
```bash
cd $NODE_HOME
chmod +x startRelayNode1.sh
./startRelayNode1.sh
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
\*\*\*\*🛑 ノードを停止するには「q」を押すか、コマンドを実行します。
 `killall cardano-node`
{% endhint %}

{% hint style="info" %}
\*\*\*\*✨ **ヒント**: 複数サーバをセットアップする場合、同期が完了したDBディレクトリを他のサーバにコピーすることにより、同期時間を節約することができます。
{% endhint %}

{% hint style="success" %}
おめでとうございます！ビジュアルグラフィックが表示され、「slot」の数値が増えて行けば同期が始まっています。
{% endhint %}

## ⚙ 9. ブロックプロデューサーキーを生成する。

ブロックプロデューサーノードでは [Shelley台帳仕様書](https://hydra.iohk.io/build/2473732/download/1/ledger-spec.pdf)で定義されている、３つのキーを生成する必要があります。

* ステークプールのコールドキー \(node.cert\)
* ステークプールのホットキー \(kes.skey\)
* ステークプールのVRFキー \(vrf.skey\)

まずは、KESペアキーを作成します。 (KES=Key Evolving Signature)

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cd $NODE_HOME
cardano-cli shelley node key-gen-KES \
    --verification-key-file kes.vkey \
    --signing-key-file kes.skey
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
KESキーは、キーを悪用するハッカーからステークプールを保護するために作成され、90日ごとに再生性する必要があります。
{% endhint %}

{% hint style="danger" %}
\*\*\*\*🔥 **コールドキーは常にエアギャップオフラインマシンで生成および保管する必要があります** コールドキーは次のパスに格納されます。 `$HOME/cold-keys.`
{% endhint %}

コールドキーを格納するディレクトリを作成します。

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```text
mkdir $HOME/cold-keys
pushd $HOME/cold-keys
```
{% endtab %}
{% endtabs %}

コールドキーのペアキーとカウンターファイルを作成します。

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley node key-gen \
    --cold-verification-key-file node.vkey \
    --cold-signing-key-file node.skey \
    --operational-certificate-issue-counter node.counter
```
{% endtab %}
{% endtabs %}

{% hint style="warning" %}
すべてのキーを別の安全なストレージデバイスにバックアップしましょう！複数のバックアップを作成することをおすすめします。
{% endhint %}

ジェネシスファイルからKES期間あたりのスロット数を決定します。

{% hint style="warning" %}
続行する前に、ノードをブロックチェーンと完全に同期する必要があります。
同期が途中の場合、最新のKES期間を取得できません。
あなたのノードが完全に同期されたことを確認するには、こちらのサイト[https://pooltool.io/](https://pooltool.io/)で自身の同期済みエポックとスロットが一致しているかをご確認ください。
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
pushd +1
slotsPerKESPeriod=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r '.slotsPerKESPeriod')
echo slotsPerKESPeriod: ${slotsPerKESPeriod}
```
{% endtab %}
{% endtabs %}



{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
slotNo=$(cardano-cli shelley query tip --mainnet | jq -r '.slotNo')
echo slotNo: ${slotNo}
```
{% endtab %}
{% endtabs %}

スロット番号をslotsPerKESPeriodで割り、kesPriodを算出します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
echo kesPeriod: ${kesPeriod}
startKesPeriod=$(( ${kesPeriod} - 1 ))
echo startKesPeriod: ${startKesPeriod}
```
{% endtab %}
{% endtabs %}

これにより、プール運用証明書を生成することができます。

**kes.vkey** をコールド環境にコピーします。

**startKesPeriod**の値を適宜変更します。

{% hint style="warning" %}
[バージョン 1.19.0](https://github.com/input-output-hk/cardano-node/issues/1742)では開始KES期間の値を(kesPeriod)-1に設定する必要があります。
{% endhint %}

{% hint style="info" %}
ステークプールオペレータは、プールを実行する権限があることを確認するための運用証明書を発行する必要があります。証明書には、オペレータの署名が含まれプールに関する情報（アドレス、キーなど）が含まれます。
{% endhint %}

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley node issue-op-cert \
    --kes-verification-key-file kes.vkey \
    --cold-signing-key-file $HOME/cold-keys/node.skey \
    --operational-certificate-issue-counter $HOME/cold-keys/node.counter \
    --kes-period <startKesPeriod> \
    --out-file node.cert
```
{% endtab %}
{% endtabs %}

**node.cert** をホット環境(ブロックプロデューサーノード)にコピーします。

VRFペアキーを作成します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley node key-gen-VRF \
    --verification-key-file vrf.vkey \
    --signing-key-file vrf.skey
```
{% endtab %}
{% endtabs %}

新しいターミナルウィンドウを開き、次のコマンドを実行してノードを停止します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
killall cardano-node
```
{% endtab %}
{% endtabs %}

起動スクリプトにKES、VRF、運用証明書のパスを追記し更新します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cat > $NODE_HOME/startBlockProducingNode.sh << EOF 
DIRECTORY=\$NODE_HOME
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

{% hint style="info" %}
ステークプールを運用するには、KES、VRFキー、および運用証明書が必要です。
{% endhint %}

ブロックプロデューサーノードを起動します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cd $NODE_HOME
./startBlockProducingNode.sh
```
{% endtab %}
{% endtabs %}

## 🔐 10. 各種アドレス用のキーを作成します。(支払い／ステーク用アドレス)

まずは、プロトコルパラメータを取得します。

{% hint style="info" %}
このエラーが出た場合は、ノードが同期を開始するまで待つか、手順３に戻り「db/socket」へのパスが追加されているか確認してください。

`cardano-cli: Network.Socket.connect: : does not exist (No such file or directory)`
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query protocol-parameters \
    --mainnet \
    --out-file params.json
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
paymentキーは支払い用アドレスに使用され、stakeキーはプール委任アドレス用の管理に使用されます。
{% endhint %}

２つのペアキーを作成するには、２通りの方法があります。最適な方法を選択してください。

{% hint style="danger" %}
🔥 **運用上のセキュリティに関する重要なアドバス:** キーの生成はエアギャップオフラインマシンで生成する必要があり、インターネット接続が無くても生成可能です。

ホット環境で必要とする手順は以下の内容です。
* 現在のスロット番号を取得する
* アドレスの残高を紹介する
* トランザクションの送信
{% endhint %}

{% tabs %}
{% tab title="Cardano-CLIを使用する方法" %}
支払い用アドレスのペアキーを作成します。: `payment.skey` & `payment.vkey`

```bash
###
### On エアギャップオフラインマシン,
###
cd $NODE_HOME
cardano-cli shelley address key-gen \
    --verification-key-file payment.vkey \
    --signing-key-file payment.skey
```

ステークアドレス用のペアキーを作成します。 `stake.skey` & `stake.vkey`

```bash
###
### On エアギャップオフラインマシン,
###
cardano-cli shelley stake-address key-gen \
    --verification-key-file stake.vkey \
    --signing-key-file stake.skey
```

ステークアドレス検証キーから、ステークアドレスファイルを作成します。 `stake.addr`

```bash
###
### On エアギャップオフラインマシン,
###
cardano-cli shelley stake-address build \
    --stake-verification-key-file stake.vkey \
    --out-file stake.addr \
    --mainnet
```

ステークアドレスに委任する支払い用アドレスを作成します。

```bash
###
### On エアギャップオフラインマシン,
###
cardano-cli shelley address build \
    --payment-verification-key-file payment.vkey \
    --stake-verification-key-file stake.vkey \
    --out-file payment.addr \
    --mainnet
```

※プール運営開始後に、上記の処理を実行するとアドレスが上書きされるので注意してください。
{% endtab %}

{% tab title="Mnemonic Method" %}
{% hint style="info" %}
このプロセスを提案してくれた [ilap](https://gist.github.com/ilap/3fd57e39520c90f084d25b0ef2b96894)のクレジット表記です。 
{% endhint %}

{% hint style="success" %}
**この方法によるメリット**: 委任をサポートするウォレット（ダイダロス、ヨロイなど）からプール報酬を確認することが可能になります。
{% endhint %}

15ワードまたは24ワード長のシェリー互換ニーモニックを、オフラインマシンのダイダロスまたはヨロイを使用して作成します。

ブロックプロデューサーノードに `cardano-wallet`をダウンロードします。

```bash
###
### On ブロックプロデューサーノード,
###
cd $NODE_HOME
wget https://hydra.iohk.io/build/3662127/download/1/cardano-wallet-shelley-2020.7.28-linux64.tar.gz
```

正規ウォレットであることを確認するために、SHA256チェックを実行します。

```bash
echo "f75e5b2b4cc5f373d6b1c1235818bcab696d86232cb2c5905b2d91b4805bae84 *cardano-wallet-shelley-2020.7.28-linux64.tar.gz" | shasum -a 256 --check
```

チェックが成功した例：

> cardano-wallet-shelley-2020.7.28-linux64.tar.gz: OK

{% hint style="danger" %}
SHA256チェックで **OK**が出た場合のみ続行してください。
{% endhint %}

USBキーまたはその他のリムーバブルメディアを介して、カルダノウォレットをエアギャップオフラインマシンに転送します。

ウォレットファイルを抽出してクリーンアップします。

```bash
###
### On エアギャップオフラインマシン,
###
tar -xvf cardano-wallet-shelley-2020.7.28-linux64.tar.gz
rm cardano-wallet-shelley-2020.7.28-linux64.tar.gz
```

スクリプトファイルを作成します。`extractPoolStakingKeys.sh`

```bash
###
### On エアギャップオフラインマシン,
###
cat > extractPoolStakingKeys.sh << HERE
#!/bin/bash 

CADDR=\${CADDR:=\$( which cardano-address )}
[[ -z "\$CADDR" ]] && ( echo "cardano-address cannot be found, exiting..." >&2 ; exit 127 )

CCLI=\${CCLI:=\$( which cardano-cli )}
[[ -z "\$CCLI" ]] && ( echo "cardano-cli cannot be found, exiting..." >&2 ; exit 127 )

OUT_DIR="\$1"
[[ -e "\$OUT_DIR"  ]] && {
           echo "The \"\$OUT_DIR\" is already exist delete and run again." >&2 
           exit 127
} || mkdir -p "\$OUT_DIR" && pushd "\$OUT_DIR" >/dev/null

shift
MNEMONIC="\$*"

# Generate the master key from mnemonics and derive the stake account keys 
# as extended private and public keys (xpub, xprv)
echo "\$MNEMONIC" |\
"\$CADDR" key from-recovery-phrase Shelley > root.prv

cat root.prv |\
"\$CADDR" key child 1852H/1815H/0H/2/0 > stake.xprv

cat root.prv |\
"\$CADDR" key child 1852H/1815H/0H/0/0 > payment.xprv

TESTNET=0
MAINNET=1
NETWORK=\$MAINNET

cat payment.xprv |\
"\$CADDR" key public | tee payment.xpub |\
"\$CADDR" address payment --network-tag \$NETWORK |\
"\$CADDR" address delegation \$(cat stake.xprv | "\$CADDR" key public | tee stake.xpub) |\
tee base.addr_candidate |\
"\$CADDR" address inspect
echo "Generated from 1852H/1815H/0H/{0,2}/0"
cat base.addr_candidate
echo

# XPrv/XPub conversion to normal private and public key, keep in mind the 
# keypars are not a valind Ed25519 signing keypairs.
TESTNET_MAGIC="--testnet-magic 42"
MAINNET_MAGIC="--mainnet"
MAGIC="\$MAINNET_MAGIC"

SESKEY=\$( cat stake.xprv | bech32 | cut -b -128 )\$( cat stake.xpub | bech32)
PESKEY=\$( cat payment.xprv | bech32 | cut -b -128 )\$( cat payment.xpub | bech32)

cat << EOF > stake.skey
{
    "type": "StakeExtendedSigningKeyShelley_ed25519_bip32",
    "description": "",
    "cborHex": "5880\$SESKEY"
}
EOF

cat << EOF > payment.skey
{
    "type": "PaymentExtendedSigningKeyShelley_ed25519_bip32",
    "description": "Payment Signing Key",
    "cborHex": "5880\$PESKEY"
}
EOF

"\$CCLI" shelley key verification-key --signing-key-file stake.skey --verification-key-file stake.evkey
"\$CCLI" shelley key verification-key --signing-key-file payment.skey --verification-key-file payment.evkey

"\$CCLI" shelley key non-extended-key --extended-verification-key-file payment.evkey --verification-key-file payment.vkey
"\$CCLI" shelley key non-extended-key --extended-verification-key-file stake.evkey --verification-key-file stake.vkey


"\$CCLI" shelley stake-address build --stake-verification-key-file stake.vkey \$MAGIC > stake.addr
"\$CCLI" shelley address build --payment-verification-key-file payment.vkey \$MAGIC > payment.addr
"\$CCLI" shelley address build \
    --payment-verification-key-file payment.vkey \
    --stake-verification-key-file stake.vkey \
    \$MAGIC > base.addr

echo "Important the base.addr and the base.addr_candidate must be the same"
diff base.addr base.addr_candidate
popd >/dev/null
HERE
```

バイナリーファイルを使用するには、アクセス県を追加してパスをエクスポートします。

```bash
###
### On エアギャップオフラインマシン,
###
chmod +x extractPoolStakingKeys.sh
export PATH="$(pwd)/cardano-wallet-shelley-2020.7.28:$PATH"
```

キーを抽出し、ニーモニックフレーズで更新します。

```bash
###
### On エアギャップオフラインマシン,
###
./extractPoolStakingKeys.sh extractedPoolKeys/ <15|24-word length mnemonic>
```

{% hint style="danger" %}
**重要**: **base.addr** と **base.addr\_candidate** は同じでなければなりません。
{% endhint %}

新しいステークキーは次のフォルダーにあります。 `extractedPoolKeys/`

`paymentとstake`で使用するペアキーを `$NODE_HOME`に移動します。

```bash
###
### On エアギャップオフラインマシン,
###
cd extractedPoolKeys/
cp stake.vkey stake.skey stake.addr payment.vkey payment.skey base.addr $NODE_HOME
cd $NODE_HOME
#Rename to base.addr file to payment.addr
mv base.addr payment.addr
```

{% hint style="info" %}
**payment.addr**はあなたのプール誓約金を保持しているアドレスになります。
{% endhint %}

ニーモニックフレーズを保護するには、履歴とファイルを削除します。

```bash
###
### On エアギャップオフラインマシン,
###
history -c && history -w
rm -rf $NODE_HOME/cardano-wallet-shelley-2020.7.28
```

すべてのターミナルウィンドウを閉じ、履歴のない新しいウィンドウを開きます。

{% hint style="success" %}
いかがでしょうか？ウォレットでプール報酬を確認することが可能になりました。
{% endhint %}
{% endtab %}
{% endtabs %}

次のステップは、あなたの支払いアドレスに送金する手順です。

**payment.addr** をホット環境（ブロックプロデューサーノード）にコピーします。

{% tabs %}
{% tab title="Mainnet" %}
以下のウォレットアドレスから送金が可能です。

* ダイダロス / ヨロイウォレット
* もしITNに参加している場合は、キーを変換できます。

次のコードを実行し。支払いアドレスを表示させます。

```bash
cat payment.addr
```
{% endtab %}

{% tab title="メインネット候補版" %}
以下のウォレットアドレスから送金が可能です。

* [テストネット用口座](https://testnets.cardano.org/en/shelley/tools/faucet/)
* バイロンメインネット資金 
* INTに参加している場合は、キーを変換できます。 

次のコードを実行し。支払いアドレスを表示させます。

```text
cat payment.addr
```
{% endtab %}

{% tab title="Shelley テストネット" %}
[テストネット用口座](https://testnets.cardano.org/en/shelley/tools/faucet/)にあなたの支払い用アドレスをリクエストします。

次のコードを実行し。支払いアドレスを表示させます。

```text
cat payment.addr
```

このアドレスを上記ページのリクエスト欄に貼り付けます。

{% hint style="info" %}
シェリーテストネット用口座は24時間ごとに100,000fADAを提供します。
{% endhint %}
{% endtab %}
{% endtabs %}

支払い用アドレスに送金後、残高を確認してください。

{% hint style="danger" %}
続行する前に、ノードをブロックチェーンと完全に同期させる必要があります。完全に同期されていない場合は、残高が表示されません。
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query utxo \
    --address $(cat payment.addr) \
    --mainnet
```
{% endtab %}
{% endtabs %}

次のように表示されます。

```text
                           TxHash                                 TxIx        Lovelace
----------------------------------------------------------------------------------------
100322a39d02c2ead....                                              0        1000000000
```

## 👩💻 11. ステークアドレスを登録します。

`stake.vkey`を使用して、`stake.cert`証明証を作成します。 

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```text
cardano-cli shelley stake-address registration-certificate \
    --stake-verification-key-file stake.vkey \
    --out-file stake.cert
```
{% endtab %}
{% endtabs %}

ttlパラメータを設定するには、最新のスロット番号を取得する必要があります。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
currentSlot=$(cardano-cli shelley query tip --mainnet | jq -r '.slotNo')
echo Current Slot: $currentSlot
```
{% endtab %}
{% endtabs %}

残高とUTXOを出力します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query utxo \
    --address $(cat payment.addr) \
    --mainnet > fullUtxo.out

tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

cat balance.out

tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo TxHash: ${in_addr}#${idx}
    echo ADA: ${utxo_balance}
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < balance.out
txcnt=$(cat balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}
```
{% endtab %}
{% endtabs %}

keyDepositの値を出力します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
keyDeposit=$(cat $NODE_HOME/params.json | jq -r '.keyDeposit')
echo keyDeposit: $keyDeposit
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
ステークアドレス証明書の登録には2,000,000lovelace(2ADA)が必要です。
{% endhint %}

build-rawトランザクションコマンドを実行します。

{% hint style="info" %}
**ttl**の値は、現在のスロット番号よりも大きくなければなりません。この例では現在のスロット番号＋10000を使用します。
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+0 \
    --ttl $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --out-file tx.tmp \
    --certificate stake.cert
```
{% endtab %}
{% endtabs %}

現在の最低手数料を計算します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
fee=$(cardano-cli shelley transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
残高が手数料+keyDepositのコストよりも大きいことを確認してください。そうしないと機能しません。
{% endhint %}

計算結果を出力します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
txOut=$((${total_balance}-${keyDeposit}-${fee}))
echo Change Output: ${txOut}
```
{% endtab %}
{% endtabs %}

ステークアドレスを登録するトランザクションファイルを作成します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${txOut} \
    --ttl $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file stake.cert \
    --out-file tx.raw
```
{% endtab %}
{% endtabs %}

**tx.raw**をコールド環境にコピーします。

paymentとstakeの秘密鍵でトランザクションファイルに署名します。

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file payment.skey \
    --signing-key-file stake.skey \
    --mainnet \
    --out-file tx.signed
```
{% endtab %}
{% endtabs %}

**tx.signed**をブロックプロデューサーノードにコピーします。

署名されたトランザクションを送信します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction submit \
    --tx-file tx.signed \
    --mainnet
```
{% endtab %}
{% endtabs %}

## 📄 12. ステークプールを登録します。

JSONファイルを使用してプールのメタデータを作成します。

{% hint style="warning" %}
**ticker**名の長さは3～5文字にする必要があります。文字はA-Zと0-9のみで構成する必要があります。
{% endhint %}

{% hint style="warning" %}
**description**の長さは255文字以内となります。
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cat > poolMetaData.json << EOF
{
"name": "MyPoolName",
"description": "My pool description",
"ticker": "MPN",
"homepage": "https://myadapoolnamerocks.com"
}
EOF
```
{% endtab %}
{% endtabs %}

メタデータファイルのハッシュ値を計算します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley stake-pool metadata-hash --pool-metadata-file poolMetaData.json > poolMetaDataHash.txt
```
{% endtab %}
{% endtabs %}

**poolMetaData.json**をあなたの公開用WEBサーバへアップロードしてください。


<!--Refer to the following quick guide if you need help hosting your metadata on github.com

{% page-ref page="how-to-upload-poolmetadata.json-to-github.md" %}-->


最小プールコストを出力します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
minPoolCost=$(cat $NODE_HOME/params.json | jq -r .minPoolCost)
echo minPoolCost: ${minPoolCost}
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
minPoolCostは 340000000 lovelace または 340 ADAです。
{% endhint %}

ステークプールの登録証明書を作成します。 **metadata URL**と**リレーノード情報**を追記し構成します。リレーノード構成にはDNSベースまたはIPベースのどちらかを選択できます。

{% hint style="info" %}
ノード管理を簡単にするために、DNSベースのリレー設定をお勧めします。もしリレーサーバを変更する場合IPアドレスが変わるため、その都度登録証明書トランザクションを再送する必要があります。DNSベースで登録しておけば、IPアドレスが変更になってもお使いのドメイン管理画面にてIPアドレスを変更するだけで完了します。
{% endhint %}

{% hint style="info" %}
#### \*\*\*\*✨ **複数のリレーノードを構成する記述方法**


**DNSレコードに1つのエントリーの場合**

```bash
    --single-host-pool-relay relaynode1.myadapoolnamerocks.com\
    --pool-relay-port 6000 \
    --single-host-pool-relay relaynode2.myadapoolnamerocks.com\
    --pool-relay-port 6000 \
```

**ラウンドロビンDNSベース** [**SRV DNS record**](https://support.dnsimple.com/articles/srv-record/)の場合

```bash
    --multi-host-pool-relay relayNodes.myadapoolnamerocks.com\
    --pool-relay-port 6000 \
```

**IPアドレス, 1ノード1IPアドレスの場合**

```bash
    --pool-relay-port 6000 \
    --pool-relay-ipv4 <your first relay node public IP address> \
    --pool-relay-port 6000 \
    --pool-relay-ipv4 <your second relay node public IP address> \
```
{% endhint %}

{% hint style="warning" %}
**metadata-url**は64文字以内とし、あなたの環境に合わせて修正してください。
{% endhint %}

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley stake-pool registration-certificate \
    --cold-verification-key-file $HOME/cold-keys/node.vkey \
    --vrf-verification-key-file vrf.vkey \
    --pool-pledge 100000000 \
    --pool-cost 345000000 \
    --pool-margin 0.15 \
    --pool-reward-account-verification-key-file stake.vkey \
    --pool-owner-stake-verification-key-file stake.vkey \
    --mainnet \
    --single-host-pool-relay <dns based relay, example ~ relaynode1.myadapoolnamerocks.com> \
    --pool-relay-port 6000 \
    --metadata-url <poolMetaData.jsonをアップロードしたURLを記述> \
    --metadata-hash $(cat poolMetaDataHash.txt) \
    --out-file pool.cert
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
ここでは345ADAの固定費と15%のプールマージン、100ADAの誓約費を設定しています。
ご自身の設定値に変更してください。
{% endhint %}


ステークプールにステークを誓約するファイルを作成します。

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley stake-address delegation-certificate \
    --stake-verification-key-file stake.vkey \
    --cold-verification-key-file $HOME/cold-keys/node.vkey \
    --out-file deleg.cert
```
{% endtab %}
{% endtabs %}

**pool.cert**と**deleg.cert**をブロックプロデューサーノードにコピーします。

<!--{% hint style="info" %}
This operation creates a delegation certificate which delegates funds from all stake addresses associated with key `stake.vkey` to the pool belonging to cold key `node.vkey`
{% endhint %}-->

{% hint style="info" %}
自分のプールに資金を預けることを**Pledge(誓約)**と呼ばれます

* あなたのペイメント残高はPledge額よりも大きい必要があります。
* 誓約金を宣言しても、実際にはどこにも移動されていません。payment.addrに残ったままです。
* 誓約を行わないと、ブロック生成の機会を逃し委任者は報酬を得ることができません。
* あなたの誓約金はブロックされません。いつでも自由に取り出せます。
{% endhint %}

**ttl**パラメータを設定するには、最新のスロット番号を取得する必要があります。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
currentSlot=$(cardano-cli shelley query tip --mainnet | jq -r '.slotNo')
echo Current Slot: $currentSlot
```
{% endtab %}
{% endtabs %}

残高と**UTXOs**を出力します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query utxo \
    --address $(cat payment.addr) \
    --mainnet > fullUtxo.out

tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

cat balance.out

tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo TxHash: ${in_addr}#${idx}
    echo ADA: ${utxo_balance}
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < balance.out
txcnt=$(cat balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}
```
{% endtab %}
{% endtabs %}

poolDepositを出力します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
poolDeposit=$(cat $NODE_HOME/params.json | jq -r '.poolDeposit')
echo poolDeposit: $poolDeposit
```
{% endtab %}
{% endtabs %}

build-rawトランザクションコマンドを実行します。

{% hint style="info" %}
**ttl**の値は、現在のスロット番号よりも大きくなければなりません。この例では、現在のスロット+10000を使用します。
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+$(( ${total_balance} - ${poolDeposit}))  \
    --ttl $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file pool.cert \
    --certificate-file deleg.cert \
    --out-file tx.tmp
```
{% endtab %}
{% endtabs %}

最低手数料を計算します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
fee=$(cardano-cli shelley transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 3 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
残高が手数料コスト+minPoolCostよりも大きいことを確認してください。小さい場合は機能しません。
{% endhint %}

計算結果を出力します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
txOut=$((${total_balance}-${poolDeposit}-${fee}))
echo txOut: ${txOut}
```
{% endtab %}
{% endtabs %}

トランザクションファイルを作成します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${txOut} \
    --ttl $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file pool.cert \
    --certificate-file deleg.cert \
    --out-file tx.raw
```
{% endtab %}
{% endtabs %}

**tx.raw**をコールド環境へコピーします。

トランザクションに署名します。

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file payment.skey \
    --signing-key-file $HOME/cold-keys/node.skey \
    --signing-key-file stake.skey \
    --mainnet \
    --out-file tx.signed
```
{% endtab %}
{% endtabs %}

**tx.signed**ブロックプロデューサーノードにコピーします。

トランザクションを送信します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction submit \
    --tx-file tx.signed \
    --mainnet
```
{% endtab %}
{% endtabs %}

## 🐣 13. ステークプールが機能しているか確認します。

ステークプールIDは以下の用に出力できます。

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley stake-pool id --verification-key-file $HOME/cold-keys/node.vkey > stakepoolid.txt
cat stakepoolid.txt
```
{% endtab %}
{% endtabs %}

**stakepoolid.txt**をブロックプロデューサーノードへコピーします。

このファイルを用いて、自分のステークプールがブロックチェーンに登録されているか確認します。

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query ledger-state --mainnet | grep publicKey | grep $(cat stakepoolid.txt)
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
文字列による戻り値が返ってきた場合は、正常に登録されています 👏
{% endhint %}

あなたのステークプールを次のサイトで確認することが出来ます。 [https://pooltool.io/](https://pooltool.io/)

## ⚙ 14. トポロジーファイルを構成する。

{% hint style="info" %}
Shelley has been launched without peer-to-peer \(p2p\) node discovery so that means we will need to manually add trusted nodes in order to configure our topology. This is a **critical step** as skipping this step will result in your minted blocks being orphaned by the rest of the network.
{% endhint %}

There are two ways to configure your topology files.

* **topologyUpdate.sh method** is automated and works after 4 hours. 
* **Pooltool.io method** gives you control over who your nodes connect to.

{% tabs %}
{% tab title="topologyUpdater.sh Method" %}
### 🚀 Publishing your Relay Node with topologyUpdater.sh

{% hint style="info" %}
Credits to [GROWPOOL](https://twitter.com/PoolGrow) for this addition and credits to [CNTOOLS Guild OPS](https://cardano-community.github.io/guild-operators/Scripts/topologyupdater.html) on creating this process.
{% endhint %}

Create the `topologyUpdater.sh` script which publishes your node information to a topology fetch list.

```bash
###
### On relaynode1
###
cat > $NODE_HOME/topologyUpdater.sh << EOF
#!/bin/bash
# shellcheck disable=SC2086,SC2034

USERNAME=$(whoami)
CNODE_PORT=6000 # must match your relay node port as set in the startup command
CNODE_HOSTNAME="CHANGE ME"  # optional. must resolve to the IP you are requesting from
CNODE_BIN="/usr/local/bin"
CNODE_HOME=$NODE_HOME
CNODE_LOG_DIR="\${CNODE_HOME}/logs"
GENESIS_JSON="\${CNODE_HOME}/${NODE_CONFIG}-shelley-genesis.json"
NETWORKID=\$(jq -r .networkId \$GENESIS_JSON)
CNODE_VALENCY=1   # optional for multi-IP hostnames
NWMAGIC=\$(jq -r .networkMagic < \$GENESIS_JSON)
[[ "\${NETWORKID}" = "Mainnet" ]] && HASH_IDENTIFIER="--mainnet" || HASH_IDENTIFIER="--testnet-magic \${NWMAGIC}"
[[ "\${NWMAGIC}" = "764824073" ]] && NETWORK_IDENTIFIER="--mainnet" || NETWORK_IDENTIFIER="--testnet-magic \${NWMAGIC}"

export PATH="\${CNODE_BIN}:\${PATH}"
export CARDANO_NODE_SOCKET_PATH="\${CNODE_HOME}/db/socket"

blockNo=\$(cardano-cli shelley query tip \${NETWORK_IDENTIFIER} | jq -r .blockNo )

# Note:
# if you run your node in IPv4/IPv6 dual stack network configuration and want announced the
# IPv4 address only please add the -4 parameter to the curl command below  (curl -4 -s ...)
if [ "\${CNODE_HOSTNAME}" != "CHANGE ME" ]; then
  T_HOSTNAME="&hostname=\${CNODE_HOSTNAME}"
else
  T_HOSTNAME=''
fi

if [ ! -d \${CNODE_LOG_DIR} ]; then
  mkdir -p \${CNODE_LOG_DIR};
fi

curl -s "https://api.clio.one/htopology/v1/?port=\${CNODE_PORT}&blockNo=\${blockNo}&valency=\${CNODE_VALENCY}&magic=\${NWMAGIC}\${T_HOSTNAME}" | tee -a \$CNODE_LOG_DIR/topologyUpdater_lastresult.json
EOF
```

Add permissions and run the updater script.

```bash
###
### On relaynode1
###
cd $NODE_HOME
chmod +x topologyUpdater.sh
./topologyUpdater.sh
```

When the `topologyUpdater.sh` runs successfully, you will see

> `{ "resultcode": "201", "datetime":"2020-07-28 01:23:45", "clientIp": "1.2.3.4", "iptype": 4, "msg": "nice to meet you" }`

{% hint style="info" %}
Every time the script runs and updates your IP, a log is created in **`$NODE_HOME/logs`**
{% endhint %}

Add a crontab job to automatically run `topologyUpdater.sh` every hour on the 22nd minute. You can change the 22 value to your own preference.

```bash
###
### On relaynode1
###
cat > $NODE_HOME/crontab-fragment.txt << EOF
22 * * * * ${NODE_HOME}/topologyUpdater.sh
EOF
crontab -l | cat - crontab-fragment.txt >crontab.txt && crontab crontab.txt
rm crontab-fragment.txt
```

{% hint style="success" %}
After four hours and four updates, your node IP will be registered in the topology fetch list.
{% endhint %}

### 🤹♀ Update your relay node topology files

{% hint style="danger" %}
Complete this section after **four hours** when your relay node IP is properly registered.
{% endhint %}

Create `relay-topology_pull.sh` script which fetches your relay node buddies and updates your topology file. **Update with your block producer's public IP address.**

```bash
###
### On relaynode1
###
cat > $NODE_HOME/relay-topology_pull.sh << EOF
#!/bin/bash
BLOCKPRODUCING_IP=<BLOCK PRODUCERS PUBLIC IP ADDRESS>
BLOCKPRODUCING_PORT=6000
curl -s -o $NODE_HOME/${NODE_CONFIG}-topology.json "https://api.clio.one/htopology/v1/fetch/?max=20&customPeers=\${BLOCKPRODUCING_IP}:\${BLOCKPRODUCING_PORT}:2|relays-new.cardano-mainnet.iohk.io:3001:2"
EOF
```

Add permissions and pull new topology files.

```bash
###
### On relaynode1
###
chmod +x relay-topology_pull.sh
./relay-topology_pull.sh
```

The new topology takes after after restarting your stake pool.

```bash
###
### On relaynode1
###
killall cardano-node
./startRelayNode1.sh
```

{% hint style="warning" %}
Don't forget to restart your relay nodes after every time you fetch the topology!
{% endhint %}
{% endtab %}

{% tab title="Pooltool.io Method" %}
1. Visit [https://pooltool.io/](https://pooltool.io/)
2. Create an account and login
3. Search for your stakepool id
4. Click ➡ **Pool Details** &gt; **Manage** &gt; **CLAIM THIS POOL**
5. Fill in your pool name and pool URL if you have one.
6. Fill in your **Private Nodes** and **Your Relays** as follows.

![](../.gitbook/assets/ada-relay-setup-mainnet.png)

{% hint style="info" %}
You can find your public IP with [https://www.whatismyip.com/](https://www.whatismyip.com/) or

```text
curl http://ifconfig.me/ip
```
{% endhint %}

Add requests for nodes or "buddies" to each of your relay nodes. Make sure you include the IOHK node and your private nodes.

IOHK's node address is:

```text
relays-new.cardano-mainnet.iohk.io
```

IOHK's node port is:

```text
3001
```

For example, on relaynode1's buddies you should add **requests** for

* your private BlockProducingNode
* IOHK's node
* and any other buddy/friendly nodes your can find or know

{% hint style="info" %}
A relay node connection is not established until there is a request and an approval.
{% endhint %}

For **relaynode1**, create a get\_buddies.sh script to update your topology.json file.

```bash
###
### On relaynode1
###
cat > $NODE_HOME/get_buddies.sh << EOF 
#!/usr/bin/env bash

# YOU CAN PASS THESE STRINGS AS ENVIRONMENTAL VARIABLES, OR EDIT THEM IN THE SCRIPT HERE
if [ -z "\$PT_MY_POOL_ID" ]; then
## CHANGE THESE TO SUIT YOUR POOL TO YOUR POOL ID AS ON THE EXPLORER
PT_MY_POOL_ID="XXXXXXXX"
fi

if [ -z "\$PT_MY_API_KEY" ]; then
## GET THIS FROM YOUR ACCOUNT PROFILE PAGE ON POOLTOOL WEBSITE
PT_MY_API_KEY="XXXXXXXX"
fi

if [ -z "\$PT_MY_NODE_ID" ]; then
## GET THIS FROM YOUR POOL MANAGE TAB ON POOLTOOL WEBSITE
PT_MY_NODE_ID="XXXXXXXX"
fi

if [ -z "\$PT_TOPOLOGY_FILE" ]; then
## SET THIS TO THE LOCATION OF YOUR TOPOLOGY FILE THAT YOUR NODE USES
PT_TOPOLOGY_FILE="$NODE_HOME/${NODE_CONFIG}-topology.json"
fi

JSON="\$(jq -n --compact-output --arg MY_API_KEY "\$PT_MY_API_KEY" --arg MY_POOL_ID "\$PT_MY_POOL_ID" --arg MY_NODE_ID "\$PT_MY_NODE_ID" '{apiKey: \$MY_API_KEY, nodeId: \$MY_NODE_ID, poolId: \$MY_POOL_ID}')"
echo "Packet Sent: \$JSON"
RESPONSE="\$(curl -s -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "\$JSON" "https://api.pooltool.io/v0/getbuddies")"
SUCCESS="\$(echo \$RESPONSE | jq '.success')"
if [ \$SUCCESS ]; then
  echo "Success"
  echo \$RESPONSE | jq '. | {Producers: .message}' > \$PT_TOPOLOGY_FILE
  echo "Topology saved to \$PT_TOPOLOGY_FILE.  Note topology will only take effect next time you restart your node"
else
  echo "Failure "
  echo \$RESPONSE | jq '.message'
fi
EOF
```

For each of your relay nodes, update the following variables from pooltool.io into your get\_buddies.sh file

* PT\_MY\_POOL\_ID 
* PT\_MY\_API\_KEY 
* PT\_MY\_NODE\_ID

Update your get\_buddies.sh scripts with this information.

{% hint style="info" %}
Use **nano** to edit your files.

`nano $NODE_HOME/relaynode1/get_buddies.sh`
{% endhint %}

Add execute permissions to these scripts. Run the scripts to update your topology files.

```bash
###
### On relaynode1
###
cd $NODE_HOME
chmod +x get_buddies.sh
./get_buddies.sh
```

Stop and then restart your stakepool in order for the new topology settings to take effect.

```bash
###
### On relaynode1
###
killall cardano-node
./startRelayNode1.sh
```

{% hint style="info" %}
As your REQUESTS are approved, you must re-run the get\_buddies.sh script to pull the latest topology data. Restart your relay nodes afterwards.
{% endhint %}
{% endtab %}
{% endtabs %}

{% hint style="danger" %}
\*\*\*\*🔥 **Critical step:** In order to be a functional stake pool ready to mint blocks, you must see the **TXs processed** number increasing. If not, review your topology file and ensure your relay buddies are well connected and ideally, minted some blocks.
{% endhint %}

![](../.gitbook/assets/ada-tx-processed.png)

{% hint style="danger" %}
\*\*\*\*🛑 **Critical Reminde**r: The only stake pool **keys** and **certs** that are required to run a stake pool are those required by the block producer. Namely, the following three files.

```bash
###
### On ブロックプロデューサーノード
###
KES=\${DIRECTORY}/kes.skey
VRF=\${DIRECTORY}/vrf.skey
CERT=\${DIRECTORY}/node.cert
```

**All other keys must remain offline in your air-gapped offline cold environment.**
{% endhint %}

{% hint style="success" %}
Congratulations! Your stake pool is registered and ready to produce blocks.
{% endhint %}

## 🎇 15. Checking Stake pool Rewards

After the epoch is over and assuming you successfully minted blocks, check with this:

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query stake-address-info \
 --address $(cat stake.addr) \
 --mainnet
```
{% endtab %}
{% endtabs %}

## 🔮 16. Setup Prometheus and Grafana Dashboard

Prometheus is a monitoring platform that collects metrics from monitored targets by scraping metrics HTTP endpoints on these targets. [Official documentation is available here.](https://prometheus.io/docs/introduction/overview/) Grafana is a dashboard used to visualize the collected data.

### 🐣 16.1 Installation

Install prometheus and prometheus node exporter.

{% tabs %}
{% tab title="relaynode1" %}
```text
sudo apt-get install -y prometheus prometheus-node-exporter
```
{% endtab %}

{% tab title="ブロックプロデューサーノード" %}
```bash
sudo apt-get install -y prometheus-node-exporter
```
{% endtab %}
{% endtabs %}

Install grafana.

{% tabs %}
{% tab title="relaynode1" %}
```bash
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
```
{% endtab %}
{% endtabs %}

{% tabs %}
{% tab title="relaynode1" %}
```bash
echo "deb https://packages.grafana.com/oss/deb stable main" > grafana.list
sudo mv grafana.list /etc/apt/sources.list.d/grafana.list
```
{% endtab %}
{% endtabs %}

{% tabs %}
{% tab title="relaynode1" %}
```bash
sudo apt-get update && sudo apt-get install -y grafana
```
{% endtab %}
{% endtabs %}

Enable services so they start automatically.

{% tabs %}
{% tab title="relaynode1" %}
```bash
sudo systemctl enable grafana-server.service
sudo systemctl enable prometheus.service
sudo systemctl enable prometheus-node-exporter.service
```
{% endtab %}

{% tab title="ブロックプロデューサーノード" %}
```text
sudo systemctl enable prometheus-node-exporter.service
```
{% endtab %}
{% endtabs %}

Update **prometheus.yml** located in `/etc/prometheus/prometheus.yml`

Change the **&lt;block producer public ip address&gt;** in the following command.

{% tabs %}
{% tab title="relaynode1" %}
```bash
cat > prometheus.yml << EOF
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label job=<job_name> to any timeseries scraped from this config.
  - job_name: 'prometheus'

    static_configs:
      - targets: ['localhost:9100']
      - targets: ['<block producer public ip address>:12700']
        labels:
          alias: 'block-producing-node'
          type:  'cardano-node'
      - targets: ['localhost:12701']
        labels:
          alias: 'relaynode1'
          type:  'cardano-node'
EOF
sudo mv prometheus.yml /etc/prometheus/prometheus.yml
```
{% endtab %}
{% endtabs %}

Finally, restart the services.

{% tabs %}
{% tab title="relaynode1" %}
```text
sudo systemctl restart grafana-server.service
sudo systemctl restart prometheus.service
sudo systemctl restart prometheus-node-exporter.service
```
{% endtab %}
{% endtabs %}

Verify that the services are running properly:

{% tabs %}
{% tab title="relaynode1" %}
```text
sudo systemctl status grafana-server.service prometheus.service prometheus-node-exporter.service
```
{% endtab %}
{% endtabs %}

Update `${NODE_CONFIG}-config.json` config files with new `hasEKG` and `hasPrometheus` ports.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cd $NODE_HOME
sed -i ${NODE_CONFIG}-config.json -e "s/    12798/    12700/g" -e "s/hasEKG\": 12788/hasEKG\": 12600/g"
```
{% endtab %}

{% tab title="relaynode1" %}
```bash
cd $NODE_HOME
sed -i ${NODE_CONFIG}-config.json -e "s/    12798/    12701/g" -e "s/hasEKG\": 12788/hasEKG\": 12601/g"
```
{% endtab %}
{% endtabs %}

Stop and restart your stake pool.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cd $NODE_HOME
killall cardano-node
./startBlockProducingNode.sh
```
{% endtab %}

{% tab title="relaynode1" %}
```bash
cd $NODE_HOME
killall cardano-node
./startRelayNode1.sh
```
{% endtab %}
{% endtabs %}

### 📶 16.2 Setting up Grafana Dashboards

1. On relaynode1, open [http://localhost:3000](http://localhost:3000) or [http://&lt;your](http://<your) relaynode1 ip address&gt;:3000 in your local browser. You may need to open up port 3000 in your router and/or firewall.
2. Login with **admin** / **admin**
3. Change password
4. Click the **configuration gear** icon, then **Add data Source**
5. Select **Prometheus**
6. Set **Name** to **"prometheus**" . ✨ Lower case matters.
7. Set **URL** to [http://localhost:9090](http://localhost:9090)
8. Click **Save & Test**
9. Click **Create +** icon &gt; **Import**
10. Add dashboard by importing id: **11074**
11. Click the **Load** button.
12. Set **Prometheus** data source as "**prometheus**"
13. Click the **Import** button.

{% hint style="info" %}
Grafana [dashboard ID 11074](https://grafana.com/grafana/dashboards/11074) is an excellent overall systems health visualizer.
{% endhint %}

![Grafana system health dashboard](../.gitbook/assets/grafana.png)

Import a **Cardano-Node** dashboard

1. Click **Create +** icon &gt; **Import**
2. Add dashboard by **importing via panel json. Copy the json from below.**
3. Click the Import button.

```bash
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 1,
  "links": [],
  "panels": [
    {
      "datasource": "prometheus",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "decimals": 2,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "purple",
                "value": null
              }
            ]
          },
          "unit": "d"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 6,
        "x": 0,
        "y": 0
      },
      "id": 18,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "(cardano_node_Forge_metrics_remainingKESPeriods_int * 129600 / (60 * 60 * 24))",
          "instant": true,
          "interval": "",
          "legendFormat": "Days till renew",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Key evolution renew left",
      "type": "stat"
    },
    {
      "datasource": "prometheus",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": null
              },
              {
                "color": "#EAB839",
                "value": 12
              },
              {
                "color": "green",
                "value": 24
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 5,
        "x": 6,
        "y": 0
      },
      "id": 12,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "cardano_node_Forge_metrics_remainingKESPeriods_int",
          "instant": true,
          "interval": "",
          "legendFormat": "KES Remaining",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "KES remaining",
      "type": "stat"
    },
    {
      "datasource": "prometheus",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "yellow",
                "value": 460
              },
              {
                "color": "red",
                "value": 500
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 6,
        "x": 11,
        "y": 0
      },
      "id": 2,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "cardano_node_Forge_metrics_operationalCertificateExpiryKESPeriod_int",
          "format": "time_series",
          "instant": true,
          "interval": "",
          "legendFormat": "KES Expiry",
          "refId": "A"
        },
        {
          "expr": "cardano_node_Forge_metrics_currentKESPeriod_int",
          "instant": true,
          "interval": "",
          "legendFormat": "KES current",
          "refId": "B"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "KES Perioden",
      "type": "stat"
    },
    {
      "datasource": "prometheus",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 6,
        "x": 0,
        "y": 5
      },
      "id": 10,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "cardano_node_ChainDB_metrics_slotNum_int",
          "instant": true,
          "interval": "",
          "legendFormat": "SlotNo",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Slot",
      "type": "stat"
    },
    {
      "datasource": "prometheus",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 5,
        "x": 6,
        "y": 5
      },
      "id": 8,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "cardano_node_ChainDB_metrics_epoch_int",
          "format": "time_series",
          "instant": true,
          "interval": "",
          "legendFormat": "Epoch",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Epoch",
      "type": "stat"
    },
    {
      "datasource": "prometheus",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 6,
        "x": 11,
        "y": 5
      },
      "id": 16,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "mean"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "cardano_node_ChainDB_metrics_blockNum_int",
          "instant": true,
          "interval": "",
          "legendFormat": "Block Height",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Block Height",
      "type": "stat"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 9,
        "w": 9,
        "x": 0,
        "y": 10
      },
      "hiddenSeries": false,
      "id": 6,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pluginVersion": "7.0.3",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "cardano_node_ChainDB_metrics_slotInEpoch_int",
          "interval": "",
          "legendFormat": "Slot in Epoch",
          "refId": "B"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Slot in Epoch",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 4,
      "gridPos": {
        "h": 9,
        "w": 8,
        "x": 9,
        "y": 10
      },
      "hiddenSeries": false,
      "id": 20,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": false,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pluginVersion": "7.0.3",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "cardano_node_Forge_metrics_nodeIsLeader_int",
          "interval": "",
          "legendFormat": "Node is leader",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Node is Block Leader",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "decimals": null,
          "format": "none",
          "label": "Slot",
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 9,
        "x": 0,
        "y": 19
      },
      "hiddenSeries": false,
      "id": 14,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": false,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "cardano_node_metrics_mempoolBytes_int / 1024",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "Memory KB",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Memory Pool",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "KBs",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "datasource": "prometheus",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "decimals": 2,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          },
          "unit": "dthms"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 6,
        "w": 8,
        "x": 9,
        "y": 19
      },
      "id": 4,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "last"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "cardano_node_metrics_upTime_ns / (1000000000)",
          "format": "time_series",
          "instant": true,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "Server Uptime",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Block-Producer Uptime",
      "type": "stat"
    }
  ],
  "refresh": "5s",
  "schemaVersion": 25,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-24h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "",
  "title": "Cardano Node",
  "uid": "bTDYKJZMk",
  "version": 1
}
```

![Cardano-node dashboard](../.gitbook/assets/cardano-node-grafana.png)

{% hint style="success" %}
Congratulations. You're basically done. More great operational and maintenance tips below.
{% endhint %}

## 👏 17. Thank yous, Telegram and reference material

### 😊 17.1 Donation Tip Jar

{% hint style="info" %}
Did you find our guide useful? Let us know with a tip and we'll keep updating it. Bonus points if you use [section 18.9's instructions](./#18-9-send-a-simple-transaction-example). 🙏 🚀

It really energizes us to keep creating the best crypto guides.

Use [cointr.ee to find our donation ](https://cointr.ee/coincashew)addresses. 🙏
{% endhint %}

Thank you for supporting Cardano and us! Please use the below cointr.ee link. 😊

{% embed url="https://cointr.ee/coincashew" caption="" %}

### 😁 17.2 Thank yous

Thanks to all 11000 of you, the Cardano hodlers, buidlers, stakers, and pool operators for making the better future a reality.

### \*\*\*\*💬 17**.3 Telegram Chat Channel**

Hang out and chat with our stake pool community at [https://t.me/coincashew](https://t.me/coincashew)

### 🙃 17.4 Contributors, Donators and Friendly Stake Pools of CoinCashew

#### ✨ Contributors to the Guide

* 👏 Antonie of CNT for being awesomely helpful with Youtube content and in telegram.
* 👏 Special thanks to Kaze-Stake for the pull requests and automatic script contributions.
* 👏 The Legend of ₳da \[TLOA\] for translating this guide to Spanish.
* 👏 Chris of OMEGA \| CODEX for security improvements.
* 👏 Raymond of GROW for topologyUpdater improvements and being awesome.

#### 💸 Tip Jar Donators

* 😊 BEBOP 
* 😊 DEW
* 😊 GROW
* 😊 Leonardo
* 😊 YOU?! [Hit us up.](https://cointr.ee/coincashew)

#### 🚀CoinCashew's Preferred Stake Pools

* 🌟 CNT
* 🌟 OMEGA \| CODEX
* 🌟 TLOA
* 🌟 KAZE
* 🌟 BEBOP
* 🌟 DEW
* 🌟 GROW

### 📚 17.5 Reference Material

For more information and official documentation, please refer to the following links:

{% embed url="https://docs.cardano.org/en/latest/getting-started/stake-pool-operators/index.html" caption="" %}

{% embed url="https://testnets.cardano.org/en/shelley/get-started/creating-a-stake-pool/" caption="" %}

{% embed url="https://github.com/input-output-hk/cardano-tutorials" caption="" %}

{% embed url="https://github.com/cardano-community/guild-operators" caption="" %}

{% embed url="https://github.com/gitmachtl/scripts" caption="" %}

#### CNTools by Guild Operators

Many pool operators have asked about how to deploy a stake pool with CNTools. The [official guide can be found here.](https://cardano-community.github.io/guild-operators/#/Scripts/cntools)

## 🛠 18. Operational and Maintenance Tips

### 🤖 18.1 Updating the operational cert with a new KES Period

{% hint style="info" %}
You are required to regenerate the hot keys and issue a new operational certificate, a process called rotating the KES keys, when the hot keys expire.

**Mainnet**: KES keys will be valid for 120 rotations or 90 days
{% endhint %}

**Updating the KES Period**: When it's time to issue a new operational certificate, run the following to find the starting KES period.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cd $NODE_HOME
slotNo=$(cardano-cli shelley query tip --mainnet | jq -r '.slotNo')
slotsPerKESPeriod=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r '.slotsPerKESPeriod')
kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
startKesPeriod=$(( ${kesPeriod} - 1 ))
echo startKesPeriod: ${startKesPeriod}
```
{% endtab %}
{% endtabs %}

Create the new `node.cert` file with the following command. Update `<startKesPeriod>` with the value from above.

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cd $NODE_HOME
chmod u+rwx $HOME/cold-keys
cardano-cli shelley node issue-op-cert \
    --kes-verification-key-file kes.vkey \
    --cold-signing-key-file $HOME/cold-keys/node.skey \
    --operational-certificate-issue-counter $HOME/cold-keys/node.counter \
    --kes-period <startKesPeriod> \
    --out-file node.cert
chmod a-rwx $HOME/cold-keys
```
{% endtab %}
{% endtabs %}

{% hint style="danger" %}
Copy **node.cert** back to your ブロックプロデューサーノード.
{% endhint %}

{% hint style="info" %}
\*\*\*\*✨ **Tip:** With your hot keys created, you can remove access to the cold keys for improved security. This protects against accidental deletion, editing, or access.

To lock,

```bash
chmod a-rwx $HOME/cold-keys
```

To unlock,

```bash
chmod u+rwx $HOME/cold-keys
```
{% endhint %}

### 🔥 18.2 Resetting the installation

Want a clean start? Re-using existing server? Forked blockchain?

Delete git repo, and then rename your previous `$NODE_HOME` and `cold-keys` directory \(or optionally, remove\). Now you can start this guide from the beginning again.

```bash
rm -rf $HOME/git/cardano-node/ $HOME/git/libsodium/
mv $NODE_HOME $(basename $NODE_HOME)_backup_$(date -I)
mv $HOME/cold-keys $HOME/cold-keys_backup_$(date -I)
```

### 🌊 18.3 Resetting the databases

Corrupted or stuck blockchain? Delete all db folders.

```bash
cd $NODE_HOME
rm -rf db
```

### 📝 18.4 Changing the pledge, fee, margin, etc.

{% hint style="info" %}
Need to change your pledge, fee, margin, pool IP/port, or metadata? Simply resubmit your stake pool registration certificate.
{% endhint %}

Find the minimum pool cost.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
minPoolCost=$(cat $NODE_HOME/params.json | jq -r .minPoolCost)
echo minPoolCost: ${minPoolCost}
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
minPoolCost is 340000000 lovelace or 340 ADA. Therefore, your `--pool-cost` must be at a minimum this amount.
{% endhint %}

If you're changing your poolMetaData.json, remember to calculate the hash of your metadata file and re-upload the updated poolMetaData.json file. Refer to [section 9 for information.](./#9-register-your-stakepool) If you're verifying your stake pool ID, the hash is already provided to you by pooltool.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```text
cardano-cli shelley stake-pool metadata-hash --pool-metadata-file poolMetaData.json > poolMetaDataHash.txt
```
{% endtab %}
{% endtabs %}

Update the below registration-certificate transaction with your desired settings.

If you have **multiple relay nodes,** [**refer to section 12**](./#12-register-your-stake-pool) and change your parameters appropriately.

{% hint style="warning" %}
**metadata-url** must be no longer than 64 characters.
{% endhint %}

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley stake-pool registration-certificate \
    --cold-verification-key-file $HOME/cold-keys/node.vkey \
    --vrf-verification-key-file vrf.vkey \
    --pool-pledge 1000000000 \
    --pool-cost 345000000 \
    --pool-margin 0.20 \
    --pool-reward-account-verification-key-file stake.vkey \
    --pool-owner-stake-verification-key-file stake.vkey \
    --mainnet \
    --single-host-pool-relay <dns based relay, example ~ relaynode1.myadapoolnamerocks.com> \
    --pool-relay-port 6000 \
    --metadata-url <url where you uploaded poolMetaData.json> \
    --metadata-hash $(cat poolMetaDataHash.txt) \
    --out-file pool.cert
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
Here we are pledging 1000 ADA with a fixed pool cost of 345 ADA and a pool margin of 20%.
{% endhint %}

Pledge stake to your stake pool.

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```text
cardano-cli shelley stake-address delegation-certificate \
    --stake-verification-key-file stake.vkey \
    --cold-verification-key-file $HOME/cold-keys/node.vkey \
    --out-file deleg.cert
```
{% endtab %}
{% endtabs %}

Copy **deleg.cert** to your **hot environment.**

You need to find the **tip** of the blockchain to set the **ttl** parameter properly.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
currentSlot=$(cardano-cli shelley query tip --mainnet | jq -r '.slotNo')
echo Current Slot: $currentSlot
```
{% endtab %}
{% endtabs %}

Find your balance and **UTXOs**.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query utxo \
    --address $(cat payment.addr) \
    --mainnet > fullUtxo.out

tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

cat balance.out

tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo TxHash: ${in_addr}#${idx}
    echo ADA: ${utxo_balance}
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < balance.out
txcnt=$(cat balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}
```
{% endtab %}
{% endtabs %}

Run the build-raw transaction command.

{% hint style="info" %}
The **ttl** value must be greater than the current tip. In this example, we use current slot + 10000.
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${total_balance} \
    --ttl $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file pool.cert \
    --certificate-file deleg.cert \
    --out-file tx.tmp
```
{% endtab %}
{% endtabs %}

Calculate the minimum fee:

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
fee=$(cardano-cli shelley transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 3 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee
```
{% endtab %}
{% endtabs %}

Calculate your change output.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
txOut=$((${total_balance}-${fee}))
echo txOut: ${txOut}
```
{% endtab %}
{% endtabs %}

Build the transaction.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${txOut} \
    --ttl $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file pool.cert \
    --certificate-file deleg.cert \
    --out-file tx.raw
```
{% endtab %}
{% endtabs %}

Copy **tx.raw** to your **cold environment.**

Sign the transaction.

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file payment.skey \
    --signing-key-file $HOME/cold-keys/node.skey \
    --signing-key-file stake.skey \
    --mainnet \
    --out-file tx.signed
```
{% endtab %}
{% endtabs %}

Copy **tx.signed** to your **hot environment.**

Send the transaction.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction submit \
    --tx-file tx.signed \
    --mainnet
```
{% endtab %}
{% endtabs %}

Changes take effect next epoch. After the next epoch transition, verify that your pool settings are correct.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query ledger-state --mainnet --out-file ledger-state.json
jq -r '.esLState._delegationState._pstate._pParams."'"$(cat stakepoolid.txt)"'"  // empty' ledger-state.json
```
{% endtab %}
{% endtabs %}

### 🧩 18.5 Transferring files over SSH

Common use cases can include

* Downloading backups of stake/payment keys
* Uploading a new operational certificate to the block producer from an offline node

#### To download files from a node to your local PC

```bash
ssh <USERNAME>@<IP ADDRESS> -p <SSH-PORT>
rsync -avzhe “ssh -p <SSH-PORT>” <USERNAME>@<IP ADDRESS>:<PATH TO NODE DESTINATION> <PATH TO LOCAL PC DESTINATION>
```

> Example:
>
> `ssh myusername@6.1.2.3 -p 12345`
>
> `rsync -avzhe "ssh -p 12345" myusername@6.1.2.3:/home/myusername/cardano-my-node/stake.vkey ./stake.vkey`

#### To upload files from your local PC to a node

```bash
ssh <USERNAME>@<IP ADDRESS> -p <SSH-PORT>
rsync -avzhe “ssh -p <SSH-PORT>” <PATH TO LOCAL PC DESTINATION> <USERNAME>@<IP ADDRESS>:<PATH TO NODE DESTINATION>
```

> Example:
>
> `ssh myusername@6.1.2.3 -p 12345`
>
> `rsync -avzhe "ssh -p 12345" ./node.cert myusername@6.1.2.3:/home/myusername/cardano-my-node/node.cert`

### 🏃♂ 18.6 Auto-starting with systemd services

#### 🍰 Benefits of using systemd for your stake pool

1. Auto-start your stake pool when the computer reboots due to maintenance, power outage, etc.
2. Automatically restart crashed stake pool processes.
3. Maximize your stake pool up-time and performance.

#### 🛠 Setup Instructions

Before beginning, ensure your stake pool is stopped.

```bash
killall cardano-node
```

Run the following to create a **unit file** to define your`cardano-node.service` configuration.

{% tabs %}
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
User            = $(whoami)
Type            = forking
WorkingDirectory= $NODE_HOME
ExecStart       = /usr/bin/tmux new -d -s cnode
ExecStartPost   = /usr/bin/tmux send-keys -t cnode $NODE_HOME/startBlockProducingNode.sh Enter 
ExecStop        = killall cardano-node
Restart         = always

[Install]
WantedBy    = multi-user.target
EOF
```
{% endtab %}

{% tab title="relaynode1" %}
```bash
cat > $NODE_HOME/cardano-node.service << EOF 
# The Cardano node service (part of systemd)
# file: /etc/systemd/system/cardano-node.service 

[Unit]
Description     = Cardano node service
Wants           = network-online.target
After           = network-online.target 

[Service]
User            = $(whoami)
Type            = forking
WorkingDirectory= $NODE_HOME
ExecStart       = /usr/bin/tmux new -d -s cnode
ExecStartPost   = /usr/bin/tmux send-keys -t cnode $NODE_HOME/startRelayNode1.sh Enter 
ExecStop        = killall cardano-node
Restart         = always

[Install]
WantedBy    = multi-user.target
EOF
```
{% endtab %}
{% endtabs %}

Copy the unit file to `/etc/systemd/system` and give it permissions.

```bash
sudo cp $NODE_HOME/cardano-node.service /etc/systemd/system/cardano-node.service
```

```bash
sudo chmod 644 /etc/systemd/system/cardano-node.service
```

Run the following to enable auto-start at boot time and then start your stake pool service.

```text
sudo systemctl daemon-reload
sudo systemctl enable cardano-node
sudo systemctl start cardano-node
```

{% hint style="success" %}
Nice work. Your stake pool is now managed by the reliability and robustness of systemd. Below are some commands for using systemd.
{% endhint %}

\*\*\*\*⛓ **Reattach to the node tmux session after system startup**

```text
tmux a
```

#### 🚧 To detach from a **tmux** session and leave the node running in the background

```text
press Ctrl + b + d
```

#### ✅ Check whether the node is active

```text
sudo systemctl is-active cardano-node
```

#### 🔎 View the status of the node service

```text
sudo systemctl status cardano-node
```

#### 🔄 Restarting the node service

```text
sudo systemctl reload-or-restart cardano-node
```

#### 🛑 Stopping the node service

```text
sudo systemctl stop cardano-node
```

#### 🗄 Filtering logs

```bash
journalctl --unit=cardano-node --since=yesterday
journalctl --unit=cardano-node --since=today
journalctl --unit=cardano-node --since='2020-07-29 00:00:00' --until='2020-07-29 12:00:00'
```

### ✅ 18.7 Verify your stake pool ticker with ITN key

In order to defend against spoofing and hijacking of reputable stake pools, a owner can verify their ticker by proving ownership of an ITN stake pool.

{% hint style="info" %}
Incentivized Testnet phase of Cardano’s Shelley era ran from late November 2019 to late June 2020. If you participated, you can verify your ticker.
{% endhint %}

Make sure the ITN's `jcli` binaries are present in `$NODE_HOME`. Use `jcli` to sign your stake pool id with your `itn_owner.skey`

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
./jcli key sign --secret-key itn_owner.skey stakepoolid.txt --output stakepoolid.sig
```
{% endtab %}
{% endtabs %}

Visit [pooltool.io](https://pooltool.io/) and enter your owner public key and pool id witness data in the metadata section.

Find your pool id witness with the following command.

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```text
cat stakepoolid.sig
```
{% endtab %}
{% endtabs %}

Find your owner public key in the file you generated on ITN. This data might be stored in a file ending in `.pub`

Finally, follow [instructions to update your pool registration data](./#18-4-changing-the-pledge-fee-margin-etc) with the pooltool generated **`metadata-url`** and **`metadata-hash`**. Notice the metadata has an "extended" field which proves your ticker ownership since ITN.

### 📚 18.8 Updating your node's configuration files

Keep your config files fresh by downloading the latest .json files.

```bash
NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g')
cd $NODE_HOME
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-byron-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-shelley-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-config.json
sed -i ${NODE_CONFIG}-config.json \
    -e "s/SimpleView/LiveView/g" \
    -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g"
```

### 💸 18.9 Send a simple transaction example

Let's walk through an example to send **10 ADA** to **CoinCashew's tip address** 🙃

First, find the **tip** of the blockchain to set the **ttl** parameter properly.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
currentSlot=$(cardano-cli shelley query tip --mainnet | jq -r '.slotNo')
echo Current Slot: $currentSlot
```
{% endtab %}
{% endtabs %}

Set the amount to send in lovelaces. ✨ Remember **1 ADA** = **1,000,000 lovelaces.**

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
amountToSend=10000000
echo amountToSend: $amountToSend
```
{% endtab %}
{% endtabs %}

Set the destination address which is where you're sending funds to.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
destinationAddress=addr1qxhazv2dp8yvqwyxxlt7n7ufwhw582uqtcn9llqak736ptfyf8d2zwjceymcq6l5gxht0nx9zwazvtvnn22sl84tgkyq7guw7q
echo destinationAddress: $destinationAddress
```
{% endtab %}
{% endtabs %}

Find your balance and **UTXOs**.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query utxo \
    --address $(cat payment.addr) \
    --mainnet > fullUtxo.out

tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

cat balance.out

tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo TxHash: ${in_addr}#${idx}
    echo ADA: ${utxo_balance}
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < balance.out
txcnt=$(cat balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}
```
{% endtab %}
{% endtabs %}

Run the build-raw transaction command.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+0 \
    --tx-out ${destinationAddress}+0 \
    --ttl $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --out-file tx.tmp
```
{% endtab %}
{% endtabs %}

Calculate the current minimum fee:

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
fee=$(cardano-cli shelley transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 2 \
    --mainnet \
    --witness-count 1 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee
```
{% endtab %}
{% endtabs %}

Calculate your change output.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
txOut=$((${total_balance}-${fee}-${amountToSend}))
echo Change Output: ${txOut}
```
{% endtab %}
{% endtabs %}

Build your transaction.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${txOut} \
    --tx-out ${destinationAddress}+${amountToSend} \
    --ttl $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --out-file tx.raw
```
{% endtab %}
{% endtabs %}

Copy **tx.raw** to your **cold environment.**

Sign the transaction with both the payment and stake secret keys.

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file payment.skey \
    --mainnet \
    --out-file tx.signed
```
{% endtab %}
{% endtabs %}

Copy **tx.signed** to your **hot environment.**

Send the signed transaction.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction submit \
    --tx-file tx.signed \
    --mainnet
```
{% endtab %}
{% endtabs %}

Check if the funds arrived.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query utxo \
    --address ${destinationAddress} \
    --mainnet
```
{% endtab %}
{% endtabs %}

You should see output similar to this showing the funds you sent.

```text
                           TxHash                                 TxIx        Lovelace
----------------------------------------------------------------------------------------
100322a39d02c2ead....                                              0        10000000
```

### 🔓 18.10 Harden your node's security

Do not skimp on this critical step to protect your pool and reputation.

{% page-ref page="how-to-harden-ubuntu-server.md" %}

## 🌜 19. Retiring your stake pool

Find the slots per epoch.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
epochLength=$(cat $NODE_HOME/${NODE_CONFIG}-shelley-genesis.json | jq -r '.epochLength')
echo epochLength: ${epochLength}
```
{% endtab %}
{% endtabs %}

Find the current slot by querying the tip.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
slotNo=$(cardano-cli shelley query tip --mainnet | jq -r '.slotNo')
echo slotNo: ${slotNo}
```
{% endtab %}
{% endtabs %}

Calculate the current epoch by dividing the slot tip number by epochLength.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
epoch=$(( $((${slotNo} / ${epochLength})) + 1))
echo current epoch: ${epoch}
```
{% endtab %}
{% endtabs %}

Find the eMax value.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
eMax=$(cat $NODE_HOME/params.json | jq -r '.eMax')
echo eMax: ${eMax}
```
{% endtab %}
{% endtabs %}

{% hint style="info" %}
\*\*\*\*🚧 **Example**: if we are in epoch 39 and eMax is 18,

* the earliest epoch for retirement is 40 \( current epoch  + 1\).
* the latest epoch for retirement is 57 \( eMax + current epoch\). 

Let's pretend we wish to retire as soon as possible in epoch 40.
{% endhint %}

Create the deregistration certificate and save it as `pool.dereg.`

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley stake-pool deregistration-certificate \
--cold-verification-key-file $HOME/cold-keys/node.vkey \
--epoch $((${epoch} + 1)) \
--out-file pool.dereg
echo pool will retire at end of epoch: $((${epoch} + 1))
```
{% endtab %}
{% endtabs %}

Copy **pool.dereg** to your **hot environment.**

Find your balance and **UTXOs**.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query utxo \
    --address $(cat payment.addr) \
    --mainnet > fullUtxo.out

tail -n +3 fullUtxo.out | sort -k3 -nr > balance.out

cat balance.out

tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo TxHash: ${in_addr}#${idx}
    echo ADA: ${utxo_balance}
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < balance.out
txcnt=$(cat balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}
```
{% endtab %}
{% endtabs %}

Run the build-raw transaction command.

{% hint style="info" %}
The **ttl** value must be greater than the current tip. In this example, we use current slot + 10000.
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${total_balance} \
    --ttl $(( ${slotNo} + 10000)) \
    --fee 0 \
    --certificate-file pool.dereg \
    --out-file tx.tmp
```
{% endtab %}
{% endtabs %}

Calculate the minimum fee:

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
fee=$(cardano-cli shelley transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee
```
{% endtab %}
{% endtabs %}

Calculate your change output.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
txOut=$((${total_balance}-${fee}))
echo txOut: ${txOut}
```
{% endtab %}
{% endtabs %}

Build the transaction.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${txOut} \
    --ttl $(( ${slotNo} + 10000)) \
    --fee ${fee} \
    --certificate-file pool.dereg \
    --out-file tx.raw
```
{% endtab %}
{% endtabs %}

Copy **tx.raw** to your **cold environment.**

Sign the transaction.

{% tabs %}
{% tab title="エアギャップオフラインマシン" %}
```bash
cardano-cli shelley transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file payment.skey \
    --signing-key-file $HOME/cold-keys/node.skey \
    --mainnet \
    --out-file tx.signed
```
{% endtab %}
{% endtabs %}

Copy **tx.signed** to your **hot environment.**

Send the transaction.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley transaction submit \
    --tx-file tx.signed \
    --mainnet
```
{% endtab %}
{% endtabs %}

{% hint style="success" %}
Pool will retire at the end of your specified epoch. In this example, retirement occurs at the end of epoch 40.

If you have a change of heart, you can create and submit a new registration certificate before the end of epoch 40, which will then overrule the deregistration certificate.
{% endhint %}

After the retirement epoch, you can verify that the pool was successfully retired with the following query which should return an empty result.

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
cardano-cli shelley query ledger-state --mainnet --out-file ledger-state.json
jq -r '.esLState._delegationState._pstate._pParams."'"$(cat stakepoolid.txt)"'"  // empty' ledger-state.json
```
{% endtab %}
{% endtabs %}

## 🚀 20. Onwards and upwards...

{% hint style="success" %}
Did you find our guide useful? Let us know with a tip and we'll keep updating it. 🙏 🚀

It really energizes us to keep creating the best crypto guides. Use [cointr.ee to find our donation ](https://cointr.ee/coincashew)addresses and share your message. 🙏
{% endhint %}

