# Ubuntu下部署Hbase

## 1、环境

系统：Ubuntu 18.04 LTS

其他组件：JDK 11， Hadoop 3.2.2

目标组件：zookeeper 3.6.3， hbase 2.4.6

下载链接：https://zookeeper.apache.org/releases.html， https://apache.org/dyn/closer.cgi

## 2、配置环境变量

在/etc/profile中或~/.bashrc中添加：

```
#zookeeper
export ZOOKEEPER_HOME=/home/hadoop/zookeeper3
export PATH=$ZOOKEEPER_HOME/bin:$PATH
#Hbase
export HBASE_HOME=/home/hadoop/hbase2
export PATH=$HBASE_HOME/bin:$PATH
export CLASSPATH=$HBASE_HOME/lib:$CLASSPATH
```

别忘了source

```
source ~/.bashrc
```

## 3、部署zookeeper

hbase需要运行在zookeeper集群上。考虑到各种因素，一般会单独搭建zookeeper集群，但是事实上hbase程序包里是自带zookeeper的。

下载完后解压，主要需要修改zookeeper/conf/zoo.cfg文件

```
# 设定zookeeper的data目录和logs目录

dataDir=/home/hadoop/zookeeper3/data
dataLogDir=/home/hadoop/zookeeper3/logs

# 端口，不多说，注意默认的8080很有可能和别的程序冲突（比如spark）建议修改

clientPort=2181
admin.serverPort=8080

# 节点列表
server.1=master:2888:3888
server.2=slave1:2888:3888
server.3=slave2:2888:3888
```

将zookeeper分发至其他节点，并在每个节点的dataDir目录下创建myid文件，其中写入该节点的id（和上面zoo.cfg中server.后面的数字对应，如如果是2号节点：

```
echo "2" > /home/hadoop/zookeeper3/data/myid
```

启动zookeeper集群

```
zkServer.sh start
```

查看状态

```
zkServer.sh status

ZooKeeper JMX enabled by default
Using config: /home/hadoop/zookeeper3/bin/../conf/zoo.cfg
Mode: leader
```

停的时候可以用：

```
zkServer.sh stop
```

## 4、部署Hbase

首先还是解压，然后修改文件，都位于hbase/conf/下

hbase-env.sh

```
# JDK的位置
export JAVA_HOME= /jdk
# 是否托管zookeeper，如果你是单独搭建的zookeeper，请设为false，使用自带的就true
export HBASE_MANAGES_ZK=false
```

hbase-site.xml

在<configuration>中写

```
# hbase的存储目录，设为hdfs上的地址比较好
<property>
    <name>hbase.rootdir</name>
    <value>hdfs://master4:9000/hbase</value>
  </property>
 # hbase的运行模式，分布式为true，单机为false
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
 # 临时文件夹
  <property>
    <name>hbase.tmp.dir</name>
    <value>./tmp</value>
  </property>
 # 不知道是干嘛的，一般都设为false
  <property>
    <name>hbase.unsafe.stream.capability.enforce</name>
    <value>false</value>
  </property>
 # zookeeper列表 
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>master,slave1,slave2</value>
  </property>
  # 指向zookeeper的data目录
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>/home/hadoop/zookeeper3/data</value>
  </property>
```

