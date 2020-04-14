# docker-blogdemo
用来演示Django项目容器化实践

# Django项目容器化实践

<a name="K4qaZ"></a>
## 实验环境简介
- OS：CentOS7.5
- Harbor：v1.9.2
- Docker Version：19.03.8
- Django 项目地址：[https://github.com/gongwz/docker-blogdemo](https://github.com/gongwz/docker-blogdemo)

![image.png](https://cdn.nlark.com/yuque/0/2020/png/486920/1586768071909-9aa8a473-cd9b-4177-baa5-23fcf1bc8008.png#align=left&display=inline&height=554&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1108&originWidth=2274&size=2588076&status=done&style=none&width=1137)
<a name="kGMxw"></a>
## Dockerfile构建Django项目
<a name="RTwuq"></a>
### 原始的方法逐步构建
在项目根目录下创建 `dockerfiles`  目录，然后创建一个 `dockerfiles/myblog/Dockerfile`
```bash
# This my first django Dockerfile
# Version 1.0

# Base images 基础镜像
FROM centos:centos7.5.1804

#MAINTAINER 维护者信息
LABEL maintainer="weizhen@gmail.com"

#ENV 设置环境变量
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

#RUN 执行以下命令
RUN curl -so /etc/yum.repos.d/Centos-7.repo http://mirrors.aliyun.com/repo/Centos-7.repo
RUN yum install -y  python36 python3-devel gcc pcre-devel zlib-devel make net-tools

#工作目录
WORKDIR /opt/myblog

#拷贝文件至工作目录
COPY . .

#安装nginx
RUN tar -zxf nginx-1.13.7.tar.gz -C /opt  && cd /opt/nginx-1.13.7 && ./configure --prefix=/usr/local/nginx \
&& make && make install && ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

RUN cp myblog.conf /usr/local/nginx/conf/myblog.conf

#安装依赖的插件
RUN pip3 install -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com -r requirements.txt

RUN chmod +x run.sh && rm -rf ~/.cache/pip

#EXPOSE 映射端口
EXPOSE 8002

#容器启动时执行命令
CMD ["./run.sh"]
```
**到项目根目录下执行构建**
```bash
docker build . -t myblog:v1 -f dockerfiles/myblog/Dockerfile
```
![image.png](https://cdn.nlark.com/yuque/0/2020/png/486920/1586769384935-4ce3e884-2a13-4fa6-a3d7-cde02e7eefbb.png#align=left&display=inline&height=202&margin=%5Bobject%20Object%5D&name=image.png&originHeight=404&originWidth=2290&size=1013828&status=done&style=none&width=1145)<br />因为要下载的镜像比较大，构建时间会非常久（与网络速度有关）。<br />![image.png](https://cdn.nlark.com/yuque/0/2020/png/486920/1586771563436-fa456f45-aaa3-4904-81b0-edd36547ca4f.png#align=left&display=inline&height=69&margin=%5Bobject%20Object%5D&name=image.png&originHeight=138&originWidth=2280&size=362391&status=done&style=none&width=1140)
<a name="I3S0q"></a>
### 通过拆分定制的镜像来构建
<a name="RBgn4"></a>
#### 第一步：先生成基础镜像
`dockerfiles/myblog/Dockerfile-base`
```bash
# Base images 基础镜像
FROM centos:centos7.5.1804

#MAINTAINER 维护者信息
LABEL maintainer="weizhen@gmail.com"

#ENV 设置环境变量
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

#RUN 执行以下命令
RUN curl -so /etc/yum.repos.d/Centos-7.repo http://mirrors.aliyun.com/repo/Centos-7.repo
RUN yum install -y  python36 python3-devel gcc pcre-devel zlib-devel make net-tools

COPY nginx-1.13.7.tar.gz  /opt

#安装nginx
RUN tar -zxf /opt/nginx-1.13.7.tar.gz -C /opt  && cd /opt/nginx-1.13.7 && ./configure --prefix=/usr/local/nginx && make && make install && ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx
```
先构建一个基础镜像
```bash
docker build . -t centos-python3-nginx:v1 -f Dockerfile-base  # 构建基础镜像
docker tag centos-python3-nginx:v1 172.21.32.6:5000/base/centos-python3-nginx:v1  # 将构建好的基础镜像打 tag
docker push 172.21.32.6:5000/base/centos-python3-nginx:v1  # 推送至自己的镜像仓库
```
<a name="Kk9oa"></a>
#### 第二步：根据基础镜像来构建
`dockerfiles/myblog/Dockerfile-optimized`
```bash
# This my first django Dockerfile
# Version 1.0

# Base images 基础镜像
FROM centos-python3-nginx:v1

#MAINTAINER 维护者信息
LABEL maintainer="weizhen@gmail.com"

#工作目录
WORKDIR /opt/myblog

#拷贝文件至工作目录
COPY . .

RUN cp myblog.conf /usr/local/nginx/conf/myblog.conf

#安装依赖的插件
RUN pip3 install -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com -r requirements.txt

RUN chmod +x run.sh && rm -rf ~/.cache/pip

#EXPOSE 映射端口
EXPOSE 8002

#容器启动时执行命令
CMD ["./run.sh"]
```
```bash
$ docker build . -t myblog -f dockerfiles/myblog/Dockerfile-optimized
```
<a name="Nqg5A"></a>
### 运行MySQL容器
```bash
docker run -d -p 3306:3306 --name mysql  -v /opt/mysql/mysql-data/:/var/lib/mysql -e MYSQL_DATABASE=myblog -e MYSQL_ROOT_PASSWORD=123456 mysql:5.7
```
![image.png](https://cdn.nlark.com/yuque/0/2020/png/486920/1586772574769-74346837-13e7-424e-9a78-7b977ea2d2ae.png#align=left&display=inline&height=562&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1124&originWidth=2318&size=2676616&status=done&style=none&width=1159)
<a name="5q31d"></a>
### 运行Django项目
```bash
## 启动容器
$ docker run -d -p 8002:8002 --name myblog -e MYSQL_HOST=172.16.192.101 -e MYSQL_USER=root -e MYSQL_PASSWD=123456  myblog

## migrate
$ docker exec -ti myblog bash
#/ python3 manage.py makemigrations
#/ python3 manage.py migrate
#/ python3 manage.py createsuperuser

## 创建超级用户
$ docker exec -ti myblog python3 manage.py createsuperuser

## 收集静态文件
## $ docker exec -ti myblog python3 manage.py collectstatic
```
![image.png](https://cdn.nlark.com/yuque/0/2020/png/486920/1586772923782-9f310a0a-3028-4b0c-ae46-0771c4b8f68b.png#align=left&display=inline&height=532&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1064&originWidth=2278&size=2542526&status=done&style=none&width=1139)<br />部署成功，浏览器可访问！<br />![image.png](https://cdn.nlark.com/yuque/0/2020/png/486920/1586773037256-69935196-c934-496d-ae88-940d4e1c2e5f.png#align=left&display=inline&height=522&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1044&originWidth=2682&size=121017&status=done&style=none&width=1341)
<a name="uIb98"></a>
## Harbor管理整个项目镜像
刚才从互联网下载了大量基础镜像耗费了很多时间，如果内网有复用的场景存在就应该有更加合理的私有仓库存在，这里选择 Harbor，使用 Compose 也可。<br />本次Harbor镜像地址：[http://192.168.24.173:555](http://192.168.24.173:5555/)5/django-demo<br />![image.png](https://cdn.nlark.com/yuque/0/2020/png/486920/1586854809303-25942e8f-a506-4d13-b372-fcdd54e418ee.png#align=left&display=inline&height=741&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1482&originWidth=2858&size=264130&status=done&style=none&width=1429)
<a name="Mv6vo"></a>
### 第一步：内网生成基础镜像
`dockerfiles/myblog/Dockerfile-base`
```bash
# Base images 基础镜像
FROM 192.168.24.173:5555/django-demo/centos:centos7.5.1804

#MAINTAINER 维护者信息
LABEL maintainer="weizhen@gmail.com"

#ENV 设置环境变量
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

#RUN 执行以下命令
RUN curl -so /etc/yum.repos.d/Centos-7.repo http://mirrors.aliyun.com/repo/Centos-7.repo
RUN yum install -y  python36 python3-devel gcc pcre-devel zlib-devel make net-tools

COPY nginx-1.13.7.tar.gz  /opt

#安装nginx
RUN tar -zxf /opt/nginx-1.13.7.tar.gz -C /opt  && cd /opt/nginx-1.13.7 && ./configure --prefix=/usr/local/nginx && make && make install && ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx
```
先构建一个基础镜像
```bash
docker build . -t centos-python3-nginx:v1 -f Dockerfile-base  # 构建基础镜像
docker tag centos-python3-nginx:v1 192.168.24.173:5555/django-demo/centos-python3-nginx:v1  # 将构建好的基础镜像打 tag
docker push 192.168.24.173:5555/django-demo/centos-python3-nginx:v1  # 推送至自己的镜像仓库
```
<a name="xX4Bk"></a>
### 第二步：根据Harbor基础镜像来构建
`dockerfiles/myblog/Dockerfile-optimized`
```bash
# This my first django Dockerfile
# Version 1.0

# Base images 基础镜像
FROM 192.168.24.173:5555/django-demo/centos-python3-nginx:v1

#MAINTAINER 维护者信息
LABEL maintainer="weizhen@gmail.com"

#工作目录
WORKDIR /opt/myblog

#拷贝文件至工作目录
COPY . .

RUN cp myblog.conf /usr/local/nginx/conf/myblog.conf

#安装依赖的插件
RUN pip3 install -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com -r requirements.txt

RUN chmod +x run.sh && rm -rf ~/.cache/pip

#EXPOSE 映射端口
EXPOSE 8002

#容器启动时执行命令
CMD ["./run.sh"]
```
```bash
$ docker build . -t myblog-demo:v1 -f dockerfiles/myblog/Dockerfile-optimized
```
![image.png](https://cdn.nlark.com/yuque/0/2020/png/486920/1586852600902-96f4419b-c1c0-4968-abe6-5ac7bd7fce4e.png#align=left&display=inline&height=674&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1348&originWidth=2292&size=435420&status=done&style=none&width=1146)<br />然后将 `myblog-demo:v1` 镜像推送至 Harbor
<a name="Y9AZG"></a>
## 根据Harbor里的镜像来部署Django项目
<a name="bBLmq"></a>
### 启动数据库容器
```bash
docker run -d -p 3306:3306 --name mysql  -v /opt/mysql/mysql-data/:/var/lib/mysql -e MYSQL_DATABASE=myblog -e MYSQL_ROOT_PASSWORD=123456 192.168.24.173:5555/django-demo/mysql:5.7
```
<a name="Z6uKz"></a>
### 启动Django项目容器
```bash
docker run -d -p 8002:8002 --name myblog -e MYSQL_HOST=172.16.192.101 -e MYSQL_USER=root -e MYSQL_PASSWD=123456  192.168.24.173:5555/django-demo/myblog-demo:v1
```
<a name="rAte4"></a>
### 项目数据库迁移
```bash
docker exec -ti myblog bash
#/ python3 manage.py makemigrations
#/ python3 manage.py migrate
#/ python3 manage.py createsuperuser

## 创建超级用户
docker exec -ti myblog python3 manage.py createsuperuser
```
![image.png](https://cdn.nlark.com/yuque/0/2020/png/486920/1586854640897-64864b79-426a-4720-83cb-0c2c3837eb1f.png#align=left&display=inline&height=592&margin=%5Bobject%20Object%5D&name=image.png&originHeight=1184&originWidth=2404&size=460570&status=done&style=none&width=1202)<br />至此、仅三步即可完成Django项目的部署！
