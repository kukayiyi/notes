# openwrt有线组网、无线漫游、802.11kvr配置

本文的目标是使用多台搭载openwrt系统的路由器组成ESSID相同的无线网络，并使设备在游走时自动无缝切换到合适的路由器来提供服务。

需要注意的是，通常讨论的MESH、AC+AP等属于**路由器间的组网方案**，换句话说，这些方案只影响路由器、AP、AC(如果有)之间的互联方式，和手机/平板等在房间里走动时切换wifi的速度/效率/丝滑度等**并没有关系**，影响这些的是**802.11kvr协议**，包括路由器和手机对这些协议的支持，以及机器本身的性能。

一般的，只有存在以下问题时，才需要考虑MESH、AC+AP等组网方案:

**1.**路由器之间没有，或不全有网线相连(存在无线组网的需求)

**2.**路由器数量很多，需要组建庞大的无线网络，且路由器可能随时上线/下线

**3.**硬件条件或网络条件极差，网络使用星型拓扑可靠性太低

显然，在一般的可靠的家庭网络中，这些问题存在的概率较低，因此本文所使用组网方式为**普通有线组网**，且不对组网方式进行进一步的讨论和其他方案的配置。

以上观点参考自https://iyzm.net/openwrt/512.html https://post.smzdm.com/p/a6lr03wg/

## 1.硬件环境

多台由网线相连的路由器，可组成星形网络(中心路由器连接其他路由器)，尽可能使用光猫桥接路由器拨号的方式(未证实，有说光猫拨号会导致dhcp可能出问题)，且系统都为openwrt，实际上，路由器尽可能是同一型号，同一版本openwrt系统

## 2.配置从路由为AP模式

简单说就是关dhcp

参考自https://openwrt.org/zh/docs/guide-user/network/wifi/dumbap#%E4%BD%BF%E7%94%A8openwrt%E7%9A%84web%E7%95%8C%E9%9D%A2luci%E8%BF%9B%E8%A1%8C%E9%85%8D%E7%BD%AE

1.从路由断开wan口连接，使用lan口与电脑相连

2.访问luci页面，网络-接口中，编辑LAN

3.修改IPv4地址为一个主路由器几乎不可能分配的地址，如采用哈希分配的主路由器地址为192.168.1.1，掩码为255.255.255.0，则从路由地址可以考虑改为192.168.1.2，因为这个地址几乎不会被分配到，这只是为了防止和其他设备撞车，且之后可以维护。以防万一，也可以查看主路由的dhcp分配列表，选一个列表里没有的。

4.修改网关地址和dns为主路由器地址

5.在系统-启动项禁用一些不需要的服务，如*firewall*，*dnsmasq*和odhcpd，可选

6.修改无线BSSID、密码与主路由一致，信道可以错开

7.禁用dhcp、dhcpv6，在网络-接口-LAN中，不同的固件位置可能不一样，一般在最下面的dhcp服务器中

8.重启或断电，并将路由器与主路由器、其下的设备连接，注意只能使用LAN口，不能使用WAN口

现在其实已经可以实现无线漫游了，但很难用，必须完全失去其中一台路由器的信号才能切换到另一台路由器

## 3.配置802.11kvr以实现无缝漫游(主从路由)

### 1.kvr配置

如果路由器刷了一些国产大佬的固件，很可能已经内置了kvr和相应的软件包需求，一般在无线-无线安全或者高级配置里，可以看到802.11k、802.11v、802.11r等配置，直接勾选就可以，只有802.11r的配置需要修改：

NAS ID `不填`

移动域/Mobility Domain `可以不填 或所有机器填一样的`

重关联截止时间/Reassociation Deadline 填`20000`

FT protocol/FT 协议 选`FT over the Air`

本地生成 PMK/Generate PMK locally `取消勾`  (WPA3必须，WPA2无所谓)

剩下所有参数全部默认不修改。

### 2.openwrt官方固件kv配置

然而，如果刷了openwrt官方固件，需要进行额外配置。

首先，官方固件为了缩小体积，默认的wpad软件包并不完整，需要在软件包中删除自带的wpad包(23.05.2带的是`wpad-mesh-mbedtls`)，然后安装`wpad-wolfssl`包，除非自带的包已经是`wpad-wolfssl`或`wpad-openssl`，则跳过此步。

