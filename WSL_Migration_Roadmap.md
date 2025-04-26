# Second-Meプロジェクト WSL移行ロードマップ

## ⚠️ 最重要事項：WSL環境での実行 ⚠️

**重要**: このプロジェクトの全てのコマンドはWindows PowerShellではなく、WSL環境内で実行する必要があります。

### WSL環境へのアクセス方法

1. PowerShellやコマンドプロンプトから直接WSLを起動する:
   ```
   wsl
   ```

2. Windowsターミナルを使用している場合は、ドロップダウンメニューからUbuntuなどのWSL環境を選択

3. VSCodeを使用している場合は、ターミナルをWSLに切り替える:
   ```
   Terminal > New Terminal > ドロップダウンから「Ubuntu」などを選択
   ```

### WSL内でのプロジェクトディレクトリへのアクセス

WSL内からWindowsファイルシステムのプロジェクトにアクセスする場合:
```bash
cd /mnt/c/path/to/your/project
```

または、パフォーマンスを向上させるために、プロジェクトをWSLのファイルシステム内に配置することを強く推奨します:
```bash
# WSLのホームディレクトリなど
cd ~/Project/Second-Me
```

### スクリプト実行権限の確認と修正

WSL環境でスクリプトを実行する前に、実行権限を確認・付与する必要があります：

```bash
# スクリプトに実行権限を付与
chmod +x scripts/*.sh

# 実行権限を確認
ls -la scripts/
```

特にWindowsファイルシステム内にプロジェクトがある場合、WSLでは実行権限が自動的に設定されないことがあります。

**注意**: すべてのスクリプトとコマンドは必ずWSL環境内で実行してください。PowerShellで実行すると、環境の違いにより正常に動作しません。

---

## 問題点の概要

Second-Meプロジェクトは元々Mac向けに開発されており、WindowsのWSL環境で実行するためには以下の問題点を解決する必要があります。**終了した修正セクションには必ず✅️を付けていきます。**

### 1. パッケージ管理とインストール
- ✅️ **Homebrew依存**：セットアップスクリプトがHomebrewを使用（Mac固有のパッケージマネージャー）
- ✅️ **Node.jsインストール**：HomebrewでNode.jsをインストールしている
- ✅️ **パス設定**：Mac固有のパス（/opt/homebrew等）がハードコーディングされている

### 2. シェルスクリプトの互換性
- ✅️ **Mac固有の構文**：`${0:A}`などのMac固有のシェル構文を使用
- ✅️ **ifconfig**：`ifconfig`コマンドを使用してIPアドレスを取得（WSLでは異なる）
- ✅️ **シェルの違い**：Mac (.zshrc) と WSL (通常 .bashrc) の設定ファイルの違い

### 3. 環境設定とパス
- ✅️ **Conda環境**：Mac向けのパスが多数ハードコーディングされている
- ✅️ **ファイルパス**：Mac形式のパス区切り文字 (`/`) が使用されている
- ✅️ **環境変数**：Mac特有の環境変数が設定されている可能性がある

### 4. フロントエンド関連
- ✅️ **ポート設定**：ローカルホストとの接続ポート設定の違い
- ✅️ **NPMパッケージ**：プラットフォーム固有のNPMパッケージがある可能性

### 5. Docker関連
- **Docker設定**：Docker for Mac と Docker for Windows の違いによる問題

## 修正のロードマップ

**終了した修正セクションには必ず✅️を付けていきます。**

### Phase 1: セットアップスクリプトの修正

