# hadoop 3.3.0 + spark 3.1.2 部署（在Ubuntu 18.04上）

*本文参考自https://blog.csdn.net/weixin_43860247/article/details/88966660*

## 1.部署环境和初始化（需要在所有节点上操作）

### 1.明确host

| host    | ip          |
| ------- | ----------- |
| master1 | 192.168.1.2 |
| slave2  | 192.168.1.3 |
| slave3  | 192.168.1.4 |

将上述信息写入/etc/hosts中，建议将127.0.0.0等ip只指向localhost然后直接将hosts文件分发三份。

### 2.创建hadoop账户

安全和专业起见，应该使用专门的hadoop账户进行hadoop集群的操作。

```
$ sudo useradd -m hadoop -s /bin/bash  #创建hadoop用户，并使用/bin/bash作为shell
$ sudo passwd hadoop                   #为hadoop用户设置密码，输入两次
$ sudo adduser hadoop sudo             #为hadoop用户增加管理员权限，方便部署
$ su - hadoop                          #将当前用户切换到hadoop用户
$ sudo apt update                      #更新hadoop用户的apt,方便后续软件安装
```

### 3.安装必要软件

首先是hadoop和spark的软件包

```
https://downloads.apache.org/hadoop/common/

http://spark.apache.org/downloads.html 
```

然后安装jdk和ssh，这里都使用apt安装，你也可以选择下载压缩包安装配置。hadoop3要求最低的jdk版本为11，因此这里安装11为例。

```
sudo apt install openjdk-11-jdk openjdk-11-jdk-headless openjdk-11-jre openjdk-11-jre-headless openssh-server openssh-client
```

验证是否安装成功。

```
java -version
ssh localhost
```

## 2.配置ssh免密登录

由于hadoop集群是中心化的，需要配置master可以免密登录slave节点。

先在各个节点测试免密登录本机。

```
sudo ssh localhost                        #登陆SSH，或者是ssh master,第一次登陆输入yes
exit                                  #退出登录的ssh localhost
cd ~/.ssh/                            #如果没有这个目录就创建
ssh-keygen -t rsa -P ""  #生成私钥、公钥，默认存放
cat ./id_rsa.pub >> ./authorized_keys #加入授权
chmod 600 authorized_keys                    #设置该文件的权限
ssh localhost                         #或者是ssh master,输入yes,无需密码登陆
```

配置完后应该可以ssh到本机而无需密码。

接下来配置master免密登录slave，首先在master节点上将key传给两个slave节点。

```
scp ~/.ssh/id_rsa.pub hadoop@slave2:/home/hadoop/
scp ~/.ssh/id_rsa.pub hadoop@slave3:/home/hadoop/
```

然后在slave节点上将传过来的key加入授权。

```
cat ~/id_rsa.pub >> ~/.ssh/authorized_keys
```

如果正常，应该可以直接免密登录slave。

```
ssh slave2 #可以用来检验是否能成功登陆，exit退出
```

## 3.配置环境变量

vim ~/.bashrc

在最后添加

```
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
export HADOOP_HOME=/home/hadoop/hadoop3
export CLASSPATH=$($HADOOP_HOME/bin/hadoop classpath):$CLASSPATH
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export SPARK_HOME=/home/hadoop/spark3
export PATH=$PATH:${SPARK_HOME}/bin
```

**注：JAVA_HOME这里是使用apt安装jdk的默认位置，如果使用的压缩包进行安装需要写jdk目录的路径。HADOOP_HOME写hadoop目录的路径，SPARK_HOME写一会安装spark的路径。**

```
source ~/.bashrc
```

使其生效。

## 4.安装hadoop及配置

将hadoop压缩包解压后，主要的配置文件在hadoop/etc/hadoop/中，我们主要要配置以下几个文件：

hadoop-env.sh

```
#这一行：export HADOOP_OS_TYPE=${HADOOP_OS_TYPE:-$(uname -s)}的下面：
#填写jdk路径
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 
export HADOOP_OPTS="-Djava.library.path=${HADOOP_HOME}/lib/native"
```

验证：

```
hadoop version
```

workers

```
master1
slave2
slave3
```

core-siite.xml

```
<configuration>
        <property>
                <!-- HDFS端口，一般设置为master节点的 -->
                <name>fs.defaultFS</name>
                <value>hdfs://master1:9000</value>
        </property>
        <property>
                <!-- 临时文件存放处 -->
                <name>hadoop.tmp.dir</name>
                <value>/home/hadoop/hadoop3/tmp</value>
                <description>Abase for other temporary directories.</description>
        </property>
</configuration>
```

hdfs-site.xml

