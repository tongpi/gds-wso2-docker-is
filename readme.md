本项目的目标：简化is的产品化版本Docker镜像的发布工作：

- 修改配置
- 生成证书
- 个性化定制

一、目录说明

```
│  build-init-default.sh    使用缺省的H2数据库生成镜像的脚本
│  build-init-oracel.sh     使用外部Oracle数据库生成镜像的脚本
│  readme.md              
│  
├─connectors                 cas 连接器
│      org.wso2.carbon.extension.identity.sso.cas-2.0.2.jar
│      
├─jdbc-drivers               数据库驱动
│      mysql-connector-java-5.1.46.jar
│      ojdbc6.jar
│      
└─scripts                     自动配置脚本
        is_auto_config.sh     自动生成证书-编码转换等工作
        is_auto_config_oracle.sh 自动进行主数据库切换到oracle的工作
```

二、如何使用

1、在linux服务器上安装JDK、git、docker

2、用git拉取本项目到linux服务器的gds-wso2-docker-is目录下

```
git clone https://github.com/tongpi/gds-wso2-docker-is.git
```

3、复制从IS源代码库( https://github.com/tongpi/product-is.git)构建出来的wso2is-5.7.0.zip到本项目跟目录(gds-wso2-docker-is)下

4、修改配置  根据使用场景，修改相应脚本的配置信息以便适应你的环境:

```
打开 build-init-default.sh           # 使用缺省的H2数据库生成镜像的脚本
按照参数说明修改：
export JAVA_HOME=/opt/java/jdk1.8.0_144
PROCUCT_NAME=wso2is
PROCUCT_VERSION=5.7.0
IS_HOST_NAME=is.cd.mtn
IS_HOST_PORT=9443
IS_SERVER_DISPLAY_NAME=统一身份服务器

或
打开build-init-oracel.sh            # 使用外部Oracle数据库生成镜像的脚本
按照参数说明修改：
export JAVA_HOME=/opt/java/jdk1.8.0_144
PROCUCT_NAME=wso2is
PROCUCT_VERSION=5.7.0
IS_HOST_NAME=is.cd.mtn
IS_HOST_PORT=9443
IS_SERVER_DISPLAY_NAME=统一身份服务器
DB_HOST=192.168.3.49
DB_PORT=1521
DB_SID=kyy
DB_USERNAME=数据库用户名
DB_PASSWORD=数据库密码
```

5、根据使用场景，选择执行:

```shell
./build-init-default.sh           # 使用缺省的H2数据库生成镜像的脚本

或

./build-init-oracel.sh            # 使用外部Oracle数据库生成镜像的脚本
```

6、脚本执行完毕，可以看到控制台输出信息如下：

***注：[o]和[-oracle]只在执行build-init-oracel.sh才出现***

> 提示  1：
> IS的本地镜像版本已生成 TAG为：wso2is:o5.7.0
> 你可以执行如下的docker命令来启动IS：
>
> ```
> docker run -it -p 9443:9443 gds/wso2is:[o]5.7.0
> docker run -d -p 9443:9443 --name is.cd.mtn --restart=always gds/wso2is:[o]5.7.0
> ```
>
> 提示  2：
> 已生成能够在单独部署的wso2is版本到/opt/eip/work/target/目录下的wso2is-5.7.0[-oracle].zip文件中
> 你可以直接复制该文件来独立安装已按产品化要求配置好的IS运行版
> 提示  3：
> IS服务一旦启动，你可以通过类似下面的地址访问IS的管理控制台：     
>
> ```
> https://is.cd.mtn:9443/carbon
> ```