#### 1.1 Homebrew依存の排除
✅️ done
```bash
# setup.sh の修正

# 既存のHomebrew確認コード
if command -v brew &>/dev/null; then
  log_info "Homebrew is installed"
else
  log_warning "Homebrew is not installed, attempting to install it automatically..."
  # ...
fi

# 修正後のWSL環境向けコード
# WSL環境を明示的に検出
if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
  log_info "WSL環境を検出しました。aptを使用してパッケージをインストールします。"
  
  # 必要なパッケージのインストール
  sudo apt-get update
  sudo apt-get install -y build-essential curl file git sqlite3 python3-pip python3-venv
  
  # Node.jsの最新バージョンインストール（Ubuntuのデフォルトリポジトリは古いバージョンのため）
  if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
    log_info "Node.jsとnpmの最新バージョンをインストールします"
    # 最新のNode.jsリポジトリを追加
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
  fi
  
  # WSL環境で必要な追加ツール
  log_info "WSL環境用の追加ツールをインストールします"
  sudo apt-get install -y python3-dev
else
  # Macの場合はHomebrewを使用（既存コードを保持）
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      log_info "Homebrew is installed"
    else
      log_warning "Homebrew is not installed, attempting to install it automatically..."
      # Mac用のHomebrew installスクリプト
    fi
  else
    # その他のLinux環境
    log_info "Linux環境を検出しました。システムパッケージマネージャーを使用します。"
    if command -v apt-get &>/dev/null; then
      sudo apt-get update
      sudo apt-get install -y build-essential curl file git
    elif command -v yum &>/dev/null; then
      sudo yum groupinstall 'Development Tools'
      sudo yum install -y curl file git
    fi
  fi
fi
```

#### 1.2 Node.jsインストールの修正
✅️ done
```bash
# setup.sh の修正

# 既存のNode.jsインストールコード（Homebrew使用）
if ! command -v npm &>/dev/null; then
  log_warning "npm not found - installing Node.js and npm"
  if ! brew install node; then
    log_error "Failed to install Node.js and npm"
    return 1
  fi
  # ...
fi

# 修正後のWSL環境向けコード
# WSL環境での Node.js インストール
if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
  if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
    log_warning "node/npm not found in WSL - installing Node.js LTS version"
    
    # Node.jsの最新LTSバージョンをインストール
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    if ! sudo apt-get install -y nodejs; then
      log_error "Failed to install Node.js via apt"
      return 1
    fi
    
    # npm バージョンを確認
    npm_version=$(npm --version)
    log_info "Installed npm version: $npm_version"
    
    # グローバルパッケージをインストールするときの権限エラーを回避するための設定
    mkdir -p ~/.npm-global
    npm config set prefix '~/.npm-global'
    
    # 環境変数の設定を.bashrcに追加（まだなければ）
    if ! grep -q "NPM_CONFIG_PREFIX" ~/.bashrc; then
      echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
      source ~/.bashrc
    fi
    
    log_success "Node.js と npm のインストールが完了しました"
  else
    node_version=$(node --version)
    npm_version=$(npm --version)
    log_info "Node.js ($node_version) と npm ($npm_version) は既にインストールされています"
  fi
else
  # Mac環境用のコード（既存のコードを保持）
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v npm &>/dev/null; then
      log_warning "npm not found - installing Node.js and npm"
      if ! brew install node; then
        log_error "Failed to install Node.js and npm"
        return 1
      fi
    fi
  else
    # その他のLinux環境
    if ! command -v npm &>/dev/null; then
      if command -v apt-get &>/dev/null; then
        sudo apt-get install -y nodejs npm
      elif command -v yum &>/dev/null; then
        sudo yum install -y nodejs npm
      else
        log_error "Unsupported package manager. Please install Node.js manually."
        return 1
      fi
    fi
  fi
fi

# 共通の確認コード
if ! command -v npm &>/dev/null; then
  log_error "npm installation failed - command not found after installation"
  return 1
fi
log_success "Node.js and npm are available"
```

#### 1.3 シェル構文の修正
✅️ done
```bash
# setup.sh と その他シェルスクリプトの修正

# 既存の Mac固有のシェル構文
SCRIPT_DIR="$( cd "$( dirname "${0:A}" )" && pwd )"

# クロスプラットフォーム対応版
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
```

### Phase 2: ネットワーク関連の修正

