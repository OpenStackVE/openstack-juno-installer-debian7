#!/bin/bash
#
# Instalador desatendido para Openstack Juno sobre DEBIAN
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Octubre del 2014
#
# Script de instalacion y preparacion de cinder
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
	mkdir -p /etc/openstack-control-script-config
else
	echo "No puedo acceder a mi archivo de configuración"
	echo "Revise que esté ejecutando el instalador/módulos en el directorio correcto"
	echo "Abortando !!!!."
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/db-installed ]
then
	echo ""
	echo "Proceso de BD verificado - continuando"
	echo ""
else
	echo ""
	echo "Este módulo depende de que el proceso de base de datos"
	echo "haya sido exitoso, pero aparentemente no lo fue"
	echo "Abortando el módulo"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/keystone-installed ]
then
	echo ""
	echo "Proceso principal de Keystone verificado - continuando"
	echo ""
else
	echo ""
	echo "Este módulo depende del proceso principal de keystone"
	echo "pero no se pudo verificar que dicho proceso haya sido"
	echo "completado exitosamente - se abortará el proceso"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/cinder-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

echo "Instalando paquetes para Cinder"

echo "keystone keystone/auth-token password $SERVICE_TOKEN" > /tmp/keystone-seed.txt
echo "keystone keystone/admin-password password $keystoneadminpass" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-password-confirm password $keystoneadminpass" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-user string admin" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-tenant-name string $keystoneadminuser" >> /tmp/keystone-seed.txt
echo "keystone keystone/region-name string $endpointsregion" >> /tmp/keystone-seed.txt
echo "keystone keystone/endpoint-ip string $keystonehost" >> /tmp/keystone-seed.txt
echo "keystone keystone/register-endpoint boolean false" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-email string $keystoneadminuseremail" >> /tmp/keystone-seed.txt
echo "keystone keystone/admin-role-name string $keystoneadmintenant" >> /tmp/keystone-seed.txt
echo "keystone keystone/configure_db boolean false" >> /tmp/keystone-seed.txt
echo "keystone keystone/create-admin-tenant boolean false" >> /tmp/keystone-seed.txt

debconf-set-selections /tmp/keystone-seed.txt

echo "glance-common glance/admin-password password $glancepass" > /tmp/glance-seed.txt
echo "glance-common glance/auth-host string $keystonehost" >> /tmp/glance-seed.txt
echo "glance-api glance/keystone-ip string $keystonehost" >> /tmp/glance-seed.txt
echo "glance-common glance/paste-flavor select keystone" >> /tmp/glance-seed.txt
echo "glance-common glance/admin-tenant-name string $keystoneadmintenant" >> /tmp/glance-seed.txt
echo "glance-api glance/endpoint-ip string $glancehost" >> /tmp/glance-seed.txt
echo "glance-api glance/region-name string $endpointsregion" >> /tmp/glance-seed.txt
echo "glance-api glance/register-endpoint boolean false" >> /tmp/glance-seed.txt
echo "glance-common glance/admin-user	string $keystoneadminuser" >> /tmp/glance-seed.txt
echo "glance-common glance/configure_db boolean false" >> /tmp/glance-seed.txt
echo "glance-common glance/rabbit_host string $messagebrokerhost" >> /tmp/glance-seed.txt
echo "glance-common glance/rabbit_password password $brokerpass" >> /tmp/glance-seed.txt
echo "glance-common glance/rabbit_userid string $brokeruser" >> /tmp/glance-seed.txt

debconf-set-selections /tmp/glance-seed.txt

echo "cinder-common cinder/admin-password password $cinderpass" > /tmp/cinder-seed.txt
echo "cinder-api cinder/region-name string $endpointsregion" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/configure_db boolean false" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/admin-tenant-name string $keystoneadmintenant" >> /tmp/cinder-seed.txt
echo "cinder-api cinder/register-endpoint boolean false" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/auth-host string $keystonehost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/start_services boolean false" >> /tmp/cinder-seed.txt
echo "cinder-api cinder/endpoint-ip string $cinderhost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/volume_group string cinder-volumes" >> /tmp/cinder-seed.txt
echo "cinder-api cinder/keystone-ip string $keystonehost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/admin-user string $keystoneadminuser" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/rabbit_password password $brokerpass" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/rabbit_host string $messagebrokerhost" >> /tmp/cinder-seed.txt
echo "cinder-common cinder/rabbit_userid string $brokeruser" >> /tmp/cinder-seed.txt

debconf-set-selections /tmp/cinder-seed.txt

aptitude -y install libzookeeper-mt2 libcfg4 libcpg4

