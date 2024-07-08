# esa-md-to-confluence

## 手順

### esa のファイルダウンロード

- [help/データのインポート・エクスポート - docs.esa.io](https://docs.esa.io/posts/11) を参考に esa の markdown ファイルを一括ダウンロード
- zip ファイルを任意の場所で展開

### 環境変数を設定

- 本リポジトリを clone
- `.env` ファイルを用意

```sh
cp env.sample .env
```

- Confluence の Host と User を `.env` で設定

```sh
CONFLUENCE_HOST=https://xxx.atlassian.net
CONFLUENCE_USER=xxx@example.com
```

- [Atlassian アカウントの API トークンを管理する | アトラシアン サポート](https://support.atlassian.com/ja/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/) を参考に API トークンを取得し環境変数を設定

```sh
CONFLUENCE_API_TOKEN=xxxxxxxx
```

- 移行先の Confluence の Space ID を取得
  - https://{移行先のサブドメイン}.atlassian.net/wiki/rest/api/space/{移行先のスペースキー} にアクセスし、レスポンスに含まれている id を環境変数に設定

```sh
CONFLUENCE_API_TOKEN=123456789
```

### 実行

ダウンロードして展開したフォルダを引数に指定して `main.rb` を実行。

```sh
ruby main.rb /path/to/yyyy-mm-dd_HH-MM-SS-xxx
```
