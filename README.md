# ServerStatus

![ServerStatus_preview.png](https://i.loli.net/2020/01/31/Iv47fYVSecxUCML.png)

ServerStatus 是一个提供 Web 界面的云探针，能够实时展示多个服务器的网络连接、CPU、内存、硬盘容量等数据。

## 安装

### 脚本部署

执行以下命令下载脚本并运行

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/LilligantMatsuri/ServerStatus/master/status.sh && chmod +x status.sh
```

运行后会显示如下操作菜单，按照提示进行操作即可

```bash
  ServerStatus 一键安装管理脚本 [vx.x.x]
-- Author: Toyo | Maintainer: Matsuri --

 0. 升级脚本
————————————
 1. 安装 服务端
 2. 更新 服务端
 3. 卸载 服务端
————————————
 4. 启动 服务端
 5. 停止 服务端
 6. 重启 服务端
————————————
 7. 设置 服务端配置
 8. 查看 服务端信息
 9. 查看 服务端日志
————————————
10. 切换 客户端菜单

当前状态: 服务端 未安装

请输入选项的编号 [0-10]:
```

### 文件路径

ServerStatus 安装路径：/usr/local/ServerStatus

```bash
ServerStatus
    ├─ client
        ├─ status-client.py
    ├─ server
        ├─ config.conf
        ├─ config.json ................ 节点配置文件
        ├─ sergate
    ├─ web
        ├─ css
        ├─ img
        ├─ js
        ├─ json
        ├─ favicon.ico
        ├─ index.html
        ├─ robots.txt
    ├─ jq
```

### 常见问题

#### Q：终端输入中文显示错误

**A**：输入的节点名称、位置等含有中文字符时，如果终端模拟器不支持中文编码，将无法正常显示。可以先输入任意内容，然后再修改 config.json 中的相应字段。**修改后需要重启服务端才能在网页上体现**。

## 管理

### 服务端

- 启动：`service status-server start`

- 停止：`service status-server stop`

- 重启：`service status-server restart`

- 状态：`service status-server status`

- 日志：`tail -f /tmp/serverstatus_server.log`

### 客户端

- 启动：`service status-client start`

- 停止：`service status-client stop`

- 重启：`service status-client restart`

- 状态：`service status-client status`

- 日志：`tail -f /tmp/serverstatus_client.log`

### Caddy

- 启动：`service caddy start`

- 停止：`service caddy stop`

- 重启：`service caddy restart`

- 状态：`service caddy status`

## 更新

**2020.02.03**

> - 客户端兼容 Python 3

**2020.02.01**

> - 更新部署脚本
>   
>   - 更正客户端下载链接
>   
>   - 修复 CentOS 版本检测错误
>   
>   - 改进提示信息
> 
> - 调整前端样式

**2020.01.29**

> - 修改部署脚本
> 
> - 添加 flag-icon-css 支持
> 
> - 前端静态库使用 CDN

**2020.01.23**

> - 整理代码
> 
> - 调整前端样式
> 
> - 恢复 IPv6 状态显示

（过往更新参见上游）

## 致谢

* [Uptime Checker script](https://www.lowendtalk.com/discussion/comment/169690#Comment_169690) by **BlueVM**
* [ServerStatus](https://github.com/mojeda/ServerStatus) by **mojeda**
* [ServerStatus](https://github.com/BotoX/ServerStatus) by **BotoX**
* [ServerStatus-Toyo](https://github.com/ToyoDAdoubi/ServerStatus-Toyo) by **ToyoDAdoubi**
* [flag-icon-css](https://github.com/lipis/flag-icon-css) by **lipis**
* [![jsDelivr](https://www.jsdelivr.com/img/logo-horizontal.svg)](https://www.jsdelivr.com/)
