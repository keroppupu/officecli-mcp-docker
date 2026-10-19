# OfficeCLI MCP SSE Docker Container (via Supergateway)

OfficeCLI (`officecli mcp`) を Supergateway 経由で SSE (Server-Sent Events) 対応 MCP サーバーとして起動・公開するための Docker 環境です。

## 特徴
- **マルチアーキテクチャ対応**: AMD64 (x86_64) および ARM64 (Apple Silicon, AWS Graviton 等) を自動判別して OfficeCLI バイナリをダウンロード
- **Supergateway 連携**: OfficeCLI の stdio (標準入出力) を SSE / HTTP プロトコルにブリッジ
- **GitLab Duo / OpenClaw / リモート AI クライアント対応**: 外部から HTTP/SSE 経由で Word / Excel / PowerPoint の操作が可能
- **CORS / ヘルスチェック対応**: ブラウザや WebUI 接続用の CORS、および `/healthz` 監視エンドポイントを標準搭載

---

## 起動方法

### A. RHEL / オフライン環境での起動（GitHub Releases 配布パッケージ）

GitHub Releases から `officecli-mcp-rhel-x86.tar.gz` と `start.sh` をダウンロードして同一ディレクトリに配置します。

```bash
chmod +x start.sh

# 初回起動
./start.sh
```
※ Docker または RHEL 標準の Podman を自動検出して起動します。

---

### B. Docker Compose を使用する場合（ソースからビルド）

```bash
# ビルド & 起動
docker compose up -d --build

# ログ確認
docker compose logs -f

# 停止
docker compose down
```

---

### C. Docker コマンドを直接使用する場合

```bash
# イメージのビルド
docker build -t officecli-mcp-sse .

# コンテナの起動
docker run -d \
  --name officecli-mcp-sse \
  -p 8010:8010 \
  -v $(pwd)/data:/data \
  --restart unless-stopped \
  officecli-mcp-sse
```

---

## イメージ・コンテナの入れ替え手順（アップデート方法）

古いバージョン（ver0.1 等）から最新バージョン（ver0.2 等）に入れ替える手順です。

### 1. `start.sh` を使用した入れ替え（推奨・簡単）

新しい `officecli-mcp-rhel-x86.tar.gz` と `start.sh` を作業ディレクトリに上書き配置し、`--reload` フラグを付けて実行します：

```bash
chmod +x start.sh

# 既存コンテナを自動停止し、新しいイメージを強制再ロードして起動
./start.sh --reload
```

---

### 2. 手動コマンドで入れ替える場合

古いイメージキャッシュやコンテナを明示的にクリアして入れ替える手順です：

```bash
# 1. 実行中のコンテナを停止・削除
docker rm -f officecli-mcp-sse 2>/dev/null || true
# （Podman の場合: podman rm -f officecli-mcp-sse 2>/dev/null || true）

# 2. 古いバージョンのイメージを削除（キャッシュの混入を防止）
docker rmi officecli-mcp-rhel-x86:latest officecli-mcp-rhel-x86:ver0.1 2>/dev/null || true

# 3. 新しいオフラインイメージ（tar.gz）を読み込み
docker load < officecli-mcp-rhel-x86.tar.gz

# 4. コンテナ内の Node.js バージョンが v22 であることを確認（TransformStream 対応）
docker run --rm officecli-mcp-rhel-x86:ver0.2 node -v

# 5. コンテナを起動
./start.sh
```

---

### 3. Docker Compose 環境での入れ替え

```bash
git pull origin main
docker compose down
docker compose up -d --build
```

---

## 動作確認

起動後、curl を使ってヘルスチェックおよび SSE エンドポイントに接続確認ができます：

```bash
# ヘルスチェック確認 ("ok" が返れば正常稼働)
curl http://localhost:8010/healthz

# SSE エンドポイント接続確認
curl -N -H "Accept: text/event-stream" http://localhost:8010/sse
```

---

## GitLab Duo / MCP クライアント設定例

### GitLab Duo (`~/.gitlab/duo/mcp.json`)

```json
{
  "mcpServers": {
    "officecli": {
      "type": "sse",
      "url": "http://<DockerホストのIPまたはドメイン>:8010/sse"
    }
  }
}
```

### OpenClaw

```bash
openclaw mcp add officecli --transport sse --url http://<ホスト>:8010/sse
```
