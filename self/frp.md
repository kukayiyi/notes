# Ubuntu18.04 LTS +windows+阿里云配置frp实现内网穿透

环境：

1.系统为ubuntu18的阿里云的ecs服务器，或任意具有公网ip的ubuntu主机系统   --作为服务端（frps）

2.系统为windows的内网主机（linux可以仿照服务端和win客户端配置） --作为客户端（frpc）



## 1.服务端配置

下载

```
wget https://github.com/fatedier/frp/releases/download/v0.0.0(你想要的的版本)
```

解压、重命名

```
tar -zxvf frp_0.0.0

cp frp_0.0.0 frp

rm -rf frp_0.0.0
```

cd进入frp，并编辑frps.ini文件

```
[common]
bind_port = 7000 #服务端端口号，可以改
authenticate_heartbeats = true
authenticate_new_work_conns = true
authentication_method = token #使用token验证
token = 123456 #token验证码，自己设
log_file = ./frps.log
```

可选：添加开机自启动/挂断重连

创建/lib/systemd/system/frps.service

```
sudo vim  /lib/systemd/system/frps.service
```



```
[Unit]
Description=frps
After=network.target

[Service]
TimeoutStartSec=30
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/home/frpctler/frp/frps -c /home/frpctler/frp/frps.ini & #改为你的frps目录
ExecReload=/home/frpctler/frp/frps reload -c /home/frpctler/frp/frps.ini #同上
ExecStop=/bin/kill $MAINPID

[Install]
WantedBy=multi-user.target

```

frps的原始启动命令

在frp目录下

```
./frps -c ./frps.ini
```

重启后注册为服务，可以通过服务的方式开关frps

启动服务

```
sudo systemctl start frps
```

开机自启动

```
sudo systemctl enable frps 
```

停止

```
sudo systemctl stop frps

```

查看状态

```
sudo systemctl status frps
```

关闭开机自启动

```
sudo systemctl enable frps
```

## 2.客户端

在github上下载与服务端对应版本的frp

https://github.com/fatedier/frp/releases

同样的，由于是客户端，应该配置frp文件夹中的frpc.ini

```
[common]
server_addr = 103.10.196.44 #服务端ip
server_port = 7000 #刚才配置的端口
admin_addr = 127.0.0.1
admin_port = 7400
authenticate_heartbeats = true
authenticate_new_work_conns = true
authentication_method = token
token = 刚才设置的token
tls_enable = true
log_file = ./frps.log

[USER1] #注意，不同user的顶头不能相同
type = tcp
local_ip = 192.168.1.2 #user ip
local_port = 3389
remote_port = 6001 #不同的user应该使用不同的端口
    
[USER2]
type = tcp
local_ip = 192.168.1.3
local_port = 3389
remote_port = 6002
```

如果要在windows中设置frpc开机启动，应该先写一个start.bak脚本，放在frp目录下

```
@echo off
:home
frpc -c frpc.ini
goto home
```

将此脚本添加为开机启动，不同windows版本有不同的方法，请自行百度。

## 3.在阿里云中开启设置对应安全组

在实例控制台进入实例安全组

![QQ图片20200715174626](image/QQ图片20200715174626.png)

添加相应端口，应该包括服务端和客户端设置的所有端口，源填写0.0.0.0/0



![QQ图片20200715174626](image/QQ图片20200715174626-1594806695450.png)

在本文的示例中，你应该在阿里云安全组添加7000、6001、6002端口。