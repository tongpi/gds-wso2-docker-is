#!/bin/sh

#=====================================================================================================
#
#修改以下环境变量适合你的环境,其中：
#
#    IS_HOST_NAME            IS身份管理服务器的机器的主机域名  如:is.cd.mtn
#    IS_NAME                 IS身份管理服务器的安装目录，bin文件夹所在的目录.如：/opt/gdsapps/wso2is-5.7.0
#    JAVA_HOME               JDK的安装目录，如：/usr/java/jdk1.8.0_144
#    IS_PORTS_OFFSET         IS身份管理服务器的机器的端口偏移量，默认是0，控制台默认端口是9443，若偏移量设为1 ，则控制台端口是“默认端口+偏移量”，也就是9444. IS的其它端口也会一起偏移
#    IS_SERVER_DISPLAY_NAME  IS身份管理服务器的显示名称，在管理控制台的首页上显示。如：XXXXX学院统一身份管理服务器
#======================================================================================================
IS_HOME=$1
IS_HOST_NAME=$2
IS_SERVER_DISPLAY_NAME=$3
IS_PORTS_OFFSET=0
#LINUX_SERVICE_FILE_NAME=gds-is-server
#-----------------------------------------------------------------------------------------
#以下信息不用修改。前提是：
#IS的版本是5.7.0  IS的服务器证书库的storepass是wso2carbon JRE的安全证书库的storepass是changeit
#-----------------------------------------------------------------------------------------
#下面是IS的服务器证书库
WSO2CARBON_JKS=$IS_HOME/repository/resources/security/wso2carbon.jks
#下面是IS的服务器的crt格式的公钥证书
WSO2CARBON_CRT_FILE=$IS_HOME/repository/resources/security/$IS_HOST_NAME.crt
#下面是IS的客户端应用信任证书库
WSO2_CLIENT_TRUSTSTORE_JKS=$IS_HOME/repository/resources/security/client-truststore.jks
#下面是JRE的安全证书库
JRE_LIB_SECURITY_CACERTS=$JAVA_HOME/jre/lib/security/cacerts
#为了使用JDK的keytool命令
PATH=$JAVA_HOME/bin:$PATH
#-------------------------------------------------------------------------------------------
# 检查环境变量设置
if [ -z "$IS_HOST_NAME" ]; then
  echo "IS_HOST_NAME 环境变量必须设置."
  exit 1
fi

if [ -z "$IS_HOME" ]; then
  echo "IS_HOME 环境变量必须设置."
  exit 1
fi

if [ -z "$JAVA_HOME" ]; then
  echo "JAVA_HOME 环境变量必须设置."
  exit 1
fi

if [ -z "$IS_PORTS_OFFSET" ]; then
  echo "IS_PORTS_OFFSET 环境变量必须设置."
  exit 1
fi

if [ -z "$IS_SERVER_DISPLAY_NAME" ]; then
  echo "IS_SERVER_DISPLAY_NAME 环境变量必须设置."
  exit 1
fi
#-------------------------------------------------------------------------------------------
# 证书处理
#第一步  先删除同名证书
keytool -delete -alias $IS_HOST_NAME -keystore $WSO2CARBON_JKS -storepass wso2carbon  > /dev/null 2>&1
keytool -delete -alias $IS_HOST_NAME -keystore $WSO2_CLIENT_TRUSTSTORE_JKS -storepass wso2carbon  > /dev/null 2>&1
keytool -delete -alias $IS_HOST_NAME -keystore $JRE_LIB_SECURITY_CACERTS -storepass changeit  > /dev/null 2>&1

