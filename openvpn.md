# openvpn 组建家用网络的配置

## 1、基本信息

网络架构：使用一台路由器作为中心服务器节点，将各地的终端客户端连接起来

服务端系统：openwrt snapshot（基于19版本）

客户端系统：windows 10

## 2、服务端配置

参照https://blog.dreamtobe.cn/openwrt_openvpn/ 进行配置

有几点需要补充或修改：

### 1.生成crt证书时

将openssl.cnf中default_days 、default_crl_days设为：

```
default_days    = 3650
default_crl_days= 3650                  # how long before next CRL
```

在生成.crt证书时，原文没有加有效时间，有效时间默认为30天，如果不想频繁的更换新ca，可以加入-days选项，如：

```
openssl req -batch -nodes -new -keyout "ca.key" -out "ca.crt" -x509 -config ${PKI_CNF} -days 3650
openssl req -batch -nodes -new -keyout "my-client.key" -out "my-client.csr" -subj "/CN=my-client" -config ${PKI_CNF} -days 3650
```

所有crt文件，客户端和服务端的都要这样设置，否则一个月到期后证书将过期。使用如下命令查看证书有效期

```
openssl x509 -in ca.crt -noout -dates
输出为：
notBefore=Sep 30 09:19:47 2021 GMT
notAfter=Sep 28 09:19:47 2031 GMT #到期时间，查看是否为设置时间
```

### 2.多个客户端时

当存在多个客户端时，为表区分，最好设置相关文件的文件名不同。同时，需要在openssl.cnf末尾添加相应的keyUsage和extendedKeyUsage，如：

```
[ server ]
  keyUsage = digitalSignature, keyEncipherment
  extendedKeyUsage = serverAuth
  
[ client_1 ]
  keyUsage = digitalSignature
  extendedKeyUsage = clientAuth
  
[ client_2 ]
  keyUsage = digitalSignature
  extendedKeyUsage = clientAuth
```

注意：这里多个客户端的名字不可以重复

## 3、客户端配置

将服务端生成的客户端文件scp出来，共需要三个文件：ca.crt，my-client.crt，my-client.key，名字取决于你生成文件时的设置

新建一个.ovpn文件，并将三个文件中的内容输入进去，ovpn文件的结构如下：

```
dev tap #tap或tun模式，tap为桥接入server的子网，tun为另起一个vpn子网
proto udp  

verb 3  

client 
remote-cert-tls server 
remote your-server 1197 #这里填入服务端的ip/域名，以及端口号

<ca>
#ca.crt中的内容
</ca>

<cert>
#my-client.crt中的内容
</cert>

<key>
#my-client.key中的内容
</key>

```

完成后，在openvpn客户端中导入此ovpn文件即可连接