截止23.05.2版本，官方固件只内置开启了对802.11r的luci配置方式，k和v默认在页面上是看不到的。因此需要运行以下命令：

```bash
uci set wireless.default_radio0.ieee80211k=1
uci set wireless.default_radio0.wnm_sleep_mode=1
uci set wireless.default_radio0.bss_transition=1
uci set wireless.default_radio0.ieee80211r=1
uci set wireless.default_radio0.mobility_domain=8888
uci set wireless.default_radio0.ft_over_ds=0
uci set wireless.default_radio0.ft_psk_generate_local=0
uci set wireless.default_radio1.ieee80211k=1
uci set wireless.default_radio1.wnm_sleep_mode=1
uci set wireless.default_radio1.bss_transition=1
uci set wireless.default_radio1.ieee80211r=1
uci set wireless.default_radio1.mobility_domain=8888
uci set wireless.default_radio1.ft_over_ds=0
uci set wireless.default_radio1.ft_psk_generate_local=0
uci commit wireless
wifi reload
```

**注意**:一般radio0是2.4gwifi，radio1是5gwifi，如果只想中继其中一个，需要把另一个的配置删去

查看`/etc/config/wireless` 应该可以发现无线设备下多了如下配置项:

```bash
option ieee80211k '1'
option wnm_sleep_mode '1'
option bss_transition '1'
option ieee80211r '1'
option mobility_domain '8888'
option ft_over_ds '0'
option ft_psk_generate_local '0'
```

如果配置文件之前改过或者被改坏了，可以删除此文件，使用`wifi config` 命令重新生成

此时查看界面或日志，如果对应的无线设备并没有启动成功，可以尝试取消勾选802.11v相关的所有配置，如果这样可以成功启动，说明hostapd配置有问题

参考自https://www.right.com.cn/forum/thread-1848870-5-1.html，解决方法为:将hostapd.sh文件(本库router_all/kvr中有)放入/lib/netifd/并覆盖原文件。由于此文件实际是基于18.06.8的hostapd.sh改的，可能会出现一些兼容问题，目前本人还没有碰到

替换完成后，可以正常启动kvr

## 4.测试

ssh登录路由器，输入`logread`命令来查看日志。如果openwrt版本过低，可能需要先开启无线的日志输出，使用以下命令:

```bash
uci set wireless.radio0.log_level=1
uci set wireless.radio1.log_level=1
uci commit wireless
wifi reload
```

接下来就可以拿起设备到处走动来测试了。设备第一次连接wifi时，可能会有以下日志打印，但漫游时不该出现：

```
    Wed Nov  3 21:45:48 2021 daemon.debug hostapd: wlan0: STA 70:8a:09:df:f1:bc WPA: sending 1/4 msg of 4-Way Handshake 

    Wed Nov  3 21:45:48 2021 daemon.debug hostapd: wlan0: STA 70:8a:09:df:f1:bc WPA: received EAPOL-Key frame (2/4 Pairwise) 

    Wed Nov  3 21:45:48 2021 daemon.debug hostapd: wlan0: STA 70:8a:09:df:f1:bc WPA: sending 3/4 msg of 4-Way Handshake 

    Wed Nov  3 21:45:48 2021 daemon.debug hostapd: wlan0: STA 70:8a:09:df:f1:bc WPA: received EAPOL-Key frame (4/4 Pairwise)
```

成功的无缝漫游应该打印：

```
daemon.debug hostapd: wlan0: STA e0:...:30 WPA: FT authentication already completed - do not start 4-way handshake
```

## 5.参考文献汇总

https://openwrt.org/zh/docs/guide-user/network/wifi/dumbap#%E4%BD%BF%E7%94%A8openwrt%E7%9A%84web%E7%95%8C%E9%9D%A2luci%E8%BF%9B%E8%A1%8C%E9%85%8D%E7%BD%AE

https://post.smzdm.com/p/a6lr03wg/

https://vicfree.com/2022/11/openwrt-wpa3-802.11kvr-ap-setup/

https://www.right.com.cn/forum/thread-1848870-5-1.html

https://iyzm.net/openwrt/512.html
