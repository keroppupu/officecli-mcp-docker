# OfficeCLI MCP SSE Docker Container (via Supergateway)

OfficeCLI (`officecli mcp`) を Supergateway 経由で SSE (Server-Sent Events) 対応 MCP サーバーとして起動・公開するための Docker 環境です。

## 特徴
- **マルチアーキテクチャ対応**: AMD64 (x86_64) および ARM64 (Apple Silicon, AWS Graviton 等) を自動判別して OfficeCLI バイナリをダウンロード
- **Supergateway 連携**: OfficeCLI の stdio (標準入出力) を SSE / HTTP プロトコルにブリッジ
- **GitLab Duo / リモート AI クライアント対応**: 外部から HTTP/SSE 経由で Word / Excel / PowerPoint の操作が可能

---

## 起動方法

### Docker Compose を使用する場合（推奨）

```bash
# ビルド & 起動
docker compose up -d --build

# ログ確認
docker compose logs -f

# 停止
docker compose down
```

### Docker コマンドを直接使用する場合

```bash
# イメージのビルド
docker build -t officecli-mcp-sse .

# コンテナの起動
docker run -d \
  --name officecli-mcp-sse \
  -p 8010:8010 \
  -v $(pwd)/data:/data \
  officecli-mcp-sse
```

---

## 動作確認

起動後、curl を使って SSE エンドポイントに接続できるか確認します：

```bash
curl -N -H "Accept: text/event-stream" http://localhost:8010/sse
```

接続が確立され、SSE の初期化イベント（またはセッション情報）が返ってくれば正常です。

---

## GitLab Duo などのクライアント設定例

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
