---
description: ノード保護のためのセキュリティ強化方法です。
---
{% hint style="info" %}
AWS EC2及びlightsailは特殊環境なため、このマニュアル通りに動かない場合がございます。  
不明な点はGuildコミュニティで質問してみてください。
{% endhint %}

{% hint style="info" %}
この手順はエアギャップオフラインマシン(VirtualBox上のUbuntu)では実施する必要はありません
{% endhint %}


# Ubuntuサーバーを強化する手順(初期設定)

<!--{% hint style="success" %}
Thank you for your support and kind messages! It really energizes us to keep creating the best crypto guides. Use [cointr.ee to find our donation ](https://cointr.ee/coincashew)addresses and share your message. 🙏 
{% endhint %}-->

## オススメのターミナルソフト

1.R-Login(Winodws)[http://nanno.dip.jp/softlib/man/rlogin/](http://nanno.dip.jp/softlib/man/rlogin/) 
2.Terminal(Mac)[https://www.webdesignleaves.com/pr/plugins/mac_terminal_basics_01.html](https://www.webdesignleaves.com/pr/plugins/mac_terminal_basics_01.html)  
  


## 🧙♂ ルート権限を付与したユーザーアカウントの作成

{% hint style="info" %}
サーバを操作する場合はrootアカウントを使用せず、root権限を付与したユーザーアカウントで操作するようにしましょう。
rootアカウントで誤ってrmコマンドを使用すると、サーバ全体が完全消去されます。
{% endhint %}


新しいユーザーの追加　(例：cardano)

1.上記ターミナルソフトを使用し、サーバーに割り当てられた初期アカウント(rootなど)でログインする。  

2.新しいユーザーアカウントを作る(任意のアルファベット文字)  

```text
adduser cardano
```

```
New password:           # ユーザーのパスワードを設定
Retype new password:    # 確認再入力

Enter the new value, or press ENTER for the default
        Full Name []:   # フルネーム等の情報を設定 (不要であればブランクでも OK)
        Room Number []:
        Work Phone []:
        Home Phone []:
        Other []:
Is the information correct? [Y/n]:y
```

cardanoをsudoグループに追加する

```text
usermod -G sudo cardano
```

rootユーザーからログアウトする

```
exit
```

3.ターミナルソフトのユーザーをパスワードを上記で作成したユーザーとパスワードに書き換えて再接続。



## \*\*\*\*🔏 **SSHパスワード認証を無効化し、SSH鍵認証方式のみを使用する**

{% hint style="info" %}
SSHを強化する基本的なルールは次の通りです。

* SSHログイン時パスワード無効化 \(秘密鍵を使用\)
* rootアカウントでのSSHログイン無効化 \(root権限が必要なコマンドは`su` or `sudo`コマンドを使う\)
* 許可されていないアカウントからのログイン試行をログに記録する \(fail2banなどの、不正アクセスをブロックまたは禁止するソフトウェアの導入を検討する\)
* SSHログイン元のIPアドレス範囲のみに限定する \(希望する場合のみ\)※利用プロバイダーによっては、定期的にグローバルIPが変更されるので注意が必要
{% endhint %}

### 鍵ペアーの作成

```
ssh-keygen -t rsa
```
次のような返り値があります。  
それぞれ何も入力せずにEnterを押してください
```
Enter file in which to save the key (/home/cardano/.ssh/id_rsa):  #このままEnter
lsEnter passphrase (empty for no passphrase): #このままEnter
Enter same passphrase again: #このままEnter
```
> パスワードは設定しなくてもOK

```
cd ~/.ssh
ls
```
id_rsa（秘密鍵）とid_rsa.pub（公開鍵）というファイルが作成されているか確認する。

```
cd ~/.ssh/
cat id_rsa.pub >> authorized_keys
chmod 600 authorized_keys
chmod 700 ~/.ssh
rm id_rsa.pub
```

### id_rsaファイルをローカルパソコンへダウンロードする  

1.R-loginの場合はファイル転送ウィンドウを開く  
2.左側ウィンドウ(ローカル側)は任意の階層にフォルダを作成する。  
3.右側ウィンドウ(サーバ側)は「.ssh」フォルダを選択する  
4.右側ウィンドウから、id_rsaファイルの上で右クリックして「ファイルのダウンロード」を選択する  
5.一旦サーバからログアウトする
6.R-Loginのサーバ接続編集画面を開き、「SSH認証鍵」をクリックし4でダウンロードしたファイルを選ぶ
7.サーバへ接続する

### SSHの設定変更

`/etc/ssh/sshd_config`ファイルを開く

```text
sudo nano /etc/ssh/sshd_config
```

**ChallengeResponseAuthentication**の項目を「no」にする

```text
ChallengeResponseAuthentication no
```

**PasswordAuthentication**の項目を「no」にする

```text
PasswordAuthentication no 
```

**PermitRootLogin**の項目を「no」にする

```text
PermitRootLogin no
```

**PermitEmptyPasswords**の項目を「no」にする

```text
PermitEmptyPasswords no
```

ポート番号をランダムな数値へ変更する (49513～65535までの番号)


```bash
Port xxxxx　先頭の#を外してランダムな数値へ変更してください
```
{% hint style="info" %}
ローカルマシンからSSHログインする際、ポート番号を以下で設定した番号に合わせてください。
{% endhint %}


> Ctrl+O で保存し、Ctrl+Xで閉じる

SSH構文にエラーがないかチェックします。

```text
sudo sshd -t
```

SSH構文エラーがない場合、SSHプロセスを再起動します。

```text
sudo service sshd reload
```

一旦、ログオフし、ログイン出来るか確認します。

```text
exit
```


{% hint style="info" %}
上記でログイン出来ない場合は、SSHキーを指定してログインします。


## \*\*\*\*🤖 **システムを更新する**

{% hint style="warning" %}
不正アクセスを予防するには、システムに最新のパッチを適用することが重要です。
{% endhint %}

```bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get autoremove
sudo apt-get autoclean
```

自動更新を有効にすると、手動でインストールする手間を省けます。

```text
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 🧸 rootアカウントを無効にする

サーバーのセキュリティを維持するために、頻繁にrootアカウントでログインしないでください。

```bash
# rootアカウントを無効にするには、-lオプションを使用します。
sudo passwd -l root
```

```bash
# 何らかの理由でrootアカウントを有効にする必要がある場合は、-uオプションを使用します。
sudo passwd -u root
```

## 🧩 安全な共有メモリー

{% hint style="info" %}
システムで共有されるメモリを保護します。
{% endhint %}

`/etc/fstab`を開きます

```text
sudo nano /etc/fstab
```

次の行をファイルの最後に追記して保存します。

```text
tmpfs	/run/shm	tmpfs	ro,noexec,nosuid	0 0
```

変更を有効にするには、システムを再起動します。

```text
sudo reboot
```

## \*\*\*\*⛓ **Fail2banのインストール**

{% hint style="info" %}
Fail2banは、ログファイルを監視し、ログイン試行に失敗した特定のパターンを監視する侵入防止システムです。特定のIPアドレスから（指定された時間内に）一定数のログイン失敗が検知された場合、Fail2banはそのIPアドレスからのアクセスをブロックします。
{% endhint %}

```text
sudo apt-get install fail2ban -y
```

SSHログインを監視する設定ファイルを開きます。

```text
sudo nano /etc/fail2ban/jail.local
```

ファイルの最後に次の行を追加し保存します。

```bash
[sshd]
enabled = true
port = <22 or your random port number>
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
```

fail2banを再起動して設定を有効にします。

```text
sudo systemctl restart fail2ban
```

## \*\*\*\*🧱 **ファイアウォールを構成する**

標準のUFWファイアウォールを使用して、ノードへのネットワークアクセスを制限できます。

新規インストール時点では、デフォルトでufwが無効になっているため、以下のコマンドで有効にしてください。

* SSH接続用のポート22番\(または設定したランダムなポート番号 \#\)
* ノード用のポート6000番または6001番
* ノード監視Grafana用3000番ポート
* Prometheus-node-exporter用のポート12798・9100をリレーノードのIPのみ受け付ける用に設定してください。  
* ブロックプロデューサーノードおよびリレーノード用に設定を変更して下さい。  
* ブロックプロデューサーノードでは、リレーノードのIPのみ受け付ける用に設定してください。  
{% tabs %}
{% tab title="ブロックプロデューサーノード" %}
```bash
sudo ufw allow <22またはランダムなポート番号>/tcp
sudo ufw allow from <リレーノードIP> to any port <BP用のポート番号(6000)>
sudo ufw allow from <リレーノードIP> to any port 12798
sudo ufw allow from <リレーノードIP> to any port 9100
sudo ufw enable
sudo ufw status numbered
```
{% endtab %}

{% tab title="リレーノード1" %}
```bash
sudo ufw allow <22またはランダムなポート番号>/tcp
sudo ufw allow 6000/tcp
sudo ufw allow 3000/tcp
sudo ufw enable
sudo ufw status numbered
```
{% endtab %}
{% endtabs %}


設定が有効であることを確認します。

> ```csharp
>      To                         Action      From
>      --                         ------      ----
> [ 1] 22/tcp                     ALLOW IN    Anywhere
> [ 2] 3000/tcp                   ALLOW IN    Anywhere
> [ 3] 6000/tcp                   ALLOW IN    Anywhere
> [ 4] 22/tcp (v6)                ALLOW IN    Anywhere (v6)
> [ 5] 3000/tcp (v6)              ALLOW IN    Anywhere (v6)
> [ 6] 6000/tcp (v6)              ALLOW IN    Anywhere (v6)
> ```

## 🔭 リスニングポートの確認

安全なサーバーを維持するには、時々リスニングネットワークポートを検証する必要があります。これにより、ネットワークに関する重要な情報を得られます。

```text
netstat -tulpn
ss -tulpn
```


## 🛠 SSHの2段階認証を設定する

{% hint style="warning" %}
設定に失敗するとログインできなくなる場合があるので、設定前に２つのウィンドウでログインしておいてください。  
万が一ログインできなくなった場合、復旧できます。
{% endhint %}

{% hint style="info" %}
SSHはリモートアクセスに使用されますが、重要なデータを含むコンピュータとの接続としても使われるため、別のセキュリティーレイヤーの導入をお勧めします。2段階認証(2FA)  
事前にお手元のスマートフォンに「Google認証システムアプリ」のインストールが必要です
{% endhint %}

```text
sudo apt update
sudo apt upgrade
sudo apt install libpam-google-authenticator -y
```

SSHがGoogle Authenticator PAM モジュールを使用するために、`/etc/pam.d/sshd`ファイルを編集します。

```text
sudo nano /etc/pam.d/sshd 
```

先頭の **@include common-auth**を#を付与してコメントアウトする
```
#@include common-auth
```

以下の行を追加します。

```text
auth required pam_google_authenticator.so
```

以下を使用して`sshd`デーモンを再起動します。

```text
sudo systemctl restart sshd.service
```

`/etc/ssh/sshd_config` ファイルを開きます。

```text
sudo nano /etc/ssh/sshd_config
```

**ChallengeResponseAuthentication**の項目を「yes」にします。

```text
ChallengeResponseAuthentication yes
```

**UsePAM**の項目を「yes」にします。

```text
UsePAM yes
```

最後の行に1行追加します。(SSH公開鍵秘密鍵ログインを利用の場合)

```text
AuthenticationMethods publickey,keyboard-interactive
```

ファイルを保存して閉じます。

以下を使用して`sshd`デーモンを再起動します。

```text
sudo systemctl restart sshd.service
```

**google-authenticator** コマンドを実行します。

```text
google-authenticator
```

いくつか質問事項が表示されます。推奨項目は以下のとおりです。

* Make tokens “time-base”": yes
* Update the `.google_authenticator` file: yes
* Disallow multiple uses: yes
* Increase the original generation time limit: no
* Enable rate-limiting: yes

プロセス中に大きなQRコードが表示されますが、その下には緊急時のスクラッチコードがひょうじされますので、忘れずに書き留めておいて下さい。

スマートフォンでGoogle認証システムアプリを開き、QRコードを読み取り2段階認証を機能させます。

## 🚀 参考文献

{% embed url="https://medium.com/@BaneBiddix/how-to-harden-your-ubuntu-18-04-server-ffc4b6658fe7" %}

{% embed url="https://linux-audit.com/ubuntu-server-hardening-guide-quick-and-secure/" %}

{% embed url="https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-18-04" %}

{% embed url="https://ubuntu.com/tutorials/configure-ssh-2fa\#1-overview" %}

[https://gist.github.com/lokhman/cc716d2e2d373dd696b2d9264c0287a3\#file-ubuntu-hardening-md](https://gist.github.com/lokhman/cc716d2e2d373dd696b2d9264c0287a3#file-ubuntu-hardening-md)

{% embed url="https://www.lifewire.com/harden-ubuntu-server-security-4178243" %}

{% embed url="https://www.ubuntupit.com/best-linux-hardening-security-tips-a-comprehensive-checklist/" %}

