#!/bin/sh

#=====================================================================================================
#
#修改以下环境变量适合你的环境,其中：
#    JAVA_HOME                             JDK的安装目录，如：/usr/java/jdk1.8.0_144。要是为了找到keytool命令
#    PROCUCT_NAME                          IS身份管理服务器的产品名称。用来生成镜像名称和可独立部署的安装包的文件名
#    PROCUCT_VERSION                       IS身份管理服务器的版本。用来生成镜像版本和可独立部署的安装包的文件名
#    IS_HOST_NAME                          IS身份管理服务器的机器的主机域名  如:is.cd.mtn  用来修改conf/carbon.xml
#    IS_HOST_PORT                          IS身份管理服务器的机器的主服务端口  用来生成提示信息
#    IS_SERVER_DISPLAY_NAME                IS身份管理服务器的显示名称，在管理控制台的首页上显示。如：XXXXX学院统一身份管理服务器.  用来修改conf/carbon.xml
#
#    以下用来修改<PRODUCT_HOME>/repository/conf/datasources下的数据源配置文件master-datasources.xml等
#
#    DB_HOST                               IS身份管理服务器的主数据库Oracle的主机地址，如：192.168.3.49  
#    DB_PORT                               IS身份管理服务器的主数据库Oracle的端口，如：1521
#    DB_SID                                IS身份管理服务器的主数据库Oracle的SID，如：kyy
#    DB_USERNAME                           IS身份管理服务器的主数据库Oracle的用户名
#    DB_PASSWORD                           IS身份管理服务器的主数据库Oracle的密码
#
#    CARBON_UI_CUSTOM_IS_BRANCH            IS管理控制台个性化定制项目的分支名称，缺省是master
#======================================================================================================
export JAVA_HOME=/opt/java/jdk1.8.0_144
PROCUCT_NAME=wso2is
PROCUCT_VERSION=5.7.0
IS_HOST_NAME=is.cd.mtn
IS_HOST_PORT=9443
IS_SERVER_DISPLAY_NAME=统一身份服务器
DB_HOST=192.168.3.49
DB_PORT=1521
DB_SID=kyy
DB_USERNAME=wch_is
DB_PASSWORD=a1b2c3
CARBON_UI_CUSTOM_IS_BRANCH=master
PROCUCT_RELEASE_ZIP_FILE_DOWNLOAD_COMMAND="wget -N --http-user=admin --http-password=a1b2c3d4 --auth-no-challenge http://192.168.3.69:9080/job/product-is/lastSuccessfulBuild/artifact/modules/distribution/target/wso2is-5.7.0.zip"
#-------------------------------------------------------------------------------------------
CUR_DIR=$PWD
if [ ! -d "$PWD/docker-is" ]; then
  git clone https://github.com/tongpi/docker-is.git
fi
IS_HOME=$PWD/docker-is/dockerfiles/ubuntu/is/files/$PROCUCT_NAME-$PROCUCT_VERSION
echo "IS_HOME=$IS_HOME"
PROCUCT_RELEASE_ZIP_FILE=$PROCUCT_NAME-$PROCUCT_VERSION.zip
echo "开始从产品仓库下载$PROCUCT_RELEASE_ZIP_FILE到本地磁盘……"
$PROCUCT_RELEASE_ZIP_FILE_DOWNLOAD_COMMAND
if [ ! -f "$PROCUCT_RELEASE_ZIP_FILE" ]; then 
#  wget  $PROCUCT_RELEASE_ZIP_FILE 
   echo "========================================================================================================================="
   echo "用法："
   echo "请首先复制从IS源代码库( https://github.com/tongpi/product-is.git)构建出来的$PROCUCT_NAME-$PROCUCT_VERSION.zip到$0脚本所在目录下"
   echo "========================================================================================================================="  
   exit 1
fi 
rm -Rf $IS_HOME
# 自动安装zip包
if type unzip >/dev/null 2>&1; then 
  echo 'zip软件包已经安装' 
else 
  echo '正在安装zip软件包……' 
  sudo apt-get install zip --assume-yes  > /dev/null
