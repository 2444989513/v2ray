# V2Ray 基于 Nginx  vmess+ws+tls 一键安装脚本 （Use Path）

申明:

此为wulabing/V2Ray_ws-tls_bash_onekey 的另一个算是魔改的版本

[源作者网址](https://github.com/wulabing/V2Ray_ws-tls_bash_onekey):https://github.com/wulabing/V2Ray_ws-tls_bash_onekey

## V2ray core 更新方式
执行：
`bash <(curl -L -s https://install.direct/go.sh)`

（ 来源参考 ：[V2ray官方说明](https://www.v2ray.com/chapter_00/install.html)）
* 如果为最新版本，会输出提示并停止安装。否则会自动更新
* 未来会将相关内容集成到本脚本中并进行交互式操作更新

## 注意事项
* 推荐在纯净环境下使用本脚本，如果你是新手，请不要使用Centos系统。
* 在尝试本脚本确实可用之前，请不要将本程序应用于生产环境中。
* 该程序依赖 Nginx 实现相关功能，请使用 [LNMP](https://lnmp.org) 或其他类似携带 Nginx 脚本安装过 Nginx 的用户特别留意，使用本脚本可能会导致无法预知的错误（未测试，若存在，后续版本可能会处理本问题）。
* V2Ray 的部分功能依赖于系统时间，请确保您使用V2RAY程序的系统 UTC 时间误差在三分钟之内，时区无关。
* 本 bash 依赖于 [V2ray 官方安装脚本](https://install.direct/go.sh) 及 [acme.sh](https://github.com/Neilpang/acme.sh) 工作。
* Centos 系统用户请预先在防火墙中放行程序相关端口（默认：80，443）
## 准备工作
* 准备一个域名，并将A记录添加好。
* [V2ray官方说明](https://www.v2ray.com/)，了解 TLS WebSocket 及 V2ray 相关信息
* 安装好 curl
## 安装方式（不兼容，二选一)
个人建议安装
Vmess+websocket+TLS+Nginx+Website
```
bash <(curl -L -s https://raw.githubusercontent.com/2444989513/v2ray/master/install.sh) | tee v2ray_ins.log
```
个人不太建议安装   但是你喜欢就好！！！！！
Vmess + HTTP2 over TLS
```
bash <(curl -L -s https://raw.githubusercontent.com/2444989513/v2ray/master/install_h2.sh) | tee v2ray_ins_h2.log
```

# 查看客户端配置

`cat $HOME/v2ray_info.inf`


# 启动方式

启动 V2ray：`systemctl start v2ray`

停止 V2ray：`systemctl stop v2ray`

启动 Nginx：`systemctl start nginx`

停止 Nginx：`systemctl stop nginx`

# 相关目录

Web 目录：`/home/wwwroot/250`

V2ray 服务端配置：`/etc/v2ray/config.json`

V2ray 客户端配置: `cat $HOME/v2ray_info.inf`

Nginx 目录： `/etc/nginx`

证书文件: /data/v2ray.key 和 /data/v2ray.crt 请注意证书权限设置