```
<configuration>
        <property>
                <!-- secondarynamenode的web端口 -->
                <name>dfs.namenode.secondary.http-address</name>
                <value>master1:50090</value>
        </property>
        <property>
                <!-- 副本数，默认为3 -->
                <name>dfs.replication</name>
                <value>3</value> 
        </property>
        <property>
                <!-- 储存元数据的目录 -->
                <name>dfs.namenode.name.dir</name>
                <value>/home/hadoop/hadoop3/tmp/dfs/name</value>
        </property>
        <property>
                <!-- 储存数据的目录 -->
                <name>dfs.datanode.data.dir</name>
                <value>/home/hadoop/hadoop3/tmp/dfs/data</value>
        </property>
</configuration>
```

mapred-site.xml

```
<configuration>
        <property>
                <name>mapreduce.framework.name</name>
                <value>yarn</value>
        </property>
        <property>
                <name>mapreduce.jobhistory.address</name>
                <value>master1:10020</value>
        </property>
        <property>
                <name>mapreduce.jobhistory.webapp.address</name>
                <value>master1:19888</value>
        </property>
</configuration>
```

yarn-site.xml

```
<configuration>
        <property>
                <name>yarn.resourcemanager.hostname</name>
                <value>master1</value>
        </property>
        <property>
                <name>yarn.nodemanager.aux-services</name>
                <value>mapreduce_shuffle</value>
        </property>
        <property>
                <!-- yarn可用物理内存总量，默认为8G，如果机器达不到需要自己调整 -->
                <name>yarn.nodemanager.resource.memory-mb</name>
                <value>8192</value>
        </property>
        <property>
                <!-- yarn可用虚拟cpu核数，推荐设置与物理cpu核数一致，默认为8 -->
                <name>yarn.nodemanager.resource.cpu-vcores</name>
                <value>8</value>
        </property>
        <property>
                <!-- 单个任务最大申请虚拟cpu核数，默认为4 -->
                <name>yarn.scheduler.maximum-allocation-vcores</name>
                <value>4</value>
        </property>
</configuration>
```

推荐的配置方法是在master节点上配好了直接将整个hadoop目录传给slave节点并更改权限。

```
scp -r /home/hadoop/hadoop3 slave1:/home/hadoop/
sudo chown -R hadoop /usr/local/hadoop
```

## 5.启动hadoop

```
hdfs namenode -format #首次运行需要初始化namenode，注意最后出现shutdown不一定就是失败了，需要看打印出的信息里有没有"successful format"之类的字样。
start-dfs.sh
start-yarn.sh
mr-jobhistory-daemon.sh start historyserver
jps #查看各个节点的启动进程
```

正常的话master节点应该有resourcemanager、namenode、datanode（如果你设置了）secondarynamenode、nodemanager，slave节点应该有nodemanager和datanode。

## 6.配置spark

按照刚才在~/.bashrc中配置的spark地址解压并改名后，需要在spark/conf/中进行如下的配置：

将spark-env.sh.template复制重命名为spark-env.sh。

```
cp spark-env.sh.template  spark-env.sh
```

在末尾添加如下代码。

```
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64   #Java路径
export HADOOP_CONF_DIR=/opt/apps/hadoop-2.7.7         #hadoop路径
export SPARK_MASTER_IP=master1                        #spark的master要运行在的节点
export SPARK_MASTER_PORT=7077
export SPARK_WORKER_MEMORY=512m
export SPARK_WORKER_CORES=1
export SPARK_EXECUTOR_MEMORY=512m
export SPARK_EXECUTOR_CORES=1
export SPARK_WORKER_TNSTANCES=1
```

以上的内存、核数根据需要调整。

然后在此目录创建slaves文件。

```
vim slaves
```

并添加入所有节点的host。

```
master1
slave2
slave3
```

然后同样的，复制spark-defaults.conf.template名为spark-defaults.conf。

```
cp spark-defaults.conf.template  spark-defaults.conf
```

添加如下代码。

```
spark.master                     spark://master1:7077
spark.eventLog.enabled           true
#以下两项指定了日志的指定位置，要写hdfs的位置（master：在hadoop的core-site.xml中配置的hdfs的端口，后面跟着的目录需要自己创建。这里是指定的hdfs目录，如果要储存在本地目录，使用file://
spark.eventLog.dir               hdfs://master1:9000/spark-logs
spark.history.fs.loDirectory     hdfs://master1:9000/spark-logs
spark.serializer                 org.apache.spark.serializer.KryoSerializer
spark.driver.memory              5g
spark.executor.extraJavaOptions  -XX:+PrintGCDetails -Dkey=value -Dnumbers="one two three"    
```

配置完成后scp到另外两个节点。

```
scp -r /home/hadoop/spark3 slave2:/home/hadoop/
```

启动集群，启动文件在spark/sbin/中。

```
./start-all.sh 
```

验证

```
spark-shell
```

出现Spark的大图标就是成功了。