#### 2.1 ifconfigコマンドの置き換え
✅️ done
```bash
# start_local.sh の修正

# 既存のMac向けコード
LOCAL_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | grep "192.168" | awk '{print $2}' | head -n 1)

# WSL環境向けの修正コード - ifconfigは使用せず直接ipコマンドを使用
if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
  # WSL環境では通常ip コマンドが利用可能
  echo "WSL環境を検出しました。WSL用のIPアドレス取得方法を使用します。"
  
  # プライマリネットワークインターフェースのIPアドレスを取得
  LOCAL_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1)
  
  # 上記の方法で取得できない場合は hostname -I を試す
  if [ -z "$LOCAL_IP" ]; then
    echo "ipコマンドでの取得に失敗しました。hostname -I を使用します。"
    LOCAL_IP=$(hostname -I | awk '{print $1}')
  fi
  
  # WSLからホストWindowsシステムへのアクセス方法も表示
  WINDOWS_HOST_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
  echo "WSLからWindowsホストへのアクセス: http://${WINDOWS_HOST_IP}:${LOCAL_APP_PORT}"
  
  # さらにWindowsからWSLへのアクセス方法も表示
  echo "WindowsからWSLへのアクセス: http://localhost:${LOCAL_APP_PORT}"
else
  # Mac環境用のコード
  LOCAL_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | grep "192.168" | awk '{print $2}' | head -n 1)
fi

echo "使用するIPアドレス: $LOCAL_IP"
```

### Phase 3: Conda環境設定の修正

#### 3.1 conda_utils.sh のパス修正
✅️ done
```bash
# conda_utils.sh の修正

# 既存のMac固有のパス設定
local conda_sh_paths=(
    "$HOME/anaconda3/etc/profile.d/conda.sh"
    "$HOME/miniconda3/etc/profile.d/conda.sh"
    # ... その他のMacパス
    "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    # ... 
)

# WSL専用のパス設定に変更
if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
  log_info "WSL環境向けのConda検索パスを設定します"
  
  # WSL環境ではLinux標準のパスのみを使用
  local conda_sh_paths=(
      # WSL/Linuxの標準インストールパス
      "$HOME/anaconda3/etc/profile.d/conda.sh"
      "$HOME/miniconda3/etc/profile.d/conda.sh"
      "/opt/anaconda3/etc/profile.d/conda.sh"
      "/opt/miniconda3/etc/profile.d/conda.sh"
      "/usr/local/anaconda3/etc/profile.d/conda.sh"
      "/usr/local/miniconda3/etc/profile.d/conda.sh"
  )
else
  # Mac環境では既存のパスを使用
  local conda_sh_paths=(
      # Mac標準のパス
      "$HOME/anaconda3/etc/profile.d/conda.sh"
      "$HOME/miniconda3/etc/profile.d/conda.sh"
      "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
      # ... その他のMacパス
  )
fi
```

#### 3.2 WSL環境専用のConda初期化処理
✅️ done
```bash
# conda_utils.sh に追加

# WSL環境用のConda初期化関数
init_conda_wsl() {
  log_info "WSL環境用のConda初期化を実行します"
  
  # WSL環境ではminiforge/mambaforgeを使用した初期化を推奨
  if ! command -v conda &>/dev/null; then
    log_warning "Condaが見つかりません。Miniforgeをインストールします。"
    
    # Miniforgeのインストール（Mambaを含む、より高速なConda代替）
    MINIFORGE_PATH="$HOME/miniforge3"
    MINIFORGE_INSTALLER="/tmp/miniforge_installer.sh"
    
    # WSL用のMiniforgeインストーラーをダウンロード
    curl -L https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o $MINIFORGE_INSTALLER
    
    # インストーラーの実行
    bash $MINIFORGE_INSTALLER -b -p $MINIFORGE_PATH
    
    # PATHに追加
    export PATH="$MINIFORGE_PATH/bin:$PATH"
    
    # .bashrcに追加（WSLはデフォルトではbashを使用）
    echo '# Miniforge (conda) 設定' >> $HOME/.bashrc
    echo "export PATH=\"$MINIFORGE_PATH/bin:\$PATH\"" >> $HOME/.bashrc
    echo 'eval "$(conda shell.bash hook)"' >> $HOME/.bashrc
    
    # 確認
    if command -v conda &>/dev/null; then
      log_success "Miniforgeのインストールに成功しました"
      
      # conda-forge をデフォルトチャンネルに設定
      conda config --add channels conda-forge
      conda config --set channel_priority strict
      
      # mamba (高速conda代替) が使用可能か確認
      if command -v mamba &>/dev/null; then
        log_success "mamba も使用可能です（高速なconda代替）"
      fi
    else
      log_error "Miniforgeのインストールに失敗しました"
      return 1
    fi
  else
    log_success "conda がすでにインストールされています: $(which conda)"
    conda --version
  fi
  
  # conda環境を作成または更新
  log_info "Second-Me用のconda環境を設定します"
  
  # 環境名を取得
  local env_name=$(get_conda_env_name)
  
  # 環境が存在するか確認
  if conda env list | grep -q "^$env_name "; then
    log_info "既存の conda 環境 '$env_name' が見つかりました"
  else
    log_info "conda 環境 '$env_name' を作成します"
    
    # 高速化のためにmambaを使用（利用可能な場合）
    if command -v mamba &>/dev/null; then
      mamba env create -f environment.yml -n $env_name
    else
      conda env create -f environment.yml -n $env_name
    fi
    
    if [ $? -ne 0 ]; then
      log_error "conda環境の作成に失敗しました"
      return 1
    fi
  fi
  
  # 環境をアクティブ化
  log_info "conda環境 '$env_name' をアクティブ化します"
  conda activate $env_name
  
  return 0
}

# プラットフォーム検出と初期化関数選択
init_conda_environment() {
  if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
    # WSL環境の場合
    init_conda_wsl
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSの場合
    init_conda_mac
  else
    # その他のLinux環境
    init_conda_linux
  fi
}
```