fi
#-------------------------------------------------------------------------------------------
unzip $PROCUCT_RELEASE_ZIP_FILE -d $PWD/docker-is/dockerfiles/ubuntu/is/files   > /dev/null
echo '已解压缩PROCUCT_RELEASE_ZIP_FILE到$PWD/docker-is/dockerfiles/ubuntu/is/files目录下'
# 这一步是给docker build准备的
cp ./jdbc-drivers/*.jar $PWD/docker-is/dockerfiles/ubuntu/is/files/
# 这一步仅仅为了单独部署而准备，对build docker image来说不是必需的
cp ./jdbc-drivers/*.jar $IS_HOME/repository/components/lib/
echo '已复制数据库jdbc驱动到$PWD/docker-is/dockerfiles/ubuntu/is/files目录下'

# 给IS部署cas构件  添加org.wso2.carbon.identity.sso.cas-2.0.X.jar文件到$IS_HOME//repository/components/dropins目录下即可
cp ./connectors/org.wso2.carbon.extension.identity.sso.cas-2.0.2.jar $IS_HOME//repository/components/dropins/
# "-------------------------------------------------------------------------------------------"
echo "开始进行IS管理控制台个性化定制组件的安装工作"
if [ ! -d "$PWD/carbon-ui-custom-is" ]; then
  rm -Rf $PWD/carbon-ui-custom-is
  git clone -b $CARBON_UI_CUSTOM_IS_BRANCH https://github.com/tongpi/carbon-ui-custom-is.git
fi
cd carbon-ui-custom-is
mvn clean install    > /dev/null
cp modules/org.wso2.carbon.ui_fragment/target/org.wso2.carbon.ui_4.4.35_fragment-1.0.0.jar ../docker-is/dockerfiles/ubuntu/is/files/$PROCUCT_NAME-$PROCUCT_VERSION/repository/components/dropins/
cp modules/org.wso2.carbon.ui_patch/target/org.wso2.carbon.ui_4.4.35_patch-1.0.0.jar ../docker-is/dockerfiles/ubuntu/is/files/$PROCUCT_NAME-$PROCUCT_VERSION/repository/components/dropins/
cd $CUR_DIR
# "-------------------------------------------------------------------------------------------"
# 自动配置服务器相关证书以及文件编码转换等工作
chmod +x ./scripts/*.sh
./scripts/is_auto_config.sh $IS_HOME $IS_HOST_NAME $IS_SERVER_DISPLAY_NAME
# 自动配置服务器主数据库配置为oracle等工作
./scripts/is_auto_config_oracle.sh  $IS_HOME $DB_HOST $DB_PORT $DB_SID $DB_USERNAME $DB_PASSWORD

echo "尝试删除旧的IS本地docker 镜像......"
echo docker rmi $PROCUCT_NAME:o$PROCUCT_VERSION
sudo docker rmi $PROCUCT_NAME:o$PROCUCT_VERSION > /dev/null
echo "开始构建新的IS的docker镜像......"
echo "-------------------------------------------------------------------------------------------"
cd $PWD/docker-is/dockerfiles/ubuntu/is
echo "docker build -t gds/$PROCUCT_NAME:o$PROCUCT_VERSION ."
sudo docker build -t gds/$PROCUCT_NAME:o$PROCUCT_VERSION .
cd $CUR_DIR
#生成能够在单独部署的wso2is版本到$PWD/target/目录下
echo "开始构建可单独部署的wso2is版本......"
# "-------------------------------------------------------------------------------------------"
if [ ! -d "$PWD/target" ]; then
  mkdir target
else
  rm -f $PWD/target/$PROCUCT_NAME-$PROCUCT_VERSION-oracle.zip
fi
zip -r $PWD/target/$PROCUCT_NAME-$PROCUCT_VERSION-oracle.zip $IS_HOME    > /dev/null
# "-------------------------------------------------------------------------------------------"
#导出镜像文件以便迁移到其它docker环境中
sudo docker save -o $PWD/target/$PROCUCT_NAME-o$PROCUCT_VERSION.tar gds/$PROCUCT_NAME:o$PROCUCT_VERSION
# "-------------------------------------------------------------------------------------------"
echo "检查容器是否存在，若存在，就先删除然后重新创建一个"
DOCKER_CONTAINER_NAME=$IS_HOST_NAME
if [ ! "$(docker ps -q -f name=$DOCKER_CONTAINER_NAME)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=$DOCKER_CONTAINER_NAME)" ]; then
        docker stop $DOCKER_CONTAINER_NAME
        docker rm $DOCKER_CONTAINER_NAME
    fi
    docker run -d --name $DOCKER_CONTAINER_NAME --restart=always -p $IS_HOST_PORT:9443  gds/$PROCUCT_NAME:$PROCUCT_VERSION
    echo "                 ################################################################"
    echo
    echo "                 访问IS的管理控制台：https://$IS_HOST_NAME:$IS_HOST_PORT/carbon"
    echo "                 注意：你可能需要给你的hosts中添加添加如下的主机域名解析："
#    temptemp="$(ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addrs:" | tail -n 1)" 
    echo "                       192.168.3.69	$IS_HOST_NAME"
    echo
    echo "                 ###############################################################"
fi
echo "========================================================================================================================="
echo "提示  1："
echo "IS的本地镜像版本已生成 TAG为：$PROCUCT_NAME:o$PROCUCT_VERSION"
echo "你可以复制$PWD/target/$PROCUCT_NAME-o$PROCUCT_VERSION.tar文件到光盘以便迁移到其它docker环境中"
echo "你也可以直接在本机执行如下的docker命令来启动IS："
echo "     docker run -it -p $IS_HOST_PORT:9443 gds/$PROCUCT_NAME:o$PROCUCT_VERSION"
echo "     docker run -d -p $IS_HOST_PORT:9443 --name $IS_HOST_NAME --restart=always gds/$PROCUCT_NAME:o$PROCUCT_VERSION"
echo "提示  2："
echo "已生成能够在单独部署的wso2is版本到$PWD/target/目录下的$PROCUCT_NAME-$PROCUCT_VERSION-oracle.zip文件中"
echo "你可以直接复制该文件来独立安装已按产品化要求配置好的IS运行版"
echoecho "提示  3："
echo "IS服务一旦启动，你可以通过类似下面的地址访问IS的管理控制台："
echo "     https://$IS_HOST_NAME:$IS_HOST_PORT/carbon"
