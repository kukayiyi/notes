# Ubuntu 18.04 LTS 网络配置（配置ip、dns等）

## 1.配置ip

首先打开interfaces文件

```
vi /etc/network/interfaces
```

进行ip配置，在原有文件上继续写

```
auto lo                        
iface lo inet loopback         
                               
auto enp2s0 #一般实体机默认网卡                   
iface enp2s0 inet static       
address 1.2.3.4 		#你的ip         
netmask 255.255.255.0 	#子网掩码        
network 1.2.3.4  		#网络地址，可选       
gateway 1.2.3.4         #网关   
broadcast 1.2.3.4       #广播地址，可选
dns-nameservers 8.8.8.8 #可以在这里配置dns，但是注意：照此文方法，此处配置dns将可能不生效

```

## 2关掉所有托管程序

ubuntu 18 dns配置比较麻烦，我踩了很久的坑，也可能是学校网络环境导致，如果在interfaces中配置了dns并重启之后可以直接上网，就可以不用继续看了。

Ubuntu 18 的dns主要配置在/etc/resolv.conf中，但是查看此文件注释会发现，本文件是由systemd-resolved服务软连接另一文件生成的，直接修改将会在重启服务后修改回来。禁用systemd-resolved后，如果你设置了NetworkManager托管，那么此文件也会被其托管。最省事的方法就是关闭所有网络托管程序，手动修改/etc/resolv.conf。

关闭systemd-resolved

```
systemctl disable --now systemd-resolved.service
```

关闭NetworkManager托管

```
systemctl disable --now NetworkManager.service
```

**TIPS：NetworkManager托管只有ubuntu桌面版才有，如果你关闭了NetworkManager托管，你将会在右上角网络设置里看到“有线设备未托管“，不用理会。**

备份/etc/resolv.conf,并删除原文件以切断链接。

```
cp /etc/resolv.conf /etc/resolv.conf.bak
rm /etc/resolv.conf
```

在准备使用的resolv.conf中，将nameserver 127.0.0.x改为自己的dns。

```
nameserver 114.114.114.114

nameserver 8.8.4.4
```

然后重启服务或重启。

```
reboot
```



重启系统，并ping百度，应该可以上网了。