### Phase 4: 環境変数設定の修正

#### 4.1 .env ファイルの拡張
✅️ done
```bash
# .env ファイルに追加する内容

# WSL環境専用の設定
# このコードを.envファイルの先頭に追加

# WSL環境検出
if grep -q "Microsoft" /proc/version 2>/dev/null || grep -q "WSL" /proc/version 2>/dev/null; then
  # WSL環境向けの設定
  export PLATFORM="wsl"
  
  # WSL環境変数設定
  # WSLでのベースディレクトリパスを設定
  WSL_BASE_DIR="/home/$(whoami)/Project/Second-Me"
  LOCAL_BASE_DIR=$WSL_BASE_DIR
  
  # WSL環境での絶対パス
  export BASE_DIR=$WSL_BASE_DIR
  
  # WSL用のログディレクトリ
  LOCAL_LOG_DIR="$WSL_BASE_DIR/logs"
  
  # IPアドレス取得コマンド（ifconfigではなくipコマンド）
  NETWORK_INTERFACE_COMMAND="ip -4 addr show"
  
  # WSL特有のパス
  export PATH="$HOME/.local/bin:$PATH"
  
  # Pythonのバイナリキャッシュをオフにするとパフォーマンスが向上することがある
  export PYTHONDONTWRITEBYTECODE=1
  
  # WSL内でのNode.js環境
  export NODE_ENV=development
  
  # デフォルトのブラウザ設定（WSLでの開発時）
  export BROWSER="wslview"
  
  # クリップボード連携（可能な場合）
  if command -v clip.exe &>/dev/null; then
    export CLIPBOARD_COMMAND="clip.exe"
  fi
  
  echo "WSL環境が検出されました。WSL固有の設定を適用します。"
else
  # Mac/その他環境用の設定（変更しない）
  if [[ "$OSTYPE" == "darwin"* ]]; then
    export PLATFORM="mac"
  else
    export PLATFORM="linux"
  fi
fi
```

#### 4.2 WSL環境での.bashrcの設定
✅️ done
```bash
# WSL環境では通常.bashrcが使用される
# 以下の設定をWSL環境の.bashrcファイルに追加

# WSL用の環境設定を.bashrcに追加
cat << 'EOF' >> $HOME/.bashrc

# Second-Me WSL環境設定
if [ -f "$HOME/Project/Second-Me/.env" ]; then
  set -a
  source "$HOME/Project/Second-Me/.env"
  set +a
  
  # WSL環境向けのエイリアス
  alias cdproj="cd $HOME/Project/Second-Me"
  alias startapp="cd $HOME/Project/Second-Me && bash scripts/start_wsl.sh"
  alias startfrontend="cd $HOME/Project/Second-Me/lpm_frontend && npm run dev"
  
  # WSLとWindows間の連携用エイリアス
  alias open="wslview"
  alias explorer="explorer.exe"
  
  echo "Second-Me環境変数とエイリアスが読み込まれました。"
  echo "- cdproj: プロジェクトディレクトリに移動"
  echo "- startapp: バックエンドを起動"
  echo "- startfrontend: フロントエンドを起動"
fi
EOF

# .bashrcを再読み込み
source $HOME/.bashrc
```

