#!/bin/bash
# Run script as obia user with wheel group/sudo access

OUTPUT_FILE_NAME=environmentSpecifications.txt
ORACLE_USER_ACCOUNT=obia11g
ORACLE_GROUP_NAME=oinstall

if [ -f $OUTPUT_FILE_NAME ]; then
   rm -rf $OUTPUT_FILE_NAME;
else
   touch $OUTPUT_FILE_NAME;
   chmod 664 $OUTPUT_FILE_NAME;
fi;

echo Command: id $ORACLE_USER_ACCOUNT >> $OUTPUT_FILE_NAME
id $ORACLE_USER_ACCOUNT >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo grep $ORACLE_GROUP_NAME /etc/group >> $OUTPUT_FILE_NAME
sudo grep $ORACLE_GROUP_NAME /etc/group >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo -l -U $ORACLE_USER_ACCOUNT >> $OUTPUT_FILE_NAME
sudo -l -U $ORACLE_USER_ACCOUNT >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo 'Command: sudo cat /etc/*-release' >> $OUTPUT_FILE_NAME
sudo cat /etc/*-release >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: locale >> $OUTPUT_FILE_NAME
locale >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: 'env | sort' >> $OUTPUT_FILE_NAME
env | sort >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: 'ulimit -Su' >> $OUTPUT_FILE_NAME
ulimit -Su >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: 'ulimit -Hu' >> $OUTPUT_FILE_NAME
ulimit -Hu >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: 'ulimit -Sn' >> $OUTPUT_FILE_NAME
ulimit -Sn >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: 'ulimit -Hn' >> $OUTPUT_FILE_NAME
ulimit -Hn >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: 'sudo /usr/sbin/lsof | wc -l' >> $OUTPUT_FILE_NAME
sudo /usr/sbin/lsof | wc -l >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo grep $ORACLE_USER_ACCOUNT /etc/security/limits.conf >> $OUTPUT_FILE_NAME
sudo grep $ORACLE_USER_ACCOUNT /etc/security/limits.conf >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo 'Command: sudo grep $ORACLE_USER_ACCOUNT /etc/security/limits.d/*.conf' >> $OUTPUT_FILE_NAME
sudo grep $ORACLE_USER_ACCOUNT /etc/security/limits.d/*.conf >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo cat /etc/fstab >> $OUTPUT_FILE_NAME
sudo cat /etc/fstab >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo df -h >> $OUTPUT_FILE_NAME
sudo df -h >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo cat /etc/sysctl.conf >> $OUTPUT_FILE_NAME
sudo cat /etc/sysctl.conf >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo uname -r >> $OUTPUT_FILE_NAME
sudo uname -r >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo uname -m >> $OUTPUT_FILE_NAME
sudo uname -m >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo 'Command: sudo cat /proc/cpuinfo | grep '\''model name'\'' | sort | uniq' >> $OUTPUT_FILE_NAME
sudo cat /proc/cpuinfo | grep 'model name' | sort | uniq >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo 'Command: sudo cat /proc/cpuinfo | grep '\''physical id'\'' | sort | uniq | wc -l' >> $OUTPUT_FILE_NAME
sudo cat /proc/cpuinfo | grep 'physical id' | sort | uniq | wc -l >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo 'Command: sudo cat /proc/cpuinfo | grep '\''processor'\'' | sort | uniq | wc -l' >> $OUTPUT_FILE_NAME
sudo cat /proc/cpuinfo | grep 'processor' | sort | uniq | wc -l >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo free -m >> $OUTPUT_FILE_NAME
sudo free -m >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo cat /etc/hosts >> $OUTPUT_FILE_NAME
sudo cat /etc/hosts >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo ip addr show >> $OUTPUT_FILE_NAME
sudo ip addr show >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo ss -al >> $OUTPUT_FILE_NAME
sudo ss -al >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo Command: sudo getenforce >> $OUTPUT_FILE_NAME
sudo getenforce >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo 'Command: sudo firewall-cmd --zone=public --permanent --list-services' >> $OUTPUT_FILE_NAME
sudo firewall-cmd --zone=public --permanent --list-services >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo 'Command: sudo firewall-cmd --zone=public --permanent --list-ports' >> $OUTPUT_FILE_NAME
sudo firewall-cmd --zone=public --permanent --list-ports >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME

echo 'Command: sudo rpm -q --qf "%{n}-%{v}-%{r} %{arch}\n" binutils compat-libcap1 compat-libstdc++-33.i686 compat-libstdc++-33.x86_64 gcc gcc-c++ glibc.i686 glibc.x86_64 glibc-devel.x86_64 libaio.x86_64 libaio-devel.x86_64 libgcc.i686 libgcc.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++-devel.x86_64 ksh make ocfs2-tools sysstat numactl.x86_64 numactl-devel.x86_64 motif.x86_64 motif-devel.x86_64 libXext.i686 libXext.x86_64 libXtst.i686 libXtst.x86_64 libXi.i686 libXi.x86_64 bc perl unzip lsof' >> $OUTPUT_FILE_NAME
sudo rpm -q --qf "%{n}-%{v}-%{r} %{arch}\n" binutils compat-libcap1 compat-libstdc++-33.i686 compat-libstdc++-33.x86_64 gcc gcc-c++ glibc.i686 glibc.x86_64 glibc-devel.x86_64 libaio.x86_64 libaio-devel.x86_64 libgcc.i686 libgcc.x86_64 libstdc++.i686 libstdc++.x86_64 libstdc++-devel.x86_64 ksh make ocfs2-tools sysstat numactl.x86_64 numactl-devel.x86_64 motif.x86_64 motif-devel.x86_64 libXext.i686 libXext.x86_64 libXtst.i686 libXtst.x86_64 libXi.i686 libXi.x86_64 bc perl unzip lsof >> $OUTPUT_FILE_NAME 2>&1
echo $'\n' >> $OUTPUT_FILE_NAME