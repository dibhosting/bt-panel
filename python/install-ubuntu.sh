#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
echo "
+----------------------------------------------------------------------
| Bt-WebPanel 4.x FOR Ubuntu/Debian
+----------------------------------------------------------------------
| Copyright © 2015-2017 BT-SOFT(http://www.bt.cn) All rights reserved.
+----------------------------------------------------------------------
| The WebPanel URL will be http://SERVER_IP:8888 when installed.
+----------------------------------------------------------------------
"

if [ `whoami` != "root" ];then
	echo -e "\033[31mError: Please run the script with root privileges on Ubuntu, for example: sudo bash install.sh\033[0m";
	exit;
fi

#自动选择下载节点
CN='125.88.182.172'
HK='103.224.251.79'
HK2='103.224.251.67'
US='128.1.164.196'
CN_PING=`ping -c 1 -w 1 $CN|grep time=|awk '{print $7}'|sed "s/time=//"`
HK_PING=`ping -c 1 -w 1 $HK|grep time=|awk '{print $7}'|sed "s/time=//"`
HK2_PING=`ping -c 1 -w 1 $HK2|grep time=|awk '{print $7}'|sed "s/time=//"`
US_PING=`ping -c 1 -w 1 $US|grep time=|awk '{print $7}'|sed "s/time=//"`
echo "$HK_PING $HK" > ping.pl
echo "$HK2_PING $HK2" >> ping.pl
echo "$US_PING $US" >> ping.pl
echo "$CN_PING $CN" >> ping.pl
nodeAddr=`sort -n -b ping.pl|sed -n '1p'|awk '{print $2}'`
if [ "$nodeAddr" = "" ];then
	nodeAddr=$HK
fi
download_Url=http://$nodeAddr:5880
rm -f ping.pl

setup_path=/www
port='8888'
if [ -f $setup_path/server/panel/data/port.pl ];then
	port=`cat $setup_path/server/panel/data/port.pl`
fi

startTime=`date +%s`

#数据盘自动分区
fdiskP(){
	
	for i in `cat /proc/partitions|grep -v name|grep -v ram|awk '{print $4}'|grep -v '^$'|grep -v '[0-9]$'|grep -e 'vd' -e 'sd' -e 'xv'`;
	do
		#判断/www是否被挂载
		isR=`df -P|grep $setup_path`
		if [ "$isR" != "" ];then
			echo 'Warning: The /www directory has been mounted.'
			return;
		fi
		#判断是否存在未分区磁盘
		isP=`fdisk -l /dev/$i |grep -v 'bytes'|grep "$i[1-9]*"`
		if [ "$isP" = "" ];then
				#开始分区
				fdisk -S 56 /dev/$i << EOF
n
p
1


wq
EOF

			sleep 5
			#检查是否分区成功
			checkP=`fdisk -l /dev/$i|grep "/dev/${i}1"`
			if [ "$checkP" != "" ];then
				#格式化分区
				mkfs.ext4 /dev/${i}1
				mkdir $setup_path
				#挂载分区
				sed -i "/\/dev\/${i}1/d" /etc/fstab
				echo "/dev/${i}1    $setup_path    ext4    defaults    0 0" >> /etc/fstab
				mount -a
				df -h
			fi
		else
			#判断是否存在Windows磁盘分区
			isN=`fdisk -l /dev/$i|grep -v 'bytes'|grep -v "NTFS"|grep -v "FAT32"`
			if [ "$isN" = "" ];then
				echo 'Warning: The Windows partition was detected. For your data security, Mount manually.';
				return;
			fi
			
			#挂载已有分区
			checkR=`df -P|grep "/dev/$i"`
			if [ "$checkR" = "" ];then
					mkdir $setup_path
					sed -i "/\/dev\/${i}1/d" /etc/fstab
					echo "/dev/${i}1    $setup_path    ext4    defaults    0 0" >> /etc/fstab
					mount -a
					df -h
			fi
			
			#清理不可写分区
			echo 'True' > $setup_path/checkD.pl
			if [ ! -f $setup_path/checkD.pl ];then
					sed -i "/\/dev\/${i}1/d" /etc/fstab
					mount -a
					df -h
			else
					rm -f $setup_path/checkD.pl
			fi
		fi
	done
}
#fdiskP

ln -sf bash /bin/sh
apt-get install ruby -y
apt-get update -y
apt-get install lsb-release -y
apt-get install ntp ntpdate -y
/etc/init.d/ntp stop
update-rc.d ntp remove
cat >>~/.profile<<EOF
TZ='Asia/Shanghai'; export TZ
EOF
rm -rf /etc/localtime
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Synchronizing system time...'
ntpdate 0.asia.pool.ntp.org
apt-get upgrade -y
for pace in wget curl python python-dev python-imaging zip unzip openssl libssl-dev gcc libxml2 libxml2-dev libxslt zlib1g zlib1g-dev libjpeg-dev libpng-dev lsof libpcre3 libpcre3-dev cron;
do apt-get -y install $pace --force-yes; done
apt-get -y install python-pip python-dev

if [ -f '/www/server/mysql/bin/mysql_config' ];then
	SetLink
fi

if [ ! -f '/usr/bin/mysql_config' ];then
	apt-get install libmysqld-dev -y
fi

tmp=$(python -V 2>&1|awk '{print $2}')
pVersion=${tmp:0:3}

SetLink()
{
	mSetup_Path=/www/server/mysql
    ln -sf ${mSetup_Path}/bin/mysql /usr/bin/mysql
    ln -sf ${mSetup_Path}/bin/mysqldump /usr/bin/mysqldump
    ln -sf ${mSetup_Path}/bin/myisamchk /usr/bin/myisamchk
    ln -sf ${mSetup_Path}/bin/mysqld_safe /usr/bin/mysqld_safe
    ln -sf ${mSetup_Path}/bin/mysqlcheck /usr/bin/mysqlcheck
	ln -sf ${mSetup_Path}/bin/mysql_config /usr/bin/mysql_config
	
	rm -f /usr/lib/libmysqlclient.so.16
	rm -f /usr/lib64/libmysqlclient.so.16
	rm -f /usr/lib/libmysqlclient.so.18
	rm -f /usr/lib64/libmysqlclient.so.18
	rm -f /usr/lib/libmysqlclient.so.20
	rm -f /usr/lib64/libmysqlclient.so.20
	
	if [ -f "${mSetup_Path}/lib/libmysqlclient.so.18" ];then
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.18 /usr/lib/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.18 /usr/lib/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.18 /usr/lib/libmysqlclient.so.20
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.20
	elif [ -f "${mSetup_Path}/lib/mysql/libmysqlclient.so.18" ];then
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.18 /usr/lib/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.18 /usr/lib/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.18 /usr/lib/libmysqlclient.so.20
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.20
	elif [ -f "${mSetup_Path}/lib/libmysqlclient.so.16" ];then
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.16 /usr/lib/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.16 /usr/lib64/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.16 /usr/lib/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.16 /usr/lib64/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.16 /usr/lib/libmysqlclient.so.20
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.16 /usr/lib64/libmysqlclient.so.20
	elif [ -f "${mSetup_Path}/lib/mysql/libmysqlclient.so.16" ];then
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.16 /usr/lib/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.16 /usr/lib64/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.16 /usr/lib/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.16 /usr/lib64/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.16 /usr/lib/libmysqlclient.so.20
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.16 /usr/lib64/libmysqlclient.so.20
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient_r.so.16 /usr/lib/libmysqlclient_r.so.16
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient_r.so.16 /usr/lib64/libmysqlclient_r.so.16
	elif [ -f "${mSetup_Path}/lib/libmysqlclient.so.20" ];then
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.20 /usr/lib/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.20 /usr/lib64/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.20 /usr/lib/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.20 /usr/lib64/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.20 /usr/lib/libmysqlclient.so.20
		ln -sf ${mSetup_Path}/lib/libmysqlclient.so.20 /usr/lib64/libmysqlclient.so.20
	elif [ -f "${mSetup_Path}/lib/mysql/libmysqlclient.so.20" ];then
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.20 /usr/lib/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.20 /usr/lib64/libmysqlclient.so.16
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.20 /usr/lib/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.20 /usr/lib64/libmysqlclient.so.18
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.20 /usr/lib/libmysqlclient.so.20
		ln -sf ${mSetup_Path}/lib/mysql/libmysqlclient.so.20 /usr/lib64/libmysqlclient.so.20
	fi
	ldconfig
}


Install_Pillow()
{
	isSetup=`python -m PIL 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O Pillow-3.2.0.zip $download_Url/install/src/Pillow-3.2.0.zip -T 10
		unzip Pillow-3.2.0.zip
		rm -f Pillow-3.2.0.zip
		cd Pillow-3.2.0
		python setup.py install
		cd ..
		rm -rf Pillow-3.2.0
	fi
	isSetup=`python -m PIL 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		echo '=================================================';
		echo -e "\033[31mPillow installation failed. \033[0m";
		exit;
	fi
}

Install_psutil()
{
	isSetup=`python -m psutil 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O psutil-5.2.2.tar.gz $download_Url/install/src/psutil-5.2.2.tar.gz -T 10
		tar xvf psutil-5.2.2.tar.gz
		rm -f psutil-5.2.2.tar.gz
		cd psutil-5.2.2
		python setup.py install
		cd ..
		rm -rf psutil-5.2.2
	fi
	isSetup=`python -m psutil 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		echo '=================================================';
		echo -e "\033[31mpsutil installation failed. \033[0m";
		exit;
	fi
}

Install_mysqldb()
{
	isSetup=`python -m MySQLdb 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O MySQL-python-1.2.5.zip $download_Url/install/src/MySQL-python-1.2.5.zip -T 10
		unzip MySQL-python-1.2.5.zip
		rm -f MySQL-python-1.2.5.zip
		cd MySQL-python-1.2.5
		python setup.py install
		cd ..
		rm -rf MySQL-python-1.2.5
	fi
	
}

Install_chardet()
{
	isSetup=`python -m chardet 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O chardet-2.3.0.tar.gz $download_Url/install/src/chardet-2.3.0.tar.gz -T 10
		tar xvf chardet-2.3.0.tar.gz
		rm -f chardet-2.3.0.tar.gz
		cd chardet-2.3.0
		python setup.py install
		cd ..
		rm -rf chardet-2.3.0
	fi
	isSetup=`python -m chardet 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		echo '=================================================';
		echo -e "\033[31mchardet installation failed. \033[0m";
		exit;
	fi
}

Install_webpy()
{
	isSetup=`python -m web 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O web.py-0.38.tar.gz $download_Url/install/src/web.py-0.38.tar.gz -T 10
		tar xvf web.py-0.38.tar.gz
		rm -f web.py-0.38.tar.gz
		cd web.py-0.38
		python setup.py install
		cd ..
		rm -rf web.py-0.38
	fi
	
	isSetup=`python -m web 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		echo '=================================================';
		echo -e "\033[31mweb.py installation failed. \033[0m";
		exit;
	fi
}

pipArg=''

pip install --upgrade pip $pipArg
pip install psutil mysql-python chardet web.py virtualenv Pillow $pipArg


Install_Pillow
Install_psutil
Install_mysqldb
Install_chardet
Install_webpy

mkdir -p $setup_path/server/panel/logs
mkdir -p $setup_path/server/panel/vhost/apache
mkdir -p $setup_path/server/panel/vhost/nginx
mkdir -p $setup_path/server/panel/vhost/rewrite
wget -O $setup_path/server/panel/certbot-auto $download_Url/install/certbot-auto.init -T 5
chmod +x $setup_path/server/panel/certbot-auto


if [ -f '/etc/init.d/bt' ];then
	/etc/init.d/bt stop
fi

mkdir -p /www/server
mkdir -p /www/wwwroot
mkdir -p /www/wwwlogs
mkdir -p /www/backup/database
mkdir -p /www/backup/site

wget -O panel.zip $download_Url/install/src/panel.zip -T 10
wget -O /etc/init.d/bt $download_Url/install/src/bt.init -T 10
if [ -f "$setup_path/server/panel/data/default.db" ];then
	if [ -d "/$setup_path/server/panel/old_data" ];then
		rm -rf $setup_path/server/panel/old_data
	fi
	mkdir -p $setup_path/server/panel/old_data
	mv -f $setup_path/server/panel/data/default.db $setup_path/server/panel/old_data/default.db
	mv -f $setup_path/server/panel/data/system.db $setup_path/server/panel/old_data/system.db
	mv -f $setup_path/server/panel/data/aliossAs.conf $setup_path/server/panel/old_data/aliossAs.conf
	mv -f $setup_path/server/panel/data/qiniuAs.conf $setup_path/server/panel/old_data/qiniuAs.conf
	mv -f $setup_path/server/panel/data/iplist.txt $setup_path/server/panel/old_data/iplist.txt
	mv -f $setup_path/server/panel/data/port.pl $setup_path/server/panel/old_data/port.pl
fi

unzip -o panel.zip -d $setup_path/server/ > /dev/null

if [ -d "$setup_path/server/panel/old_data" ];then
	mv -f $setup_path/server/panel/old_data/default.db $setup_path/server/panel/data/default.db
	mv -f $setup_path/server/panel/old_data/system.db $setup_path/server/panel/data/system.db
	mv -f $setup_path/server/panel/old_data/aliossAs.conf $setup_path/server/panel/data/aliossAs.conf
	mv -f $setup_path/server/panel/old_data/qiniuAs.conf $setup_path/server/panel/data/qiniuAs.conf
	mv -f $setup_path/server/panel/old_data/iplist.txt $setup_path/server/panel/data/iplist.txt
	mv -f $setup_path/server/panel/old_data/port.pl $setup_path/server/panel/data/port.pl
	
	if [ -d "/$setup_path/server/panel/old_data" ];then
		rm -rf $setup_path/server/panel/old_data
	fi
fi

rm -f panel.zip

if [ ! -f $setup_path/server/panel/tools.py ];then
	echo -e "\033[31mERROR: Failed to download, please try again!\033[0m";
	echo '============================================'
	exit;
fi

rm -f $setup_path/server/panel/class/*.pyc
rm -f $setup_path/server/panel/*.pyc
python -m compileall $setup_path/server/panel
rm -f $setup_path/server/panel/class/*.py
rm -f $setup_path/server/panel/*.py

chmod 777 /tmp
chmod +x /etc/init.d/bt
update-rc.d bt defaults
chmod -R 600 $setup_path/server/panel
chmod +x $setup_path/server/panel/certbot-auto
chmod -R +x $setup_path/server/panel/script
echo "$port" > $setup_path/server/panel/data/port.pl
service bt start
password=`cat /dev/urandom | head -n 16 | md5sum | head -c 8`
cd $setup_path/server/panel/
username=`python tools.pyc panel $password`
cd ~
echo "$password" > $setup_path/server/panel/default.pl
chmod 600 $setup_path/server/panel/default.pl

isStart=`ps aux |grep 'python main.pyc'|grep -v grep|awk '{print $2}'`
if [ "$isStart" == '' ];then
	echo -e "\033[31mERROR: The BT-Panel service startup failed.\033[0m";
	echo '============================================'
	exit;
fi

if [ -f "/usr/sbin/ufw" ];then
	ufw allow 888,20,21,22,80,$port/tcp
	ufw allow 30000:40000/tcp
	ufw_status=`ufw status`
	echo y|ufw enable
	ufw default deny
	ufw reload
fi

pip install psutil chardet web.py MySQL-python psutil virtualenv $pipArg
if [ ! -d '/etc/letsencrypt' ];then

	mkdir -p /var/spool/cron
	if [ ! -f '/var/spool/cron/crontabs/root' ];then
		echo '' > /var/spool/cron/crontabs/root
		chmod 600 /var/spool/cron/crontabs/root
	fi
	isCron=`cat /var/spool/cron/crontabs/root|grep certbot.log`
	if [ "${isCron}" == "" ];then
		echo "30 2 * * * $setup_path/server/panel/certbot-auto renew >> $setup_path/server/panel/logs/certbot.log" >>  /var/spool/cron/crontabs/root
		chown 600 /var/spool/cron/crontabs/root
	fi
	service cron restart
	nohup $setup_path/server/panel/certbot-auto -n > /tmp/certbot-auto.log 2>&1 &
fi

address=""
address=`curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/getIpAddress`
if [ "$address" = "" ];then
	address="SERVER_IP"
fi

if [ "$address" != "SERVER_IP" ];then
	echo "$address" > $setup_path/server/panel/data/iplist.txt
fi


curl -sS --connect-timeout 10 -m 60 https://www.bt.cn/Api/SetupCount?type=Linux > /dev/null 2>&1

echo -e "=================================================================="
echo -e "\033[32mCongratulations! Install succeeded!\033[0m"
echo -e "=================================================================="
echo -e "Bt-Panel: http://$address:$port"
echo -e "username: $username"
echo -e "password: $password"
echo -e "\033[33mWarning:\033[0m"
echo -e "\033[33mIf you cannot access the panel, \033[0m"
echo -e "\033[33mrelease the following port (8888|888|80|443|20|21) in the security group\033[0m"
echo -e "=================================================================="

endTime=`date +%s`
((outTime=($endTime-$startTime)/60))
echo -e "Time consumed:\033[32m $outTime \033[0mMinute!"
rm -f install.sh