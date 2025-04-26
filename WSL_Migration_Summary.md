# Second-Me WSL移行サマリー

## ✅ 完了した変更点

### 1. スクリプトの修正

1. **setup.sh**
   - Mac固有のシェル構文 `${0:A}` を `${BASH_SOURCE[0]}` に置き換え
   - WSL環境検出機能を追加
   - Node.jsインストールをHomebrewから`apt`ベースに変更
   - グローバルnpmパッケージの権限問題を回避する設定を追加

2. **start_local.sh**
   - `ifconfig`コマンドの代わりに`ip`コマンドを使用するよう修正
   - WSL環境検出機能を追加
   - WSL環境に適したIPアドレス取得方法を追加

3. **conda_utils.sh**
   - WSL環境用のconda.sh検索パスを追加
   - 環境に応じたパス設定を追加

4. **start_wsl.sh および start_frontend_wsl.sh（新規作成）**
   - WSL環境専用の起動スクリプトを追加
   - ネットワーク設定とIPアドレス取得方法をWSL向けに最適化
   - Windowsホストとの連携機能を追加

5. **.env ファイル拡張**
   - WSL環境検出と設定を追加
   - プラットフォーム固有の環境変数を設定
   - パス設定をWSL環境に最適化

### 2. ドキュメント更新

1. **README.md**
   - WSL環境でのセットアップ手順を追加
   - WSL用の前提条件と初期設定手順を追加
   - WSL固有のコマンドを明記

2. **WSL_Migration_Roadmap.md**
   - WSL環境での使用手順を詳細に記載
   - 実装済みの項目に✅マークを追加
   - 追加考慮事項を明記

## 使用方法

### 重要: すべてのコマンドはWSL環境内で実行

まず、WSL環境に入ります：
```bash
wsl
```

### WSL環境でセットアップを実行

```bash
# WSLコンソールから実行
cd ~/Project/Second-Me

# スクリプトに実行権限を付与
chmod +x scripts/*.sh

# セットアップを実行
./scripts/setup.sh
```

### WSL環境でアプリケーションを起動

```bash
# WSL専用スクリプトでバックエンドを起動
./scripts/start_wsl.sh

# 別のWSLターミナルでフロントエンドを起動
./scripts/start_frontend_wsl.sh
```

### 代替起動方法

```bash
# 標準スクリプトでも起動可能（WSL検出機能があるため）
./scripts/start.sh

# フロントエンド
cd lpm_frontend
npm run dev
```

### Windowsからのアクセス方法

WSL内で実行しているサービスには、Windowsホストから次のアドレスでアクセスできます：

- バックエンド: http://localhost:8002
- フロントエンド: http://localhost:3000

## 注意事項

1. 全てのコマンドは必ずWSL環境内で実行してください。
2. パフォーマンスを向上させるために、プロジェクトファイルはWSLのネイティブファイルシステム内に配置することを推奨します。
3. WSL環境ではNode.jsやPythonのグローバルパッケージ権限に注意してください。

## 今後の課題

1. **Docker関連の設定**
   - WSL環境でのDockerボリュームパフォーマンスを向上させる設定

2. **WSLパフォーマンス最適化**
   - ファイルシステム間のI/O操作のパフォーマンス向上
   - メモリ使用量の最適化 