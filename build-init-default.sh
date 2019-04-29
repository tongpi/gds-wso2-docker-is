#!/bin/sh

#=====================================================================================================
#
#修改以下环境变量适合你的环境,其中：
#
#    JAVA_HOME                             JDK的安装目录，如：/usr/java/jdk1.8.0_144。要是为了找到keytool命令
#    PROCUCT_NAME                          IS身份管理服务器的产品名称。用来生成镜像名称和可独立部署的安装包的文件名
#    PROCUCT_VERSION                       IS身份管理服务器的版本。用来生成镜像版本和可独立部署的安装包的文件名
#    IS_HOST_NAME                          IS身份管理服务器的机器的主机域名  如:is.cd.mtn  用来修改conf/carbon.xml
#    IS_HOST_PORT                          IS身份管理服务器的机器的主服务端口  用来生成提示信息
#    IS_SERVER_DISPLAY_NAME                IS身份管理服务器的显示名称，在管理控制台的首页上显示。如：XXXXX学院统一身份管理服务器.  用来修改conf/carbon.xml
#
#======================================================================================================
export JAVA_HOME=/opt/java/jdk1.8.0_144
PROCUCT_NAME=wso2is
PROCUCT_VERSION=5.7.0
IS_HOST_NAME=is.cd.mtn
IS_HOST_PORT=9443
IS_SERVER_DISPLAY_NAME=统一身份服务器
#-------------------------------------------------------------------------------------------
if [ ! -d "$PWD/docker-is" ]; then
  git clone https://github.com/tongpi/docker-is.git
fi
IS_HOME=$PWD/docker-is/dockerfiles/ubuntu/is/files/$PROCUCT_NAME-$PROCUCT_VERSION
echo "IS_HOME=$IS_HOME"
PROCUCT_RELEASE_ZIP_FILE=$PROCUCT_NAME-$PROCUCT_VERSION.zip
if [ ! -f "$PROCUCT_RELEASE_ZIP_FILE" ]; then 
#  wget  $PROCUCT_RELEASE_ZIP_FILE 
   echo "========================================================================================================================="
   echo "用法："
   echo "请首先复制从IS源代码库( https://github.com/tongpi/docker-is.git)构建出来的$PROCUCT_NAME-$PROCUCT_VERSION.zip到$0脚本所在目录下"
   echo "========================================================================================================================="   
   exit 1
fi 
rm -Rf $IS_HOME
unzip $PROCUCT_RELEASE_ZIP_FILE -d $PWD/docker-is/dockerfiles/ubuntu/is/files   > /dev/null
echo '已解压缩PROCUCT_RELEASE_ZIP_FILE到$PWD/docker-is/dockerfiles/ubuntu/is/files目录下'
cp ./jdbc-drivers/*.jar $PWD/docker-is/dockerfiles/ubuntu/is/files/
echo '已复制数据库jdbc驱动到$PWD/docker-is/dockerfiles/ubuntu/is/files目录下'
# 自动配置服务器相关证书以及文件编码转换等工作
./scripts/is_auto_config.sh $IS_HOME $IS_HOST_NAME $IS_SERVER_DISPLAY_NAME

echo "尝试删除旧的IS本地docker 镜像......"
echo docker rmi $PROCUCT_NAME:$PROCUCT_VERSION
docker rmi $PROCUCT_NAME:$PROCUCT_VERSION > /dev/null
echo "开始构建新的IS的docker镜像......"
echo "-------------------------------------------------------------------------------------------"
CUR_DIR=$PWD
cd $PWD/docker-is/dockerfiles/ubuntu/is
echo "docker build -t gds/$PROCUCT_NAME:$PROCUCT_VERSION ."
docker build -t gds/$PROCUCT_NAME:$PROCUCT_VERSION .
cd $CUR_DIR
#生成能够在单独部署的wso2is版本到$PWD/target/目录下
echo "开始构建可单独部署的wso2is版本......"
echo "-------------------------------------------------------------------------------------------"
if [ ! -d "$PWD/target" ]; then
  mkdir target
else
  rm -f $PWD/target/$PROCUCT_NAME-$PROCUCT_VERSION.zip
fi
zip -r $PWD/target/$PROCUCT_NAME-$PROCUCT_VERSION.zip $IS_HOME    > /dev/null
echo "========================================================================================================================="
echo "提示  1："
echo "IS的本地镜像版本已生成 TAG为：$PROCUCT_NAME:$PROCUCT_VERSION"
echo "你可以执行如下的docker命令来启动IS："
echo "     docker run -it -p $IS_HOST_PORT:9443 gds/$PROCUCT_NAME:$PROCUCT_VERSION"
echo "     docker run -d -p $IS_HOST_PORT:9443 --name $IS_HOST_NAME --restart=always gds/$PROCUCT_NAME:$PROCUCT_VERSION"
echo "提示  2："
echo "已生成能够在单独部署的wso2is版本到$PWD/target/目录下的$PROCUCT_NAME-$PROCUCT_VERSION.zip文件中"
echo "你可以直接复制该文件来独立安装已按产品化要求配置好的IS运行版"
echo "提示  3："
echo "IS服务一旦启动，你可以通过类似下面的地址访问IS的管理控制台："
echo "     https://$IS_HOST_NAME:$IS_HOST_PORT/carbon"