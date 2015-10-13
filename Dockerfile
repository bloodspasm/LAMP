FROM ubuntu:trusty
MAINTAINER Fernando Mayo <fernando@tutum.co>, Feng Honglin <hfeng@tutum.co>

# ReSet Source
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty main multiverse restricted universe" > /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty-security main multiverse restricted universe" > /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty-updates main multiverse restricted universe" > /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty-proposed universe restricted multiverse main" > /etc/apt/sources.list
RUN echo "deb http://mirrors.163.com/ubuntu/ trusty-backports main multiverse restricted universe" > /etc/apt/sources.list

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
  apt-get -y install supervisor git apache2 libapache2-mod-php5 mysql-server php5-mysql pwgen php-apc php5-mcrypt && \
  echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server
RUN mkdir -p /var/run/sshd && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config && sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
  
  
# Add image configuration and scripts
ADD set_root_pw.sh /set_root_pw.sh
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD runssh.sh /runssh.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL utils
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
RUN chmod 755 /*.sh

# config to enable .htaccess
ADD apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Configure /app folder with sample app
RUN git clone https://git.oschina.net/zhanggangbz/wordpress431.git /app
RUN mkdir -p /app && rm -fr /var/www/html && ln -s /app /var/www/html
RUN chown -R www-data:www-data /app/wp-content /var/www/html
RUN chmod -R 777 /app
RUN chmod -R 777 /var/www/html

#Enviornment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 50M
ENV PHP_POST_MAX_SIZE 50M
ENV AUTHORIZED_KEYS **None**

# Add volumes for MySQL 
VOLUME  ["/var/lib/mysql" ]

EXPOSE 22 80 3306
CMD ["/run.sh"]
