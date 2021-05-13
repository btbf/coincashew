## 🚀 このマニュアルに関する問い合わせ先

{% hint style="success" %}
このマニュアルは役に立ちましたか？ 不明な点がある場合は、下記までご連絡下さい。

・コミュニティ：[Cardano SPO Japanese Guild](https://discord.com/invite/3HnVHs3)

・Twitter：[@btbfpark](https://twitter.com/btbfpark)

・Twitter：[@X\_StakePool\_XSP](https://twitter.com/X_StakePool_XSP)

{% endhint %}

{% hint style="success" %} 2021年5月13日時点でこのガイドは v.1.27.0に対応しています。 😁 {% endhint %}

{% hint style="info" %}
このマニュアルは、[X Stake Pool](https://xstakepool.com)オペレータの[BTBF](https://twitter.com/btbfpark)が[CoinCashew](https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node#9-register-your-stakepool)より許可を得て、日本語翻訳しております。
{% endhint %}

 `cardano-node`は常に更新されており、バージョンがアップデートされるたびにプールサーバでも作業が必要です。 [Official Cardano-Node Github Repo](https://github.com/input-output-hk/cardano-node) をフォローし最新情報を取得しましょう。

# 1. カルダノノード1.27.0 アップデート

{% hint style="info" %}
ノードバージョン1.27.0は、ステークプールによって提案された新しいCLIコマンドのサポートなど重要な新機能を提供します。
これには、ノードバージョン1.26.2でリリースされたエポック境界計算のパフォーマンス修正に加えて、いくつかのバグ修正とコードの改善が含まれています。
また、今後の機能リリース（特に、Alonzo時代のPlutusスクリプト）の準備に必要な多くの基本的な変更も含まれています。
このリリースには、APIコマンドとCLIコマンドへの重大な変更が含まれており、GHCバージョン8.6.5を使用したコンパイルはサポートされていないことに注意してください。
{% endhint %}

{% hint style="danger" %}
1.27.0では1.26.2に比べて同期スピードが遅いです。そのためブロック生成スケジュール間隔に余裕があるタイミングでの実施をお願いします。　　
ノードを再起動してから同期するまでに5分～8分かかります。
{% endhint %}

{% hint style="danger" %}
ノード起動状態で並行して新バージョンをビルドするとメモリ使用率が8GB~10GBに達するため、サーバーメモリを8GBで契約されている場合はビルドもノードも落ちます。  
ノードを停止（手順1-2）してからビルドすることをお勧めします。
{% endhint %}

## 1-0. GHCバージョンを確認する

```
ghc --version
```
> GHCのバージョンが「8.10.4」であることを確認してください。
> 8.6.5は非対応となります。

## 1-1.ソースコードをダウンロードする

```bash
cd $HOME/git
rm -rf cardano-node-old/
git clone https://github.com/input-output-hk/cardano-node.git cardano-node2
cd cardano-node2/
```

## 1-2.ノードをストップする

```bash
sudo systemctl stop cardano-node
```

## 1-3.ソースコードからビルドする

```bash
cabal update
```
> HEAD is now at 8d44955af Merge #3066
Downloading the latest package list from hackage.haskell.org

ここで止まっているかのように見えますが、時間がかかるのでそのままお待ちください。


```
git fetch --all --recurse-submodules --tags
git checkout tags/1.27.0
cabal configure -O0 -w ghc-8.10.4
```
> 'hackage.haskell.org'! Falling back to older state (2021-03-14T23:47:09Z).
Resolving dependencies...

ここで止まっているかのように見えますが、時間がかかるのでそのままお待ちください。


```bash
echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
cabal build cardano-node cardano-cli
```

> ビルド完了までに15分～40分ほどかかります。  

## 1-4.バージョン確認

```bash
$(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-cli") version
$(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-node") version
```

## 1-5.バイナリーファイルをシステムフォルダーへコピーする

```bash
sudo cp $(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
```

```bash
sudo cp $(find $HOME/git/cardano-node2/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node
```

## 1-6.システムに反映されたノードバージョンを確認する

```bash
cardano-node version
cardano-cli version
```

## 1-7.ノードを起動する

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

## 2.CNCLIをバージョンアップする（BPサーバーのみ）

サービスを止める
```
sudo systemctl stop cnode-cncli-sync.service
```
```
sudo systemctl stop cnode-cncli-validate.service
sudo systemctl stop cnode-cncli-leaderlog.service
```
CNCLIをアップデートする
```bash
rustup update
cd $HOME/git/cncli
git fetch --all --prune
git checkout v2.1.0
cargo install --path . --force
cncli --version
```


## 3.ブロックログ関連サービスを再起動する（BPサーバーのみ）

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
sudo systemctl reload-or-restart autoleaderlog
sudo systemctl reload-or-restart cnode-cncli-validate.service
sudo systemctl reload-or-restart cnode-cncli-leaderlog.service
sudo systemctl reload-or-restart cnode-logmonitor.service
```


最後に、前バージョンで使用していたバイナリフォルダをリネームし、バックアップとして保持します。最新バージョンを構築したフォルダをcardano-nodeとして使用します。

```bash
cd $HOME/git
mv cardano-node/ cardano-node-old/
mv cardano-node2/ cardano-node/
```

ノードバージョンアップは以上です。


# 📂 4 前バージョンへロールバックする場合
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
