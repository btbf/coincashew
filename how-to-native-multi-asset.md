---
description: カルダノネイティブトークンCLIコマンド手順
---

# カルダノネイティブトークン　CLI操作コマンド手順

🛑前提条件
この操作マニュアルはCardano-nodeコマンドライン(CLI)を用いています。  
操作にはUbuntuサーバにインストールされたCardano-nodeを起動する必要があります。  
ただし、リレーノードで完結できます。  

{% hint style="info" %}
この手順では、新しいウォレットを作成しトークンを作成する方法を掲載しています。
既存のウォレットを使用したい場合は、該当箇所を変更してください。
{% endhint %}

## ウォレットアドレスの作成

### 1.ウォレットアドレスのペアキーを作成します

```bash
cd $NODE_HOME
mkdir token
cardano-cli address key-gen \
    --verification-key-file payment.vkey \
    --signing-key-file payment.skey
```

### 2.ペアキーからウォレットアドレスを生成します。

```
cardano-cli address build \
--payment-verification-key-file payment.vkey \
--out-file payment.addr \
--mainnet
```

### 3.ウォレットアドレスを表示します

```
echo "$(cat payment.addr)"
```

{% hint style="info" %}
このアドレスに対して、数ADA送金してください。  
(トランザクション手数料やトークンとの送金に使われます)
{% endhint %}

### 4.残高を確認する
```
cardano-cli query utxo \
    --address $(cat payment.addr) \
    --mainnet \
    --mary-era
```
残高が表示されるか確認してください。  

>                           TxHash                                 TxIx        Amount
> --------------------------------------------------------------------------------------
> b1ddb0347fed2aecc7f00caabaaf2634f8e2d17541f6237bbed78e2092e1c414     0        1000000000 lovelace

## プロトコルパラメーターファイルの作成

```
cardano-cli query protocol-parameters \
    --mainnet \
    --mary-era \
    --out-file params.json
```

## トークンの作成　(トークン名を「GuildCoin」とする場合)

### 0.トークン名と総発行量を設定する

```
token_folder="GuildCoin"
token_name="GuildCoin"
token_t_supply=37000000
```
### 1.ポリシーを作成する

```
cd $NODE_HOME
mkdir ${token_folder}
cd ${token_folder}
```

ポリシーペアキーを作成します

```
cardano-cli address key-gen \
    --verification-key-file ${token_folder}/policy.vkey \
    --signing-key-file ${token_folder}/policy.skey
```

スクリプトファイルを作成します
```
touch ${token_folder}/policy.script && echo "" > ${token_folder}/policy.script
```

```
echo "{" >> ${token_folder}/policy.script
echo "  \"keyHash\": \"$(./cardano-cli address key-hash --payment-verification-key-file ${token_folder}/policy.vkey)\"," >> ${token_folder}/policy.script
echo "  \"type\": \"sig\"" >> ${token_folder}/policy.script
echo "}" >> ${token_folder}/policy.script
```

スクリプトファイルの中身を確認する
```
cat ${token_folder}/policy.script
```
フォーマット例
> {
>   "keyHash": "5805823e303fb28231a736a3eb4420261bb42019dc3605dd83cccd04",
>   "type": "sig"
> }


### 2.新しいアセットを造幣する

```
new_asset=$(cardano-cli transaction policyid --script-file ./${token_folder}/policy.script)
echo ${new_asset}
```
> ex) 328a60495759e0d8e244eca5b85b2467d142c8a755d6cd0592dff47b


ウォレットの残高とUTXOsを出力
```
cardano-cli query utxo \
    --address $(cat payment.addr) \
    --mainnet \
    --mary-era > fullUtxo.out

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


### 3.トランザクションを構築する

```
cardano-cli transaction build-raw \
	     --mary-era \
             --fee 0 \
             ${tx_in} \
             --tx-out $(cat payment.addr)+$(( ${total_balance}+"${token_t_supply} ${new_asset}.${token_name}" \
             --mint="${token_t_supply} ${new_asset}.${token_name}" \
             --out-file tx.tmp
```

トランザクション手数料を計算する

```
cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --witness-count 2 \
    --mainnet \
    --protocol-params-file params.json | awk '{ print $1 }')
echo fee: $fee
```

手数料を計算します
```
txOut=$((${total_balance}-${fee}))
echo txOut: ${txOut}
```

手数料をもとにトランザクションを再構築する

```
cardano-cli transaction build-raw \
      ${tx_in} \
      --tx-out $(cat payment.addr)+${txOut}+"${token_t_supply} ${new_asset}.${token_name}" \
      --mint="${token_t_supply} ${new_asset}.${token_name}" \
      --mary-era \
      --fee ${fee} \
      --out-file matx.raw
```

トランザクションに署名する

```
cardano-cli transaction sign \
	     --signing-key-file payment.skey \
	     --signing-key-file ${token_folder}/policy.skey \
	     --script-file ${token_folder}/policy.script \
	     --mainnet \
	     --tx-body-file matx.raw \
      --out-file matx.signed
```

トランザクションを送信する

```
cardano-cli transaction submit \
    --tx-file matx.signed \
    --mainnet
```


## トークンの送信


##　トークンのBurn(焼却)

