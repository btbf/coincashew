# poolMetaData.jsonをGithubにアップロードする方法

## poolMetaData.jsonをホストするクイックステップ

1.Githubアカウントを作成しログインします [https://github.com/](https://github.com/)  
2.右上の＋マークをクリックし**new repository** をクリックします。
3.**Repository name**に任意のリポジトリ名を入力し、**Create repository**をクリックします。
4.小さい文字で書かれた"**creating a new file**"をクリックします。

![](.gitbook/assets/git1.png)

5.ファイル名を **poolMetaData.json** として入力し **json** コンテンツを貼り付けます。

![](.gitbook/assets/git2.png)

6.**Commit new file**をクリックします。

![](.gitbook/assets/git3.png)

7.作成したファイルの名前をクリックします。

8.**Rawボタン**をクリックします。

9. 「https://raw」から始まるURLをコピーします。

> 例: [https://raw.githubusercontent.com/coincashew/test/master/poolMetaData.json](https://raw.githubusercontent.com/coincashew/test/master/poolMetaData.json)

10.URLは64文字より短くする必要があります。 [https://git.io/](https://git.io/) を使用してURLを短縮します。

11.9でコピーしたURLを貼り付けます。

12.短縮されたURLを`--metadata-url` に記述します。

> 例:  
> --metadata-url https://git.io/JUcnl


