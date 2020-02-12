<div align="center">
<img src="https://i.loli.net/2020/02/12/N2jT3DXpIHumiBS.png">
</div>

<h1 align="center">ServerStatus</h1>

<div align="center">
ServerStatus 是一个提供 Web 界面的云探针，<br />实时展示网络连接、CPU、内存、硬盘容量等数据。
</div>

<div align="center">
<a href="LICENSE"><img src="https://img.shields.io/github/license/LilligantMatsuri/ServerStatus" alt="LICENSE"></a>
<a href="https://www.python.org"><img src="https://img.shields.io/badge/Python-%E2%89%A5%202.7-%233776AB?logo=python" alt="Python"></a>
<a href="https://www.centos.org"><img src="https://img.shields.io/badge/CentOS-%E2%89%A5%207-%23262577?logo=centos" alt="CentOS"></a>
<a href="https://www.debian.org"><img src="https://img.shields.io/badge/Debian-%E2%89%A5%207-%23A81D33?logo=debian" alt="Debian"></a>
<a href="https://ubuntu.com"><img src="https://img.shields.io/badge/Ubuntu-%E2%89%A5%2014.04-%23E95420?logo=ubuntu" alt="Ubuntu"></a>
</div>

## 截图

![ServerStatus_preview.png](https://i.loli.net/2020/01/31/Iv47fYVSecxUCML.png)

## 安装

### 脚本部署

**v2 (systemd)**

CentOS ≥ 7 / Debian ≥ 8 / Ubuntu ≥ 15.04 默认支持 systemd，低版本需要手动配置

```bash
wget --no-check-certificate https://git.io/Jvc6U -O status.sh && chmod +x status.sh && bash status.sh
```

**v1 (init)**

系统低于上述版本，或由于其他原因不能使用 systemd 管理服务

```bash
wget --no-check-certificate https://git.io/Jvc6G -O status.sh && chmod +x status.sh && bash status.sh
```

运行脚本后将显示如下菜单，根据提示进行操作即可

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

### 文件目录

ServerStatus 安装路径：/usr/local/ServerStatus

```bash
ServerStatus
    ├─ client
        ├─ status-client.py ........... 客户端程序
    ├─ server
        ├─ config.conf
        ├─ config.json ................ 节点配置文件
        ├─ sergate .................... 服务端程序
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

#### Q：客户端无法正常运行？

**A**：客户端的运行依赖 Python 2.7 及以上（此分支已兼容 3.x）。 

CentOS ≤ 6 / Debian ≤ 6 / Ubuntu ≤ 13.10 的软件包内 Python 版本不符合要求，如果出于某些原因不得不使用这些系统，则需在使用脚本前自行安装 Python 并正确配置（命令 `python -V` 能够打印版本号即可）。

此外，CentOS 8 默认没有内置 Python，脚本将自动安装 2.7 版本并设为默认。如果事先已经安装，则没有影响。

#### Q：终端输入中文显示错误？

**A**：输入的节点名称、位置等含有中文字符时，如果终端模拟器不支持中文编码，将无法正常显示。可以先输入任意内容，然后再修改节点配置文件中的相应字段。**修改后需要重启服务端才能在网页上体现**。

## 管理

### 服务端

- 启动：`systemctl start statuss`

- 停止：`systemctl stop statuss`

- 状态：`systemctl status statuss`

- 若不支持 systemctl 则使用 `service status-server start`，其他命令以此类推

### 客户端

- 启动：`systemctl start statusc`

- 停止：`systemctl stop statusc`

- 状态：`systemctl status statusc`

- 若不支持 systemctl 则使用 `service status-client start`，其他命令以此类推

### Caddy

- 启动：`service caddy start`

- 停止：`service caddy stop`

- 重启：`service caddy restart`

- 状态：`service caddy status`

## 更新

**2020.02.12**

> - 修复 systemd 服务配置
> 
> - 更新部署脚本
>   
>   - 改进各种状态检测
>   
>   - 优化安装和管理流程
>   
>   - 防火墙添加 IPv6 规则

**2020.02.10**

> - 新增部署脚本 v2，使用 systemd 管理服务

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

> - 更新部署脚本
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

（过往更新日志参见上游）

## 致谢

此分支只是在 Toyo 所做工作的基础上进行维护，确保它一直可用、易用，并没有多少实质性的贡献。谨向所有上游代码作者以及相关开源项目作者表示感谢。

* [Uptime Checker script](https://www.lowendtalk.com/discussion/comment/169690#Comment_169690) by **BlueVM**
* [ServerStatus](https://github.com/mojeda/ServerStatus) by **mojeda**
* [ServerStatus](https://github.com/BotoX/ServerStatus) by **BotoX**
* [ServerStatus-Toyo](https://github.com/ToyoDAdoubi/ServerStatus-Toyo) by **ToyoDAdoubi**
* [flag-icon-css](https://github.com/lipis/flag-icon-css) by **lipis**
* [![jsDelivr](https://www.jsdelivr.com/img/logo-horizontal.svg)](https://www.jsdelivr.com/)
