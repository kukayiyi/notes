# redmi ax6000刷机流程

由于网上资料较为复杂，且存在资料错误、重复等问题，因此整理(2024.02.15)

## 1.架构

路由器:redmi ax6000

参考刷机方式和固件:ax6000存在两种刷机布局，ubootmod和stock，前者空间利用率高，但由于与小米官方固件分区不同，不能使用小米救砖工具方便的恢复回官方固件。stock则是相反，保留分区方式和官方一致以可以随时恢复回官方固件，代价是浪费一定空间。由于本人不需要过多繁杂功能，因此**本文的刷机目标是stock布局**，刷机方式参考ptpt52大佬的刷机方式，固件使用openwrt官方23.05.2版本固件(猜测openwrt官网文档也是ptpt52大佬写的)

参考文献

https://openwrt.org/toh/xiaomi/redmi_ax6000#installation 官网教程

https://www.right.com.cn/FORUM/thread-8255378-1-1.html ptpt52大佬的教程

## 2.准备文件

ax6000 官方1.0.48或1.0.60版本固件

initramfs-factory文件，官方固件名称结尾为stock-initramfs-factory.ubi

sysupgrade文件，官方固件名称结尾为stock-squashfs-sysupgrade.bin

可能的救砖工具

上述文件在本仓库router_all目录下

## 3.刷机步骤

### 1.降级固件

如果的路由器官方固件版本大于1.0.60，需要先降级固件，推荐降为1.0.48

在固件升级界面上传低级的固件，页面可能提示不能降级，此时编辑 url 并将末尾的 <html>0</html> 更改为  <html>1</html>，然后按 Enter。如果已经有 <html>1</html>  ，则更改为 <html>2</html>。降级将继续进行。

### 2.获取token

当进入路由器主界面并通过密码登录后，观察此时页面的url，可以找到其中有stok=一串十六进制字符，这就是token，会在下面的步骤中用到，下面执行的操作中，**{token}** 即用来指代这串十六进制字符，在执行命令时使用这串字符来替换**{token}** 即可。值得注意的是，这串字符每次重启路由器都会变化，需要重新复制。

### 3.开启ssh

使用这些url来开启debug模式。执行每个url后会返回数字。执行后路由器会重启

```
http://192.168.31.1/cgi-bin/luci/;stok={token}/api/misystem/set_sys_time?timezone=%20%27%20%3B%20echo%20pVoAAA%3D%3D%20%7C%20base64%20-d%20%7C%20mtd%20write%20-%20crash%20%3B%20 

http://192.168.31.1/cgi-bin/luci/;stok={token}/api/misystem/set_sys_time?timezone=%20%27%20%3b%20reboot%20%3b%20
```

使用以下url来设置Bbeta参数来开启telnet，会重启

```
http://192.168.31.1/cgi-bin/luci/;stok={token}/api/misystem/set_sys_time?timezone=%20%27%20%3B%20bdata%20set%20telnet_en%3D1%20%3B%20bdata%20set%20ssh_en%3D1%20%3B%20bdata%20commit%20%3B%20

http://192.168.31.1/cgi-bin/luci/;stok={token}/api/misystem/set_sys_time?timezone=%20%27%20%3b%20reboot%20%3b%20
```

使用telnet登录路由器，不需要密码

首先修改root密码

```bash
echo -e 'admin\nadmin' | passwd root
```

固化ssh

```bash
bdata set boot_wait=on
bdata commit
nvram set ssh_en=1
nvram set telnet_en=1
nvram set uart_en=1
nvram set boot_wait=on
nvram commit
sed -i 's/channel=.*/channel="debug"/g' /etc/init.d/dropbear
/etc/init.d/dropbear restart
```

使用以下代码来永久开启ssh

```bash
mkdir /data/auto_ssh && cd /data/auto_ssh
curl -O https://fastly.jsdelivr.net/gh/lemoeo/AX6S@main/auto_ssh.sh
chmod +x auto_ssh.sh
uci set firewall.auto_ssh=include
uci set firewall.auto_ssh.type='script'
uci set firewall.auto_ssh.path='/data/auto_ssh/auto_ssh.sh'
uci set firewall.auto_ssh.enabled='1'
uci commit firewall
```

注意第二个命令下载了auto_ssh.sh脚本。如果无法访问外网，需要下好传进去(或者直接vim复制)，在本仓库router_all下也有备份

修改时区设置

```bash
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].webtimezone='CST-8'
uci set system.@system[0].timezoneindex='2.84'
uci commit
```

关闭debug模式并重启

```bash
mtd erase crash
reboot
```

### 4.刷固件

使用ssh登录路由器，用户名是root，密码admin，并将固件initramfs-factory文件(ubi)上传至路由器/tmp目录下

查看固件版本

```bash
cat /proc/cmdline
```

会打印形如：

```
console=ttyS0,115200n1 loglevel=8 firmware=1 uart_en=1
```

注意firmware的值，可能为0或1，指目前的系统为ubi1或ubi0，根据此，后续会进行不同的操作

**注意!!!此处开始刷写固件，务必核对好固件版本**

如果firmware=0，设置nvram变量从ubi1启动，执行：

```bash
nvram set boot_wait=on
nvram set uart_en=1
nvram set flag_boot_rootfs=1
nvram set flag_last_success=1
nvram set flag_boot_success=1
nvram set flag_try_sys1_failed=0
nvram set flag_try_sys2_failed=0
nvram commit
ubiformat /dev/mtd9 -y -f /tmp/initramfs-factory.ubi
reboot 
```

如果firmware=1，设置nvram变量从ubi0启动，执行：

```bash
nvram set boot_wait=on
nvram set uart_en=1
nvram set flag_boot_rootfs=0
nvram set flag_last_success=0
nvram set flag_boot_success=1
nvram set flag_try_sys1_failed=0
nvram set flag_try_sys2_failed=0
nvram commit
ubiformat /dev/mtd8 -y -f /tmp/initramfs-factory.ubi
reboot 
```

把上述命令中/tmp/initramfs-factory.ubi替换为实际的文件路径即可

重启后，应该进入了临时系统，接下来需要刷写sysupgrade.bin文件，将文件传入/tmp目录下

执行以下命令来设置uboot env变量

```bash
fw_setenv boot_wait on
fw_setenv uart_en 1
fw_setenv flag_boot_rootfs 0
fw_setenv flag_last_success 1
fw_setenv flag_boot_success 1
fw_setenv flag_try_sys1_failed 8
fw_setenv flag_try_sys2_failed 8
```

刷写bin文件

```
sysupgrade -n /tmp/stock-sysupgrade.bin
```

同样修改文件路径

重启完成后，openwrt就可用了。访问:192.168.1.1 root admin
