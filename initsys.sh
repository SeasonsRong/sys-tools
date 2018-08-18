#!/bin/bash
#
menu(){
cat << eof
+---------------------------------------+
+     *********系统初始化**********     + 
+---------------------------------------+
+      1、配置网卡                      +
+      2、关闭防火墙                    +
+      3、关闭Selinux                   +
+      4、修改ssh端口、关闭ssh的DNS解析 +
+         GSSAPI认证、禁止root远程登陆  +
+      5、退出程序                      +
+      6、配置ISO yum源                 +
+      7、设置主机名                    +
+---------------------------------------+

eof
}

ipcfg(){
    echo "系统中网卡如下："
    echo 
    ifconfig|grep flags|awk -F: '{print $1}'
    echo
    read -p "请选择需要修改的网卡：" netname
    read -p "请选择需要修改的网卡的IP：" ipaddr
    read -p "请选择需要修改的网卡的子网掩码【1-32】：" prefix
    read -p "请选择需要修改的网卡网关：" gw
    read -p "请选择需要修改的网卡首选DNS：" dns1
    read -p "请选择需要修改的网卡备用DNS：" dns2

#可以将太长的文件名定义成变量
    sed -ri '2,$d' /etc/sysconfig/network-scripts/ifcfg-${netname}
    sed -ri '$a \BOOTPROTO=none\nONBOOT=yes\nNAME='"$netname"'\nDEVICE='"$netname"'' /etc/sysconfig/network-scripts/ifcfg-${netname}
    sed -ri '$a \IPADDR='"$ipaddr"'\nPREFIX='"$prefix"'\nGATEWAY='"$gw"'\nDNS1='"$dns1"'\nDNS2='"$dns2"'' /etc/sysconfig/network-scripts/ifcfg-${netname}
    nmcli con reload
    nmcli con up $netname
    echo "网络配置成功！您的网络配置信息如下:"
    ipnew=$(ifconfig $netname|grep netmask|awk '{print $2}')
    masknew=$(ifconfig $netname|grep netmask|awk '{print $4}')
    gwnew=$(route -n|sed -n '3p' |awk '{print $2}')
    dns1new=$(sed -n '2p' /etc/resolv.conf |awk '{print $2}')
    dns2new=$(sed -n '3p' /etc/resolv.conf |awk '{print $2}')
    echo "网卡：" $netname
    echo "网卡的IP：" $ipnew
    echo "网卡的子网掩码【1-32】：" $masknew
    echo "网卡网关：" $gwnew
    echo "网卡首选DNS：" $dns1new
    echo "网卡备用DNS：" $dns2new
}

firew(){
    systemctl stop firewalld
    systemctl disable firewalld
    systemctl mask firewalld
    echo "永久关闭防火墙成功！"
}

selinux(){
    setenforce 0
    sed -ri --follow-symlinks '/^SELINUX=/c \SELINUX=disabled' /etc/sysconfig/selinux
    echo "永久关闭SElinux成功！"
}
ssh(){
    read -p "请输入新的ssh端口号：" ssh_port
    sed -ri '/^#Port/c \Port '"$ssh_port"'' /etc/ssh/sshd_config
    echo "ssh端口修改成功，新的端口号为$ssh_port！"
    sed -ri '/UseDNS/c \UseDNS no' /etc/ssh/sshd_config
    sed -ri '/GSSAPIAuthentication/c \GSSAPIAuthentication no' /etc/ssh/sshd_config
    sed -ri '/GSSAPICleanupCredentials/c \GSSAPICleanupCredentials no' /etc/ssh/sshd_config
    sed -ri '/^#PermitRootLogin/c \PermitRootLogin no' /etc/ssh/sshd_config
    systemctl restart sshd
    echo "关闭DNS解析和GSSAPI完成！"
    echo "关闭ssh远程root登陆功能完成！"
     
}
isoyum(){
mkdir -p /etc/yum.repos.d/bak
mv /etc/yum.repos.d/Cent* /etc/yum.repos.d/bak/
if [ -d /media/centos74 ];then
    mount /dev/sr0 /media/centos74
else
    mkdir -p /media/centos74
    mount /dev/sr0 /media/centos74
fi

cat << eof > /etc/yum.repos.d/iso.repo
[iso]
name=iso
baseurl=file:///media/centos74
gpgcheck=0
enable=1
eof

yum repolist|grep iso

}

sethostname(){
echo "当前主机名为：$(hostname)"
read -p "请输入新的主机名：" hname
hostnamectl set-hostname $hname
echo "主机名修改成功，当前主机名为：$(hostname)！"
}

menu

while true;do
    read -p "请输入选项【1-7】:" choice
    case $choice in
    1)
        ipcfg
        ;;
    2)
        firew
        ;;
    3)
        selinux
        ;;
    4)
        ssh
        ;;
    5)
        exit 0
        ;;
    6)
        isoyum
        ;;
    7)
        sethostname
        ;;
esac

done