### Phase 5: 実行スクリプトの修正

#### 5.1 WSL用の起動スクリプト作成
✅️ done
ファイル名: `scripts/start_wsl.sh`
```bash
#!/bin/bash

# Second-Me WSL向け起動スクリプト

# スクリプトが中断された場合に一時ファイルを削除するためのクリーンアップ関数
cleanup() {
  echo "スクリプトを終了しています..."
  # 必要に応じてクリーンアップ処理を追加
  exit 0
}

# Ctrl+C で正常にクリーンアップするためのトラップ
trap cleanup SIGINT

# Windows側からWSLへのアクセス方法を表示する関数
show_access_info() {
  echo -e "\n===== アクセス情報 ====="
  echo "- Windows側からのアクセス: http://localhost:${LOCAL_APP_PORT}"
  echo "- WSL内からのアクセス: http://127.0.0.1:${LOCAL_APP_PORT}"
  
  # ブラウザを自動的に開くオプション
  if [[ "$AUTO_OPEN_BROWSER" == "true" ]]; then
    echo "ブラウザを自動的に開きます..."
    if command -v wslview &>/dev/null; then
      wslview "http://localhost:${LOCAL_APP_PORT}"
    elif command -v explorer.exe &>/dev/null; then
      explorer.exe "http://localhost:${LOCAL_APP_PORT}"
    fi
  fi
}

# 環境変数設定
echo "環境変数を設定しています..."
export PYTHONPATH=$(pwd):${PYTHONPATH}

# .env ファイルから環境変数を読み込む
echo ".env ファイルを読み込んでいます..."
set -a
source .env
set +a

# WSL環境を確認
if ! grep -q "Microsoft" /proc/version && ! grep -q "WSL" /proc/version; then
  echo "警告: WSL環境ではありません。このスクリプトはWSL環境用に設計されています。"
  read -p "続行しますか？ (y/n): " continue_anyway
  if [[ "$continue_anyway" != "y" ]]; then
    echo "スクリプトを終了します。"
    exit 1
  fi
fi

# ローカルベースディレクトリを使用
echo "ベースディレクトリ: ${LOCAL_BASE_DIR}"
export BASE_DIR=${LOCAL_BASE_DIR}

# 正しいPython環境を使用していることを確認
echo "Python環境を確認しています..."
PYTHON_PATH=$(which python)
echo "使用するPython: $PYTHON_PATH"
PYTHON_VERSION=$(python --version)
echo "Pythonバージョン: $PYTHON_VERSION"
CONDA_ENV=$(echo $CONDA_DEFAULT_ENV)
echo "Conda環境: $CONDA_ENV"

# 必要なPythonパッケージの確認
echo "必要なPythonパッケージを確認しています..."
python -c "import flask" || { echo "エラー: flaskパッケージがインストールされていません"; exit 1; }
python -c "import chromadb" || { echo "エラー: chromadbパッケージがインストールされていません"; exit 1; }

# データベース初期化
echo "データベースを初期化しています..."
SQLITE_DB_PATH="${BASE_DIR}/data/sqlite/lpm.db"
mkdir -p "${BASE_DIR}/data/sqlite"

if [ ! -f "$SQLITE_DB_PATH" ]; then
    echo "新しいデータベースを初期化しています..."
    cat docker/sqlite/init.sql | sqlite3 "$SQLITE_DB_PATH"
    
    # デフォルト設定を適用
    python -c "from lpm_kernel.api.services.config_service import ConfigService; ConfigService().ensure_default_configs()"
    
    echo "データベース初期化が完了しました"
else
    echo "既存のデータベースが見つかりました"
fi

# 必要なディレクトリの作成
echo "必要なディレクトリを確認しています..."
mkdir -p ${BASE_DIR}/data/chroma_db
mkdir -p ${LOCAL_LOG_DIR}

# ChromaDBの初期化
echo "ChromaDBを初期化しています..."
python docker/app/init_chroma.py

# WSL特有のIPアドレス取得方法
echo "ネットワーク情報を取得しています..."
LOCAL_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1)
if [ -z "$LOCAL_IP" ]; then
    echo "ipコマンドでIPアドレスを取得できませんでした。hostname -Iを使用します..."
    LOCAL_IP=$(hostname -I | awk '{print $1}')
fi

# Windowsホストのアドレスを取得
WINDOWS_HOST_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')

# Flaskアプリケーションを起動
echo "Flaskアプリケーションを起動しています..."
echo "アプリケーションは以下のアドレスで実行されます:"
echo "- Windowsからのアクセス: http://localhost:${LOCAL_APP_PORT}"
echo "- WSL内からのアクセス: http://127.0.0.1:${LOCAL_APP_PORT}"
echo "- WSL IPアドレス: http://${LOCAL_IP}:${LOCAL_APP_PORT}"
echo "- Windowsホスト: http://${WINDOWS_HOST_IP}:${LOCAL_APP_PORT}"

# アクセス情報表示
show_access_info

# ログファイルへの出力
echo "ログは ${LOCAL_LOG_DIR}/backend.log に記録されます"
exec python -m flask run --host=0.0.0.0 --port=${LOCAL_APP_PORT} >> "${LOCAL_LOG_DIR}/backend.log" 2>&1
```

