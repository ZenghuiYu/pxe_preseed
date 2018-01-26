#!/bin/bash
#
# This script is executed after the first reboot to install compute-node automatically.
#
# To be considered: error handling, programming style, log saving
#
# $@: all parameters

local_ip=`ifconfig eth0 | grep Bcast | awk {'print $2'} | awk -F ":" {'print $2'}`
HOSTNAME=`hostname`
home_path=/opt/openstack

#
# add repo
#
function add_repo()
{
LOG "add repo"
mv /etc/apt/sources.list /etc/apt/sources.list.bak
echo "deb file:/opt/openstack openstack/" >> /etc/apt/sources.list
cp /opt/openstack/source/packages.tar.gz /root/
tar zxf /root/packages.tar.gz -C /opt/
apt-get update
}

#
# modify config
#
function update_config()
{
chmod 755 -R $home_path
cd $home_path/etc
for i in `find ./ -type f`;do sed -i "s/openstack-ip/$local_ip/g" $i;done
# TODO: OPENSTACK_PASSWD is exported in function init_env().
for i in `find ./ -type f`;do sed -i "s/openstack-passwd/$OPENSTACK_PASSWD/g" $i;done
}

#
# init env
#
function init_env()
{
apt-get install ntp curl -y --force-yes
cp $home_path/etc/ntp/ntp-client/ntp.conf /etc/
cp $home_path/etc/networking.1404 /etc/init.d/networking
cat >> /etc/profile <<EOF
export OS_USERNAME=admin
export OS_PASSWORD=admin_pass@2014
export OS_TENANT_NAME=admin
export OPENSTACK_PASSWD=hengtian
export OS_AUTH_URL=http://hty-controller:35357/v2.0

export OS_SERVICE_TOKEN=abc
export OS_SERVICE_ENDPOINT=http://hty-controller:35357/v2.0
export LANG=en_US.UTF-8
EOF
source /etc/profile

cp $home_path/etc/hosts/hosts-compute /etc/hosts
sed -i "s/HOSTNAME/$HOSTNAME/" /etc/hosts
sed -i "s/128.0.0.0/1,0.0.0.0/1" /etc/hosts
}

#
# install nova-compute
#
function install_nova_compute()
{
/bin/sh $home_path/scripts/nova/nova-compute-install.sh
/bin/sh $home_path/scripts/nova/nova-compute-conf-install.sh 
sleep 3
sh $home_path/scripts/nova/nova-compute-init.sh
sleep 3
}

#
# install cinder-volume
#
function install_cinder_volume()
{
/bin/sh $home_path/scripts/cinder/cinder-volume-install.sh
/bin/sh $home_path/scripts/cinder/cinder-volume-conf-install.sh 
sleep 3
sh $home_path/scripts/cinder/cinder-volume-init.sh
sleep 3
}

#
# install patch
#
function install_patch()
{
/bin/sh $home_path/scripts/nova/nova-compute-patch-install.sh
sleep 3
/bin/sh $home_path/scripts/nagios/nagios-compute.sh
sleep 3
/bin/sh $home_path/scripts/cinder/cinder-volume-patch-install.sh
sleep 3
/bin/sh $home_path/scripts/keystone/keystone-patch-install.sh
}

#
# upgrade kernel
#
function upgrade_kernel()
{
cd $home_path/source/linux-3.18.0
dpkg -i linux-headers*
dpkg -i linux-image*
cd /lib/firmware/3.18.0-031800-generic/bnx2
cp bnx2-mips-06-6.2.1.fw bnx2-mips-06-6.2.3.fw
cp bnx2-mips-09-6.2.1a.fw bnx2-mips-09-6.2.1b.fw

ln -s /etc/apparmor.d/usr.sbin.libvirtd  /etc/apparmor.d/disable/
ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper  /etc/apparmor.d/disable/
apparmor_parser -R  /etc/apparmor.d/usr.sbin.libvirtd
apparmor_parser -R  /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper
}

#
# install elk
#
function install_elk()
{
/bin/sh $home_path/scripts/elk/elk-install.sh
}

#
# install clear
#
function install_clear()
{
/bin/sh $home_path/scripts/hengtianyun/hengtianyun-controller-conf-install.sh
/bin/sh $home_path/scripts/clear/hardware.sh
cp $home_path/scripts/clear/hty-compute_service.sh /root/
cp -rf $home_path/scripts/power/compute/watch_services /root
cp $home_path/compute-install.log /root
cp -r $home_path/source/ceph-monitor/ /root/
/bin/sh $home_path/scripts/nova/compute-setup.sh
/bin/sh $home_path/scripts/clear/hty-compute_optimization.sh
/bin/sh $home_path/scripts/clear/clear.sh
}

#
# main function
#
function main()
{
add_repo
update_config
init_env
#init_network
#install_db
#install_rabbitmq
#install_keystone
#install_glance
#install_dependencies
install_nova_compute
install_cinder_volume
#install_nagios-compute-client
#install_neutron
#install_mongodb
#install_ceilometer
#install_heat
#install_horizon
#install_qemu
#install_ceph
install_patch
upgrade_kernel
install_elk
install_clear
#check
reboot
}

main $@
