## Dify 1.0 Plugin Offline Repackaging

将 Dify 插件打包为离线包，使其可在无网络环境中安装。

### 环境要求

- **OS**: Linux amd64/aarch64, macOS x86_64/arm64（不支持原生 Windows，WSL 可用）
- **Python**: 3.12.x（需与 `dify-plugin-daemon` 版本一致）
- **依赖**: `curl`, `unzip`, `pip`

### 使用方式

#### 1. 本地运行

```bash
git clone https://github.com/yemmmm/dify-plugin-repackaging.git
cd dify-plugin-repackaging

# 下载最新版本并打包
./repack.sh https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible

# 指定版本
./repack.sh https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible 0.0.9

# 打包 ARM 平台
./repack.sh https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible --arm
```

#### 2. GitHub Actions

Fork 本仓库后，手动触发 workflow，填入：
- **plugin_url**（必选）: 插件商城 URL，如 `https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible`
- **plugin_version**（可选）: 留空则自动下载最新版本
- **platform_arm**（可选）: 是否打包 ARM 平台

构建完成后下载 artifact 即可。

#### 3. Docker

```bash
docker build -t dify-plugin-repackaging .
docker run -v $(pwd):/app dify-plugin-repackaging ./repack.sh https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible
```

### 其他命令

```shell
# 从商城按 author/name/version 下载
./plugin_repackaging.sh market langgenius agent 0.0.9

# 从 GitHub Release 下载
./plugin_repackaging.sh github junjiem/dify-plugin-agent-mcp_sse 0.0.1 agent-mcp_see.difypkg

# 本地 difypkg 重新打包
./plugin_repackaging.sh local ./db_query.difypkg

# 跨平台打包（-p 指定目标平台）
./plugin_repackaging.sh -p manylinux2014_aarch64 url https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible
```

### Dify 平台配置

在 `.env` 中修改以下配置以支持离线插件安装：

```
FORCE_VERIFYING_SIGNATURE=false
PLUGIN_MAX_PACKAGE_SIZE=524288000
NGINX_CLIENT_MAX_BODY_SIZE=500M
```

然后通过 Dify 插件管理页面 → **本地插件** 完成安装。