#### 5.2 フロントエンド起動スクリプトの作成
✅️ done
ファイル名: `scripts/start_frontend_wsl.sh`
```bash
#!/bin/bash

# Second-Me WSL向けフロントエンド起動スクリプト

# フロントエンドディレクトリに移動
cd lpm_frontend || { echo "フロントエンドディレクトリが見つかりません"; exit 1; }

# 環境変数を読み込む
echo "環境変数を読み込んでいます..."
set -a
source ../.env
set +a

# 依存関係が最新かどうか確認
echo "npm依存関係を確認しています..."
npm install

# フロントエンドアプリケーションを起動
echo "フロントエンドアプリケーションを起動しています..."
echo "フロントエンドは以下のアドレスで実行されます:"
echo "- Windows側からのアクセス: http://localhost:${LOCAL_FRONTEND_PORT}"

# 開発サーバーを起動
exec npm run dev
```

### Phase 6: Docker設定の修正

#### 6.1 WSL用Dockerコマンド対応
```bash
# Docker関連スクリプトの修正

# WSL環境向けのDockerコマンド
if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
  echo "WSL環境を検出しました。WSL用のDocker設定を使用します。"
  
  # Docker Desktop for Windowsが実行されているか確認
  if ! command -v docker &>/dev/null || ! docker info &>/dev/null; then
    echo "エラー: Docker Desktop for Windowsが実行されていないか、WSLと統合されていません。"
    echo "Docker Desktop for Windowsをインストールし、以下の設定を有効にしてください:"
    echo "- 'Settings > Resources > WSL Integration > Enable integration with my default WSL distro'"
    exit 1
  fi
  
  # WSL2かWSL1かを確認
  if grep -q "WSL2" /proc/version; then
    echo "WSL2を検出しました。標準のLinuxパスを使用します。"
    DOCKER_MOUNT_PATH=${BASE_DIR}
    
    # WSL2ではLinuxパスをそのまま使用可能
    docker run \
      -v "${DOCKER_MOUNT_PATH}:/app" \
      -p ${LOCAL_APP_PORT}:${APP_PORT} \
      --name second-me-app \
      second-me-app:latest
  else
    echo "WSL1を検出しました。パス変換が必要です。"
    # WSL1の場合はWindowsパスに変換が必要
    DOCKER_MOUNT_PATH=$(wslpath -w ${BASE_DIR})
    
    # Windows形式のパスを使用
    docker run \
      -v "${DOCKER_MOUNT_PATH}:/app" \
      -p ${LOCAL_APP_PORT}:${APP_PORT} \
      --name second-me-app \
      second-me-app:latest
  fi
else
  # 通常のLinuxやMacの場合
  DOCKER_MOUNT_PATH=${BASE_DIR}
  docker run \
    -v "${DOCKER_MOUNT_PATH}:/app" \
    -p ${LOCAL_APP_PORT}:${APP_PORT} \
    --name second-me-app \
    second-me-app:latest
fi
```

