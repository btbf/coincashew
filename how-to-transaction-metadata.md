

# cardano-cliを使用してメタデータ付きトランザクションを送信する方法

{% hint style="info" %}
以下の内容は、cardano-cliを使用して、payment.addrから任意のアドレスにメタデータを添付してトランザクションを送信する方法です。 トランザクションを送信するには最低1ADA必要です。
{% endhint %}

## metadataフォルダを作成します
```bash
cd $NODE_HOME
mkdir metadata
```

## metadataに使用するjsonファイルを作成します
```bash
cat > $NODE_HOME/metadata/sendMetadata.json << EOF
{
"0" : { "message" : "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" }
}
EOF
```
> xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx　を任意の文字列(ハッシュ値)に置き換えてください

## 送金金額を指定します。（最低送金額は1ADA)
```
amountToSend=1000000
echo amountToSend: $amountToSend
```
> ここで指定しているのは1,000,000 lovelace (1ADA)

## 送金先アドレスを指定します
```
destinationAddress=addr1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo destinationAddress: $destinationAddress
```
> addr1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx を任意のアドレスに置き換えてください

## 現在のスロット番号を算出します
```bash
currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slotNo')
echo Current Slot: $currentSlot
```

## payment.addrの未使用トランザクションを算出します
```bash
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

## トランザクション計算ファイルを作成します
```bash
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+0 \
    --tx-out ${destinationAddress}+0 \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --json-metadata-no-schema \
    --metadata-json-file $NODE_HOME/metadata/sendMetadata.json \
    --mary-era \
    --out-file tx.tmp
```

## 手数料を算出します

```bash
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 2 \
    --mainnet \
    --witness-count 1 \
    --byron-witness-count 0 \
    --protocol-params-file $NODE_HOME/params.json | awk '{ print $1 }')
echo fee: $fee
```

## Outputを計算します
```bash
txOut=$((${total_balance}-${fee}-${amountToSend}))
echo Change Output: ${txOut}
```

トランザクションファイルを再構築します
```bash
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat payment.addr)+${txOut} \
    --tx-out ${destinationAddress}+${amountToSend} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --json-metadata-no-schema \
    --metadata-json-file $NODE_HOME/metadata/sendMetadata.json \
    --mary-era \
    --out-file tx.raw
```

## トランザクションファイルに署名します
```bash
cardano-cli transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file payment.skey \
    --mainnet \
    --out-file tx.signed
```


## トランザクションを送信します。
```bash
cardano-cli transaction submit \
    --tx-file tx.signed \
    --mainnet
```

