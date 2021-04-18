## 🚀 このマニュアルに関する問い合わせ先

{% hint style="success" %}
このマニュアルは役に立ちましたか？ 不明な点がある場合は、下記までご連絡下さい。

・コミュニティ：[Cardano SPO Japanese Guild](https://discord.com/invite/3HnVHs3)

・Twitter：[@btbfpark](https://twitter.com/btbfpark)

・Twitter：[@X\_StakePool\_XSP](https://twitter.com/X_StakePool_XSP)

{% endhint %}

{% hint style="success" %} 2021年4月18日時点でこのガイドは v.1.26.2に対応しています。 😁 {% endhint %}

{% hint style="info" %}
このマニュアルは、[X Stake Pool](https://xstakepool.com)オペレータの[BTBF](https://twitter.com/btbfpark)が[CoinCashew](https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node#9-register-your-stakepool)より許可を得て、日本語翻訳しております。
{% endhint %}

 `cardano-node`は常に更新されており、バージョンがアップデートされるたびにプールサーバでも作業が必要です。 [Official Cardano-Node Github Repo](https://github.com/input-output-hk/cardano-node) をフォローし最新情報を取得しましょう。

# 0. 1.26.2緊急アップデート

{% hint style="info" %}
このバージョンはブロックプロデューサーノードでの不具合を改善するものとなり、BPノードを優先的にバージョンアップしてください。
(リレーノードには適用しなくても問題ないです)
{% endhint %}

## 0-2.ソースコードをダウンロードする

```bash
cd $HOME/git
rm -rf cardano-node-old/
git clone https://github.com/input-output-hk/cardano-node.git cardano-node2
cd cardano-node2/
```

## 0-3.ソースコードからビルドする

```bash
cabal update
rm -rf $HOME/git/cardano-node2/dist-newstyle/build/x86_64-linux/ghc-8.10.2
rm -rf $HOME/git/cardano-node2/dist-newstyle/build/x86_64-linux/ghc-8.10.4
git fetch --all --recurse-submodules --tags
git checkout tags/1.26.2
cabal configure -O0 -w ghc-8.10.4
```
```bash
echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
cabal build cardano-node cardano-cli
```

> Warning: Requested index-state 2021-03-15T00:00:00Z is newer than
'hackage.haskell.org'! Falling back to older state (2021-03-14T23:47:09Z).
Resolving dependencies...

ここで止まっているかのように見えますが、時間がかかるのでそのままお待ちください。


> ビルド完了までに15分～40分ほどかかります。  
> Linking /home/btbf/git/cardano-node2/dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-cli-1.26.2/t/cardano-cli-test/build/cardano-cli-test/cardano-cli-test ...　が最後のメッセージならビルド成功

## 0-4.バージョン確認

```bash
$(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-cli") version
$(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-node") version
```

## 0-5.ノードをストップする

```bash
sudo systemctl stop cardano-node
```

## 0-6.バイナリーファイルをシステムフォルダーへコピーする

```bash
sudo cp $(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
```

```bash
sudo cp $(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node
```

## 0-7.システムに反映されたノードバージョンを確認する

```bash
cardano-node version
cardano-cli version
```

## 0-8.ノードを起動する

```bash
sudo systemctl start cardano-node
tmux a -t cnode
```

前バージョンで使用していたバイナリフォルダをリネームし、バックアップとして保持します。最新バージョンを構築したフォルダをcardano-nodeとして使用します。

```bash
cd $HOME/git
mv cardano-node/ cardano-node-old/
mv cardano-node2/ cardano-node/
```

## 0-9.ブロックログ関連サービスを再起動する（BPサーバーのみ）

```bash
sudo systemctl reload-or-restart cnode-cncli-sync.service
tmux a -t cncli
```

{% hint style="info" %}
「100.00% synced」になるまで待ちます。  
100%になったら、Ctrl+bを押した後に d を押し元の画面に戻ります  
(バックグラウンド実行に切り替え)
{% endhint %}

```bash
sudo systemctl reload-or-restart cnode-cncli-validate.service
sudo systemctl reload-or-restart cnode-cncli-leaderlog.service
sudo systemctl reload-or-restart cnode-logmonitor.service
sudo systemctl reload-or-restart autoleaderlog
```

以上、ここで終了です。


# 📡 1. 1.25.1からのノードバージョンアップデート手順

{% hint style="danger" %}
全ての更新を終えるまで約3時間～4時間ほどかかる場合があります。  
時間に余裕があるときに実施してください。
{% endhint %}

{% hint style="info" %}
1.25.1から1.26.1へのバージョンアップはDB更新が発生します。  
この更新には60分～120分以上かかる場合があります。その間ノードは停止状態となりブロック生成が出来なくなります。  
スロットリーダースケジュールを確認し、次のブロック生成予定までに十分時間があるタイミングで実施してください。
特にBP更新時やリレーノード1台のみで運用しているプールはご注意ください。
{% endhint %}

## 1-1.GHCとCabalをアップデートする

```bash
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
```

> Press ENTER to proceed or ctrl-c to abort.
Note that this script can be re-run at any given time.

⇒Enter

>Press ENTER to proceed or ctrl-c to abort.
Installation may take a while

⇒Enter

>Answer with YES or NO and press ENTER

⇒noと入力しEnter

>Detected bash shell on your system...
If you want ghcup to automatically add the required PATH variable to "/home/xxxx/.bashrc"
answer with YES, otherwise with NO and press ENTER.

⇒yesと入力しEnter

```bash
source ~/.bashrc
ghcup upgrade
ghcup install ghc 8.10.4
ghcup set ghc 8.10.4
ghc --version
# 8.10.4と表示されればOK

ghcup install cabal 3.4.0.0
ghcup set cabal 3.4.0.0
cabal --version
# 3.4.0.0と表示されればOK
```

{% hint style="info" %}
バイナリーファイルは必ずソースコードからビルドするようにし、整合性をチェックしてください。  
また、IOGは現在ARMアーキテクチャ用のバイナリファイルを提供していません。Raspberry Piを使用してプールを構築する場合は、ARM用コンパイラでコンパイルする必要があります。
{% endhint %}

## 1-2.ソースコードをダウンロードする

```bash
cd $HOME/git
rm -rf cardano-node-old/
git clone https://github.com/input-output-hk/cardano-node.git cardano-node2
cd cardano-node2/
```

## 1-3.ソースコードからビルドする

```bash
cabal update
rm -rf $HOME/git/cardano-node2/dist-newstyle/build/x86_64-linux/ghc-8.10.2
rm -rf $HOME/git/cardano-node2/dist-newstyle/build/x86_64-linux/ghc-8.10.4
git fetch --all --recurse-submodules --tags
git checkout tags/1.26.1
cabal configure -O0 -w ghc-8.10.4
```

> Warning: Requested index-state 2021-03-15T00:00:00Z is newer than
'hackage.haskell.org'! Falling back to older state (2021-03-14T23:47:09Z).
Resolving dependencies...

ここで止まっているかのように見えますが、時間がかかるのでそのままお待ちください。

```bash
echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
cabal build cardano-node cardano-cli
```

> ビルド完了までに15分～40分ほどかかります。  
> Linking /home/xxxx/git/cardano-node2/dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-cli-1.26.1/t/cardano-cli-test/build/cardano-cli-test/cardano-cli-test ...　が最後のメッセージならビルド成功

## 1-4.バージョン確認

```bash
$(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-cli") version
$(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-node") version
```

## 1-5.ノードをストップする

```bash
sudo systemctl stop cardano-node
```

## 1-6.バイナリーファイルをシステムフォルダーへコピーする

```bash
sudo cp $(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
```

```bash
sudo cp $(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node
```

## 1-7.システムに反映されたノードバージョンを確認する

```bash
cardano-node version
cardano-cli version
```

## 1-8.ノードを起動する

```bash
sudo systemctl start cardano-node
tmux a -t cnode
```

{% hint style="danger" %}
DB更新が完了するまで、約60分～120分かかります。  
更新が完了すると、自動的にノードが起動します。
{% endhint %}

<!--```bash
cd $HOME/git
rm -rf cardano-node-old/
mkdir cardano-node2
cd cardano-node2
```

## 1-1.新しいバイナリーファイルをダウンロードする

```bash
wget https://hydra.iohk.io/build/5984213/download/1/cardano-node-1.26.1-linux.tar.gz
tar -xf cardano-node-1.26.1-linux.tar.gz
```
**cardano-cli** と **cardano-node** が希望のバージョンに更新されたことを確認して下さい。

```bash
$(find $HOME/git/cardano-node2/ -type f -name "cardano-cli") version
```
```bash
$(find $HOME/git/cardano-node2/ -type f -name "cardano-node") version
```

## 1-2.バイナリーファイルを更新する 
  

{% hint style="danger" %}
バイナリーファイルを更新する前に、ノードを停止して下さい。
{% endhint %}

```
sudo systemctl stop cardano-node
```

**cardano-cli** と **cardano-node** ファイルをbinディレクトリにコピーします。

```bash
sudo cp $(find $HOME/git/cardano-node2/ -type f -name "cardano-cli") /usr/local/bin/cardano-cli
```
```bash
sudo cp $(find $HOME/git/cardano-node2/ -type f -name "cardano-node") /usr/local/bin/cardano-node
```

バージョンを確認します。
```bash
cardano-node version
cardano-cli version
```
> 1.26.1と表示されたらOK

ノードを再起動します。
```
sudo systemctl start cardano-node
tmux a -t cnode
```
-->

# 2.各ツールを導入している場合は以下の内容を実施ください

{% hint style="danger" %}
リレーノード／ブロックプロデューサーノードごとに作業内容が異なりますので、タブで切り替えてください。
{% endhint %}

{% tabs %}
{% tab title="リレーノード" %}

## 2-1-1 topologyUpdater.shを更新する

```bash
cd $NODE_HOME
sed -i topologyUpdater.sh \
  -e "s/jq -r .blockNo/jq -r .block/g"
```

## 2-1-2 gLiveViewを更新する

```bash
cd ${NODE_HOME}/scripts
curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh
curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
chmod 755 gLiveView.sh
sed -i env \
    -e "s/\#CONFIG=\"\${CNODE_HOME}\/files\/config.json\"/CONFIG=\"\${NODE_HOME}\/mainnet-config.json\"/g" \
    -e "s/\#SOCKET=\"\${CNODE_HOME}\/sockets\/node0.socket\"/SOCKET=\"\${NODE_HOME}\/db\/socket\"/g"
```

{% hint style="info" %}
リレーノードのポート番号を変更している場合は、"nano env" でファイルを開きポート番号を変更してください。
{% endhint %}

## 2-1-3 gLiveViewを起動する

```bash
./gLiveView.sh
```

ノードが同期しているか確認する

{% hint style="danger" %}
リレーノードにおける "TraceMempool:true" について、現バージョンでCPUのパフォーマンスは改善されたようですが、どうしてもメモリ消費が増加傾向にあるため、しばらくfalseで様子見といたします。新たな情報が出ましたらアナウンスさせていただきます。
{% endhint %}

{% endtab %}

{% tab title="ブロックプロデューサーノード" %}

## 2-2-1.gLiveViewとcncli.shファイルを更新する

```bash
cd $NODE_HOME/scripts
curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh
curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
wget -N https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/cncli.sh
chmod 755 gLiveView.sh
```

## 2-2-2.設定ファイルを編集する

envファイルを編集します

```bash
nano env
```

ファイル内上部にある設定値を変更します。  
先頭の **#** を外し、ご自身の環境に合わせCNODE_HOME=の**user_name**やファイル名、ポート番号を設定します。  
下記以外の**#**がついている項目はそのままで良いです。

```bash
CCLI="/usr/local/bin/cardano-cli"
CNODE_HOME=/home/user_name/cardano-my-node
CNODE_PORT=6000
CONFIG="${CNODE_HOME}/mainnet-config.json"
SOCKET="${CNODE_HOME}/db/socket"
BLOCKLOG_TZ="Asia/Tokyo"
```

cncli.shファイルを編集します。

```bash
nano cncli.sh
```

ファイル内の設定値を変更します。  
先頭の **#** を外し、ご自身の環境に合わせてプールIDやファイル名を設定します。

```bash
POOL_ID="xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
POOL_VRF_SKEY="${CNODE_HOME}/vrf.skey"
POOL_VRF_VKEY="${CNODE_HOME}/vrf.vkey"
```

## 2-2-3.gLiveViewを起動する

```bash
./gLiveView.sh
```
ノードが同期しているか確認する。

## 2-2-4.CNCLIをバージョンアップする

```bash
rustup update
cd $HOME/git/cncli
git fetch --all --prune
git checkout v2.0.0
cargo install --path . --force
cncli --version
```

## 2-2-5.ブロックログ関連サービスを再起動する

```bash
sudo systemctl reload-or-restart cnode-cncli-sync.service
tmux a -t cncli
```

{% hint style="info" %}
「100.00% synced」になるまで待ちます。  
100%になったら、Ctrl+bを押した後に d を押し元の画面に戻ります  
(バックグラウンド実行に切り替え)
{% endhint %}

```bash
sudo systemctl reload-or-restart cnode-cncli-validate.service
sudo systemctl reload-or-restart cnode-cncli-leaderlog.service
sudo systemctl reload-or-restart cnode-logmonitor.service
sudo systemctl reload-or-restart autoleaderlog
```

## 2-2-6.params.jsonを更新する
```bash
cd $NODE_HOME
cardano-cli query protocol-parameters \
    --mainnet \
    --out-file params.json
```
{% endtab %}
{% endtabs %}

最後に、前バージョンで使用していたバイナリフォルダをリネームし、バックアップとして保持します。最新バージョンを構築したフォルダをcardano-nodeとして使用します。

```bash
cd $HOME/git
mv cardano-node/ cardano-node-old/
mv cardano-node2/ cardano-node/
```

# 📂 3 前バージョンへロールバックする場合
最新バージョンに問題がある場合は、以前のバージョンへ戻す場合のみ実行してください。

{% hint style="danger" %}
バイナリを更新する前にノードを停止します。
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}

```bash
killall -s 2 cardano-node
```

{% endtab %}

{% tab title="リレーノード1" %}

```bash
killall -s 2 cardano-node
```

{% endtab %}

{% tab title="systemd" %}

```bash
sudo systemctl stop cardano-node
```

{% endtab %}
{% endtabs %}

古いリポジトリを復元します。

```bash
cd $HOME/git
mv cardano-node/ cardano-node-rolled-back/
mv cardano-node-old/ cardano-node/
```

バイナリーファイルを `/usr/local/bin`にコピーします。

```bash
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node
```

バイナリーが希望するバージョンであることを確認します。

```bash
/usr/local/bin/cardano-cli version
/usr/local/bin/cardano-node version
```

{% hint style="success" %}
次にノードを再起動して同期が開始しているか確認して下さい。
{% endhint %}

{% tabs %}
{% tab title="ブロックプロデューサーノード" %}

```bash
cd $NODE_HOME
./startBlockProducingNode.sh
```

{% endtab %}

{% tab title="リレードード1" %}

```bash
cd $NODE_HOME
./startRelayNode1.sh
```

{% endtab %}

{% tab title="systemd" %}

```bash
sudo systemctl start cardano-node
```

{% endtab %}
{% endtabs %}

### 🤖 4.3 上手く行かない場合は、ソースコードから再構築

次のマニュアル [カルダノステークプール構築手順](./)1～3を実行する。

## 👏 5. 寄付とクレジット表記

{% hint style="info" %}
このマニュアル制作に携わった全ての方に、感謝申し上げます。 快く翻訳を承諾して頂いた、[CoinCashew](https://www.coincashew.com/)には敬意を表します。
この活動をサポートして頂ける方は、是非寄付をよろしくお願い致します。
{% endhint %}

### CoinCashew ADAアドレス

```bash
addr1qxhazv2dp8yvqwyxxlt7n7ufwhw582uqtcn9llqak736ptfyf8d2zwjceymcq6l5gxht0nx9zwazvtvnn22sl84tgkyq7guw7q
```

### X StakePoolへの寄付  

カルダノ分散化、日本コミュニティ発展の為に日本語化させて頂きました。私達をサポート頂ける方は当プールへ委任頂けますと幸いです。  

* Ticker：XSP  
Pool ID↓  

```bash
788898a81174665316af96880459dcca053f7825abb1b0db9a433630
```

* ADAアドレス

```bash
addr1q85kms3xw788pzxcr8g8d4umxjcr57w55k2gawnpwzklu97sc26z2lhct48alhew43ry674692u2eynccsyt9qexxsesjzz8qp
```