#### 6.2 WSL環境でのDockerボリュームパフォーマンス向上
```bash
# WSL環境でのDockerボリュームパフォーマンスを向上させるための設定

# 必要なディレクトリを作成
mkdir -p ${BASE_DIR}/.docker-conf

# WSL用のDocker設定ファイルを作成
cat > ${BASE_DIR}/.docker-conf/docker-compose.override.yml << EOF
version: '3'

services:
  app:
    volumes:
      # WSL環境でのパフォーマンス向上のためのボリューム設定
      - type: bind
        source: ${BASE_DIR}
        target: /app
        consistency: cached

      # node_modulesをボリュームマウントして高速化
      - node_modules:/app/lpm_frontend/node_modules

volumes:
  node_modules:
EOF

echo "WSL用のDockerボリューム設定が完了しました"
```

### Phase 7: テストとデバッグ

#### 7.1 WSL環境での環境設定テスト
1. WSL環境でセットアップスクリプトを実行
   ```bash
   # WSLコンソールで実行
   cd ~/Project/Second-Me
   # まず実行権限を付与
   chmod +x scripts/*.sh
   # セットアップを実行
   bash scripts/setup.sh
   ```

2. Conda環境が正しく作成されたか確認
   ```bash
   # WSLコンソールで実行
   conda env list
   conda activate second-me
   ```

#### 7.2 WSL専用バックエンド起動テスト
```bash
# WSLコンソールで実行
cd ~/Project/Second-Me
bash scripts/start_wsl.sh
```

#### 7.3 WSL環境でのフロントエンド起動テスト
```bash
# 別のWSLコンソールで実行
cd ~/Project/Second-Me
bash scripts/start_frontend_wsl.sh
```

#### 7.4 WSL環境での統合テスト
1. WindowsブラウザからのWSLサービスへの接続確認
   ```
   http://localhost:8002  # バックエンド
   http://localhost:3000  # フロントエンド
   ```

2. WSL内からのサービス接続確認
   ```
   curl http://127.0.0.1:8002  # バックエンドAPIをテスト
   ```

3. WSL固有の環境変数が正しく設定されていることを確認
   ```bash
   echo $PLATFORM  # "wsl"と表示されるはず
   ```

## 追加考慮事項

### 1. WSLとWindowsのファイルシステム連携
WSLからWindowsファイルシステムへのアクセスと、Windowsファイルシステムからのアクセスの両方が可能です。

- **WSLからWindowsへのアクセス**:
  ```bash
  # CドライブにアクセスするWin Path
  cd /mnt/c/
  ```

- **WindowsからWSLへのアクセス**:
  ```powershell
  # PowerShellからWSLファイルシステムへアクセス
  \\wsl$\Ubuntu-22.04\home\username\Project\Second-Me
  ```

### 2. パフォーマンスを考慮したファイル配置
WSL2のパフォーマンスを最大化するためには、プロジェクトファイルをWindowsファイルシステム（/mnt/c/）ではなく、WSLのネイティブファイルシステム（/home/username/）に配置することを強く推奨します。

### 3. WSL環境でのファイルパーミッション
Windowsファイルシステム上のファイルをWSLから実行する場合、実行権限の問題が発生することがあります。

```bash
# スクリプトに実行権限を付与
chmod +x scripts/*.sh
```

WSLのネイティブファイルシステムでは通常のLinuxと同様のパーミッション管理が可能です。

### 4. WSL内からWindowsアプリケーションの起動
WSL内からWindowsのアプリケーションを直接起動できます。

```bash
# Windows側のブラウザでURLを開く
explorer.exe "http://localhost:3000"

# ファイルエクスプローラーを開く
explorer.exe .
```

### 5. ポート転送
WSL2ではWindowsホストからWSLへのポート転送が自動的に設定されるため、通常は `localhost:PORT` でWSL内のサービスにアクセスできます。WSL1では追加の設定が必要なことがあります。

### 6. WSL固有のパフォーマンス最適化

- **WSL2のメモリ使用量制限**:
  ```
  # .wslconfigファイルを作成（Windowsのユーザーホームディレクトリに）
  notepad.exe 'C:\Users\<username>\.wslconfig'
  ```
  
  以下の内容を追加:
  ```
  [wsl2]
  memory=6GB
  processors=4
  ```

- **I/O パフォーマンスの最適化**:
  クロスファイルシステムの操作（/mnt/cなど）はパフォーマンスが低下するため、WSLネイティブファイルシステムを使用しましょう。 