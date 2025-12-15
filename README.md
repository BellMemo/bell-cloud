# Bell Cloud 🎐

> 随风而动的云端记忆。
> The backend storage service for Bell Memo.

Bell Cloud 是 [Bell Memo](https://github.com/yourname/bell-memo) 的官方服务端解决方案。它基于 [Alist](https://github.com/alist-org/alist) 构建，提供标准化的 WebDAV 接口，支持将备忘录数据存储在本地服务器、阿里云盘、AWS S3 等多种介质中。

## ✨ 特性

- **多源聚合**：支持挂载本地硬盘、NAS、各大网盘（阿里云盘/百度/Google Drive）。
- **标准协议**：通过 WebDAV 与 Bell Memo 客户端无缝同步。
- **即时预览**：在浏览器端直接查看 Markdown 格式的备忘录内容。
- **隐私优先**：数据掌握在自己手中，支持私有化部署。

## 🚀 快速部署

### 前置要求

- **Docker** 和 **Docker Compose**（V2 推荐）
- **Docker 权限**：确保当前用户有权限访问 Docker daemon

如果遇到 `permission denied while trying to connect to the Docker daemon socket` 错误，请执行：

```bash
# 将当前用户添加到 docker 组（推荐）
sudo usermod -aG docker $USER

# 重新登录或运行以下命令使组权限生效
newgrp docker
```

或者使用 `sudo` 运行 Docker 命令（不推荐，但可以临时使用）。

---

### 方式一：一键安装（推荐）

使用以下命令一键安装并初始化 Bell Cloud：

```bash
curl -fsSL https://raw.githubusercontent.com/BellMemo/bell-cloud/main/install.sh | bash
```

或者指定安装目录：

```bash
curl -fsSL https://raw.githubusercontent.com/BellMemo/bell-cloud/main/install.sh | bash -s my-bell-cloud
```

安装脚本会自动：
- 检查 Docker 和 Docker Compose 是否已安装
- 创建项目目录并生成配置文件
- 提示你运行初始化脚本

---

### 方式二：手动部署

如果你已经克隆了仓库，可以手动部署：

#### 1. 启动服务与初始化

我们提供了一个脚本 `init.sh`，它可以自动启动 Docker 容器、设置随机密码、并自动挂载存储目录。

```bash
# 1. 赋予脚本执行权限
chmod +x init.sh

# 2. 运行初始化脚本
./init.sh
```

脚本运行结束后，会显示如下信息：
*   Alist 访问地址
*   管理员账号 (`admin`)
*   自动生成的**管理员密码**（请妥善保存）

#### 2. 手动操作（可选）

如果你不想使用自动化脚本，也可以手动操作：

1.  **启动容器**：
    ```bash
    docker compose up -d
    ```
2.  **查看/设置密码**：
    ```bash
    docker logs bell-cloud
    # 或手动设置
    docker exec -it bell-cloud ./alist admin set YOUR_PASSWORD
    ```
3.  **配置存储**：
    访问 `http://localhost:5244`，登录后手动添加 Local 存储（参考下文“服务端配置指南”）。

---

## ⚙️ 服务端配置指南

### WebDAV 启用说明

**好消息**：Alist 默认已启用 WebDAV 服务，无需额外配置！

WebDAV 访问地址格式：
```
http://your-server:5244/dav
```

⚠️ **重要**：路径必须以 `/dav` 结尾。

---

### 配置存储（如果使用 init.sh 可跳过）

如果你使用了 `init.sh` 脚本，存储已经自动配置好了，可以跳过此步骤。

如果手动部署，请按以下步骤配置：

1.  登录 Alist 管理后台 (`http://your-server:5244`)。
2.  进入 **存储 (Storages)** -> **添加 (Add)**。
3.  驱动选择 **本机存储 (Local)**（或其他网盘）。
4.  **挂载路径 (Mount Path)**: `/BellMemo` 
    *   ⚠️ **注意**：此路径必须为 `/BellMemo`，客户端默认会识别此路径。
5.  **根文件夹路径 (Root Folder Path)**: `/mnt/local` 
    *   ⚠️ **⚠️ 重要提示**：此路径**必须**填写 `/mnt/local`，不能填写其他路径！
    *   **原因**：在 `docker-compose.yml` 中，我们将宿主机的 `./storage` 目录挂载到了容器内的 `/mnt/local`：
      ```yaml
      volumes:
        - './storage:/mnt/local'  # 宿主机路径:容器内路径
      ```
    *   如果你填写了错误的路径（如 `/storage`、`/mnt/storage` 等），Alist 将无法找到文件，导致上传失败或文件丢失。
    *   **映射关系**：
      - 容器内路径：`/mnt/local` ← 在 Alist 后台填写这个
      - 宿主机路径：`./storage`（即项目目录下的 `storage` 文件夹）
6.  保存。

现在，所有上传到 Bell Cloud 的文件，都会实际存储在宿主机的 `bell-cloud/storage` 目录下。

#### 常见错误

❌ **错误示例**：
- 根文件夹路径填写 `/storage` → 容器内不存在此路径，会报错
- 根文件夹路径填写 `/mnt/storage` → 容器内不存在此路径，会报错
- 根文件夹路径填写 `./storage` → Alist 不支持相对路径，会报错

✅ **正确配置**：
- 根文件夹路径填写 `/mnt/local` → 正确！对应 docker-compose.yml 中的挂载点

---

### 检查 WebDAV 用户权限

默认情况下，`admin` 用户已经拥有完整的 WebDAV 权限。如果你创建了新用户，需要确保用户有以下权限：

1.  登录 Alist 管理后台。
2.  进入 **用户 (Users)** -> 选择要使用的用户。
3.  确保以下权限已启用：
    - ✅ **Webdav Read**：允许通过 WebDAV 读取文件
    - ✅ **Webdav Manage**：允许通过 WebDAV 管理文件（上传、删除、重命名等）
    - ✅ **Read**：基本读取权限
    - ✅ **Write**：基本写入权限（如果需要上传文件）

**注意**：`init.sh` 脚本创建的 `admin` 用户默认拥有所有权限，无需手动配置。

---

## 📱 客户端连接配置

### 验证 WebDAV 是否正常工作

在配置客户端之前，建议先验证 WebDAV 服务是否正常：

#### 方法一：使用 curl 测试（推荐）

```bash
# 测试 WebDAV 连接（替换为你的服务器地址和密码）
curl -X PROPFIND http://your-server:5244/dav \
  -u admin:your_password \
  -H "Depth: 1"

# 如果返回 XML 格式的文件列表，说明 WebDAV 正常工作
# 示例输出：
# <?xml version="1.0" encoding="UTF-8"?>
# <multistatus xmlns="DAV:">
#   <response>...</response>
# </multistatus>
```

#### 方法二：使用浏览器测试

1. 打开浏览器，访问：`http://your-server:5244/dav`
2. 输入用户名 `admin` 和密码
3. 如果能看到文件列表或提示输入认证信息，说明 WebDAV 已启用

#### 方法三：使用图形化工具测试

- **Windows**: [RaiDrive](https://www.raidrive.com/) - 免费，支持 WebDAV 挂载
- **macOS**: [Cyberduck](https://cyberduck.io/) 或 [Mountain Duck](https://mountainduck.io/)
- **Linux**: 使用 `davfs2` 挂载

如果测试失败，请参考下文的"常见问题排查"部分。

---

### 获取连接信息

部署完成后，你需要以下信息来配置客户端：

1. **服务器地址**：
   - **本地访问**：`http://localhost:5244/dav`
   - **局域网访问**：`http://服务器内网IP:5244/dav`
   - **公网访问**：`http://服务器公网IP:5244/dav` 或 `http://你的域名:5244/dav`
   
   ⚠️ **重要**：Alist 的 WebDAV 路径必须以 `/dav` 结尾。

2. **用户名**：`admin`

3. **密码**：运行 `init.sh` 时显示的管理员密码（或你手动设置的密码）

4. **同步目录**：`/BellMemo`（客户端会自动识别此路径）

---

### 在 Bell Memo 客户端中配置

#### Android 客户端

1. 打开 Bell Memo 应用
2. 进入 **设置** -> **同步设置** -> **WebDAV 同步**
3. 填写以下信息：
   ```
   服务器地址: http://your-server-ip:5244/dav
   用户名: admin
   密码: [你的密码]
   同步目录: /BellMemo
   ```
4. 点击 **测试连接** 确认配置正确
5. 保存设置并启用同步

#### iOS 客户端

配置步骤与 Android 类似，在应用的同步设置中填写相同的 WebDAV 信息。

---

### 安全建议

#### 1. 使用 HTTPS（推荐）

如果服务器暴露在公网，强烈建议配置 HTTPS：

**方式一：使用反向代理（推荐）**

使用 Nginx 或 Caddy 作为反向代理，配置 SSL 证书：

```nginx
# Nginx 配置示例
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:5244;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

然后客户端使用：`https://your-domain.com/dav`

**方式二：使用 Alist 内置 HTTPS**

修改 `docker-compose.yml`，添加 SSL 证书挂载和环境变量（参考 [Alist 文档](https://alist.nn.ci/zh/)）。

#### 2. 防火墙配置

如果使用云服务器，确保防火墙开放了 `5244` 端口：

```bash
# Ubuntu/Debian
sudo ufw allow 5244/tcp

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=5244/tcp
sudo firewall-cmd --reload
```

---

### 常见问题排查

#### 1. 连接失败：`Connection refused` 或 `Network error`

**可能原因**：
- Docker 容器未启动
- 端口未正确映射
- 防火墙阻止了连接

**解决方法**：
```bash
# 检查容器状态
docker ps | grep bell-cloud

# 检查端口监听
netstat -tlnp | grep 5244
# 或
ss -tlnp | grep 5244

# 重启容器
cd bell-cloud
docker compose restart
```

#### 2. 认证失败：`401 Unauthorized` 或 `Invalid credentials`

**可能原因**：
- 用户名或密码错误
- WebDAV 路径不正确（必须包含 `/dav`）

**解决方法**：
```bash
# 重置管理员密码
docker exec -it bell-cloud ./alist admin set NEW_PASSWORD

# 确认 WebDAV 路径格式：http://server:port/dav
```

#### 3. 找不到目录：`404 Not Found` 或 `Directory not found`

**可能原因**：
- 存储未正确挂载
- 挂载路径不是 `/BellMemo`
- **根文件夹路径配置错误**（常见错误！）

**解决方法**：
1. 登录 Alist 管理后台 (`http://your-server:5244`)
2. 检查 **存储 (Storages)** 中是否存在 `/BellMemo` 存储
3. 如果存在但无法访问，**检查根文件夹路径是否正确**：
   - ✅ 必须填写：`/mnt/local`
   - ❌ 不要填写：`/storage`、`/mnt/storage`、`./storage` 等
   - 参考 `docker-compose.yml` 中的挂载配置：`./storage:/mnt/local`
4. 如果不存在，参考上文的"服务端配置指南"重新添加

#### 4. 上传失败或文件无法保存

**可能原因**：
- **根文件夹路径配置错误**（最常见原因）
- Docker 卷挂载权限问题

**解决方法**：
1. **检查根文件夹路径**：
   - 登录 Alist 管理后台
   - 进入 **存储 (Storages)** -> 编辑 `/BellMemo` 存储
   - 确认 **根文件夹路径 (Root Folder Path)** 填写的是 `/mnt/local`
   - 如果填写错误，修改为 `/mnt/local` 并保存

2. **检查 Docker 卷权限**：
   ```bash
   # 检查 storage 目录是否存在且有写权限
   ls -la bell-cloud/storage
   
   # 如果权限不足，修改权限
   chmod 755 bell-cloud/storage
   ```

#### 5. 局域网内无法访问

**可能原因**：
- Docker 容器绑定到了 `127.0.0.1` 而不是 `0.0.0.0`

**解决方法**：
检查 `docker-compose.yml` 中的端口映射：
```yaml
ports:
  - '5244:5244'  # ✅ 正确：绑定到所有网络接口
  # - '127.0.0.1:5244:5244'  # ❌ 错误：只绑定到本地
```

---

### 测试 WebDAV 连接

在配置客户端之前，你可以使用命令行工具测试 WebDAV 连接：

```bash
# 使用 curl 测试
curl -X PROPFIND http://your-server:5244/dav \
  -u admin:your_password \
  -H "Depth: 1"

# 如果返回 XML 格式的文件列表，说明连接正常
```

或者使用图形化工具：
- **Windows**: WinSCP、RaiDrive
- **macOS**: Cyberduck、Mountain Duck
- **Linux**: `davfs2`、`rclone`

---

## 📝 数据结构规范 (Protocol)

Bell Memo 客户端与服务端的数据交互遵循 **"Markdown First"** 原则。

### 目录结构

```text
/BellMemo/
├── 2023/
│   ├── 10/
│   │   ├── 2023-10-01_购物清单.md        # 备忘录本体
│   │   └── 2023-10-01_购物清单_assets/   # (可选) 附件文件夹
│   │       ├── image_01.jpg
│   │       └── audio_01.mp3
│   └── ...
└── Archive/
```

### Markdown 元数据 (Front Matter)

每篇备忘录的开头包含 YAML 格式的元数据，用于客户端解析：

```yaml
---
uuid: "550e8400-e29b-41d4-a716-446655440000"
title: "超市购物清单"
created_at: 2023-10-01T10:00:00Z
updated_at: 2023-10-01T10:30:00Z
tags: ["生活", "购物"]
pinned: true
color: "#FF5733"
---

# 超市购物清单

- [ ] 牛奶
- [x] 面包
- [ ] 鸡蛋

![收据](2023-10-01_购物清单_assets/image_01.jpg)
```

## 🔗 相关链接

- [Bell Memo Android 客户端](https://github.com/yourname/bell-memo-android)
- [Alist 官方文档](https://alist.nn.ci/zh/)
