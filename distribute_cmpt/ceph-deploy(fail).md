# Ubuntu 18.04 LTS 64位机上使用ceph_deploy部署ceph集群并不使用额外硬盘部署osd。		

## 1.为便于标识，*所有节点配置*，并进行节点规划。

节点规划如图所示

​	

| hostname |       ip       |              character              |
| :------: | :------------: | :---------------------------------: |
|   mon5   | 202.194.64.165 | cephadm,monitor,mgr,rgw,mds,osd,nfs |
|   osd4   | 202.194.64.164 |     monitor,mgr,rgw,mds,osd,nfs     |
|   osd8   | 202.194.64.168 |     monitor,mgr,rgw,mds,osd,nfs     |

关闭防火墙

```
ufw disable
```

升级系统

```
apt-get update

apt-get upgrade
```

时间同步

```
apt-get install ntp

timedatectl set-ntp false
```

修改/etc/ntp.conf

在一堆pool的地方把pool注释掉，加入

```bash
server 0.asia.pool.ntp.org
server 1.1.cn.pool.ntp.org
```

重启或重载服务

```
service ntp restart
```

查看ntp状态

```
ntpq -p
```

安装python

apt-get install python3

如果自带的python版本低于最新而又想更新，加入版本号并切换

```
apt-get install python3.7
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 2
update-alternatives --config python3
2
```

# 2.ceph-deploy前期准备



## 1.安装ceph-deploy基本包，所有节点都要安

```
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
echo deb https://download.ceph.com/debian-luminous/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
sudo apt update
sudo apt install ceph-deploy
```

**注意：这将安装ceph的luminous版本，而ceph-deploy只支持luminous之前的版本，因此这必定是最新的稳定版本了，要安装更新的ceph版本，请使用cephadm。**

## 2.创建ceph管理账户，所有节点

```
ssh user@ceph-server
sudo useradd -d /home/{username} -m {username}
sudo passwd {username}
echo "{username} ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/{username}
sudo chmod 0440 /etc/sudoers.d/{username}
```

**注意：此账户将用于安装ceph，要求使用sudo时不需要输入密码。账户名不要使用ceph，因为它是现版本的进程用账户。**

创建后解释器默认为/bin/sh，要更改解释器，使用root账户修改/etc/passwd，找到刚才创建的账户名对应的行，将最后的/bin/sh改为/bin/bash。

## 3.ssh

安装ssh，所有节点。

```
sudo apt install openssh-server
```

登录到管理节点（mon5）的ceph管理账户。

生成秘钥，不要使用root账户和sudo。

```
ssh-keygen

Generating public/private key pair.
Enter file in which to save the key (/ceph-admin/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /ceph-admin/.ssh/id_rsa.
Your public key has been saved in /ceph-admin/.ssh/id_rsa.pub.
```

发送秘钥，注意也要发给自己。

```
ssh-copy-id {username}@node1
ssh-copy-id {username}@node2
ssh-copy-id {username}@node3
```

# 3.开始安装

创建一个新文件夹用于存放秘钥，进入创建的文件夹。

```
mkdir test_cluster
```

在管理节点上创建集群

```
ceph-deploy new node1
```

使用ls查看，应该会看到生成的秘钥文件和配置文件，如ceph.conf。

查看conf文件，看network是否是本节点的id。

```
public network = {ip-address}/{bits}
```

**注意：如果节点有多个地址，使用外部地址，不要使用内部地址。**

安装包。

```
ceph-deploy install node1 node2 node3
```

在管理节点激活一个monitor。

```
ceph-deploy mon create-initial
```

将配置文件复制到所有节点。

```
ceph-deploy admin node1 node2 node3
```

部署一个mgr。

```
ceph-deploy mgr create node1
```

部署osd，常规方法需要一个空硬盘，当然lvm卷也可以。

```
ceph-deploy osd create --data /dev/vdb node1
ceph-deploy osd create --data /dev/vdb node2
ceph-deploy osd create --data /dev/vdb node3
```

我在这一步的时候已经装好了系统且不方便重装系统来给osd腾空间，使用命令设置目录为osd，较为麻烦，有条件请使用上面的方法。

### 使用文件目录创建osd

原文链接：https://blog.csdn.net/zzboat0422/article/details/94601138?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.nonecase&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.nonecase

复制key到对应节点

```
scp ceph.bootstrap-osd.keyring node-1859:/var/lib/ceph/bootstrap-osd/ceph.keyring
```

ssh到对应节点（可以是root），执行下列命令。

```
UUID=$(uuidgen)
OSD_SECRET=$(ceph-authtool --gen-print-key)

ID=$(echo "{\"cephx_secret\": \"$OSD_SECRET\"}" | \
   ceph osd new $UUID -i - \
   -n client.bootstrap-osd -k /var/lib/ceph/bootstrap-osd/ceph.keyring)
   
mkdir /var/lib/ceph/osd/ceph-$ID

ceph-authtool --create-keyring /var/lib/ceph/osd/ceph-$ID/keyring \
     --name osd.$ID --add-key $OSD_SECRET

ceph-osd -i $ID --mkfs --osd-uuid $UUID
chown -R ceph:ceph /var/lib/ceph/osd/ceph-$ID
systemctl enable ceph-osd@$ID
systemctl start ceph-osd@$ID
```

使用上述方法在三个节点（其实可以在任意节点上创建任意数量）创建三个osd，ssh到管理节点查看部署情况。

```
ceph -s
```

```
cluster:
    id:     xxx
    health: HEALTH_OK

  services:
    mon: 1 daemons, quorum mon5
    mgr: mon5(active)
    osd: 3 osds: 0 up, 0 in
```