dpkg -i libs/sheepdog/*.deb

aptitude -y install cinder-api cinder-common cinder-scheduler cinder-volume python-cinderclient tgt open-iscsi

sed -r -i 's/CINDER_ENABLE\=false/CINDER_ENABLE\=true/' /etc/default/cinder-common

source $keystone_admin_rc_file

echo "Listo"

/etc/init.d/cinder-api stop
/etc/init.d/cinder-api stop
/etc/init.d/cinder-scheduler stop
/etc/init.d/cinder-scheduler stop
/etc/init.d/cinder-volume stop
/etc/init.d/cinder-volume stop


rm -f /tmp/cinder-seed.txt
rm -f /tmp/glance-seed.txt
rm -f /tmp/keystone-seed.txt

echo ""
echo "Configurando Cinder"

openstack-config --set /etc/cinder/api-paste.ini filter:authtoken paste.filter_factory  "keystonemiddleware.auth_token:filter_factory"
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken service_protocol http
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken service_host $keystonehost
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken service_port 5000
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken auth_protocol http
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken auth_host $keystonehost
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken admin_tenant_name $keystoneservicestenant
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken admin_user $cinderuser
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken admin_password $cinderpass
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken auth_port 35357
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken auth_uri http://$keystonehost:5000/v2.0/
openstack-config --set /etc/cinder/api-paste.ini filter:authtoken identity_uri http://$keystonehost:35357

openstack-config --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen 0.0.0.0
openstack-config --set /etc/cinder/cinder.conf DEFAULT api_paste_config /etc/cinder/api-paste.ini
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_host $glancehost
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT debug False
openstack-config --set /etc/cinder/cinder.conf DEFAULT verbose False
openstack-config --set /etc/cinder/cinder.conf DEFAULT use_syslog False


case $brokerflavor in
"qpid")
        openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend cinder.openstack.common.rpc.impl_qpid
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_hostname $messagebrokerhost
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_username $brokeruser
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_password $brokerpass
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_reconnect_limit 0
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_reconnect true
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_reconnect_interval_min 0
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_reconnect_interval_max 0
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_heartbeat 60
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_protocol tcp
        openstack-config --set /etc/cinder/cinder.conf DEFAULT qpid_tcp_nodelay True
        ;;

"rabbitmq")
        openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend cinder.openstack.common.rpc.impl_kombu
        openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_host $messagebrokerhost
        openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_port 5672
        openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_use_ssl false
        openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_userid $brokeruser
        openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_password $brokerpass
        openstack-config --set /etc/cinder/cinder.conf DEFAULT rabbit_virtual_host $brokervhost
        ;;
esac

openstack-config --set /etc/cinder/cinder.conf DEFAULT iscsi_helper tgtadm
openstack-config --set /etc/cinder/cinder.conf DEFAULT volume_group cinder-volumes
openstack-config --set /etc/cinder/cinder.conf DEFAULT volume_driver cinder.volume.drivers.lvm.LVMISCSIDriver
openstack-config --set /etc/cinder/cinder.conf DEFAULT logdir /var/log/cinder
openstack-config --set /etc/cinder/cinder.conf DEFAULT state_path /var/lib/cinder
openstack-config --set /etc/cinder/cinder.conf DEFAULT lock_path /var/lib/cinder/tmp
openstack-config --set /etc/cinder/cinder.conf DEFAULT volumes_dir /var/lib/cinder/volumes/
openstack-config --set /etc/cinder/cinder.conf DEFAULT rootwrap_config /etc/cinder/rootwrap.conf
openstack-config --set /etc/cinder/cinder.conf DEFAULT iscsi_ip_address $cinder_iscsi_ip_address


case $dbflavor in
"mysql")
        openstack-config --set /etc/cinder/cinder.conf database connection mysql://$cinderdbuser:$cinderdbpass@$dbbackendhost:$mysqldbport/$cinderdbname
        ;;
"postgres")
        openstack-config --set /etc/cinder/cinder.conf database connection postgresql://$cinderdbuser:$cinderdbpass@$dbbackendhost:$psqldbport/$cinderdbname
        ;;
esac

openstack-config --set /etc/cinder/cinder.conf database retry_interval 10
openstack-config --set /etc/cinder/cinder.conf database idle_timeout 3600
openstack-config --set /etc/cinder/cinder.conf database min_pool_size 1
openstack-config --set /etc/cinder/cinder.conf database max_pool_size 10
openstack-config --set /etc/cinder/cinder.conf database max_retries 100
openstack-config --set /etc/cinder/cinder.conf database pool_timeout 10

openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_host $keystonehost
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_user $cinderuser
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken admin_password $cinderpass
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken signing_dirname /tmp/keystone-signing-cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://$keystonehost:5000/v2.0/
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken identity_uri http://$keystonehost:35357


openstack-config --set /etc/cinder/cinder.conf DEFAULT notification_driver cinder.openstack.common.notifier.rpc_notifier

if [ $ceilometerinstall == "yes" ]
then
        openstack-config --set /etc/cinder/cinder.conf DEFAULT control_exchange cinder
fi


sync
sleep 2
sync
sleep 2

su cinder -s /bin/sh -c "cinder-manage db sync"

echo ""
echo "Levantando servicios de Cinder"

echo "include /etc/tgt/conf.d/*.conf" >> /etc/tgt/targets.conf

#
# Parche para DEBIAN7 - No trae el init script de tgtd - bug ??
#
cp ./libs/tgtd.sh /etc/init.d/tgtd
chmod 755 /etc/init.d/tgtd
chkconfig tgtd on


/etc/init.d/cinder-api restart
chkconfig cinder-api on
/etc/init.d/cinder-scheduler restart
chkconfig cinder-scheduler on
/etc/init.d/cinder-volume restart
/etc/init.d/open-iscsi restart
chkconfig cinder-volume on
chkconfig open-iscsi on
/etc/init.d/tgtd restart

echo "Listo"

echo ""
echo "Aplicando reglas de IPTABLES"

iptables -A INPUT -p tcp -m multiport --dports 3260,8776 -j ACCEPT
/etc/init.d/iptables-persistent save

testcinder=`dpkg -l cinder-api 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testcinder == "0" ]
then
	echo ""
	echo "Falló la instalación de cinder - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/cinder-installed
	date > /etc/openstack-control-script-config/cinder
fi

echo "Listo"

echo ""
echo "Cinder Instalado"
echo ""