#第二步  生成新的自签名的密钥对到IS服务器证书库并导入其公钥到客户端证书库
#1、生成一个自签名的密钥对存放到IS的服务器证书库中
keytool -genkey -keyalg RSA -alias $IS_HOST_NAME -validity 36500 -keysize 2048 -dname "EMAILADDRESS=admin@$IS_HOST_NAME, CN=$IS_HOST_NAME, O=长城数字, L=西安, S=陕西, C=CN, OU=安全中心" -keystore $WSO2CARBON_JKS -storepass wso2carbon -keypass wso2carbon   > /dev/null 2>&1
echo "别名为$IS_HOST_NAME密钥对已生成到IS的服务器证书库$WSO2CARBON_JKS中."
#2、导出上一步在IS的服务器证书库中生成的密钥对的公钥证书到文件$WSO2CARBON_CRT_FILE中
keytool -export -alias $IS_HOST_NAME -file $WSO2CARBON_CRT_FILE -keystore $WSO2CARBON_JKS -storepass wso2carbon   > /dev/null 2>&1
echo "别名为$IS_HOST_NAME 的IS服务器公钥已经导出到磁盘上的新文件$WSO2CARBON_CRT_FILE中."
#3、导入$WSO2CARBON_CRT_FILE中的公钥证书到IS的客户端应用信任证书库中
keytool -import -v -trustcacerts -noprompt -alias $IS_HOST_NAME -file $WSO2CARBON_CRT_FILE -keystore $WSO2_CLIENT_TRUSTSTORE_JKS -keypass wso2carbon -storepass wso2carbon   > /dev/null 2>&1
echo "别名为$IS_HOST_NAME 的IS服务器公钥已经导入到IS的客户端应用信任证书库$WSO2_CLIENT_TRUSTSTORE_JKS中."
#4、导入$WSO2CARBON_CRT_FILE中的公钥证书到JRE的安全证书库中
#    注：这一步不是必需的，一般只有使用该jdk的应用（如tomcat中的某个webapp）需要与IS进行SSL通信时才需要执行这一步。建议执行这一步
# keytool -import -v -trustcacerts -noprompt -alias $IS_HOST_NAME -file $WSO2CARBON_CRT_FILE -keystore $JRE_LIB_SECURITY_CACERTS -keypass changeit -storepass changeit   > /dev/null 2>&1
# echo "别名为$IS_HOST_NAME 的IS服务器公钥已经导入到JRE的安全证书库$JRE_LIB_SECURITY_CACERTS中."
#-------------------------------------------------------------------------------------------
# 替换carbon.xml文件的配置
sed -i "s/ISO-8859-1/UTF-8/g" $IS_HOME/repository/conf/carbon.xml
sed -i "s/<Name>WSO2 Identity Server/<Name>$IS_SERVER_DISPLAY_NAME/g" $IS_HOME/repository/conf/carbon.xml
sed -i "s/localhost/$IS_HOST_NAME/g" $IS_HOME/repository/conf/carbon.xml
sed -i "s/<Offset>0</<Offset>$IS_PORTS_OFFSET</g" $IS_HOME/repository/conf/carbon.xml
#-------------------------------------------------------------------------------------------
# 转换编码
iconv -s -f ISO-8859-1 -t UTF-8 $IS_HOME/bin/wso2server.sh  > /dev/null 2>&1
iconv -s -f ISO-8859-1 -t UTF-8 $IS_HOME/repository/conf/carbon.xml > /dev/null 2>&1
#-------------------------------------------------------------------------------------------
# 去掉^M  也可以用dos2unix来转换，但dos2unix需要安装
# sed -i "s/\r//g"  $IS_HOME/bin/wso2server.sh
find $IS_HOME/bin/  -name "*.sh" |xargs sed -i 's/\r//'
#-------------------------------------------------------------------------------------------
# 自动给hosts添加主机域名解析
#temptemp="$(ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addrs:" | tail -n 1)" |echo $temptemp	$IS_HOST_NAME  >>/etc/hosts
#-------------------------------------------------------------------------------------------
# 安装为Linux服务

# cp $LINUX_SERVICE_FILE_NAME $IS_HOME/bin/
# sed -i "s#JAVA_HOME=<JAVA_HOME>#JAVA_HOME=$JAVA_HOME#g" $IS_HOME/bin/$LINUX_SERVICE_FILE_NAME
# sed -i "s#PRODUCT_HOME=<PRODUCT_HOME>#PRODUCT_HOME=$IS_HOME#g" $IS_HOME/bin/$LINUX_SERVICE_FILE_NAME
# chmod a+x $IS_HOME/bin/$LINUX_SERVICE_FILE_NAME
# ln -snf $IS_HOME/bin/$LINUX_SERVICE_FILE_NAME /etc/init.d/$LINUX_SERVICE_FILE_NAME
# update-rc.d $LINUX_SERVICE_FILE_NAME defaults
#-------------------------------------------------------------------------------------------
# echo
# echo "========================================================"
# echo "恭喜！！！       IS服务器已经配置完毕，可以启动起来看看了."
# echo "提示："
# echo "前台启动命令为：$IS_HOME/bin/wso2server.sh  [start | stop | restart]"
# echo "后台启动命令为：sh $IS_HOME/bin/wso2server.sh start & [start | stop | restart]"
# echo "服务方式启动命令为：service $LINUX_SERVICE_FILE_NAME start [start | stop | restart]"