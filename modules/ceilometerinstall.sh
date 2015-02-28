#!/bin/bash
#
# Instalador desatendido para Openstack Juno sobre DEBIAN
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Octubre del 2014
#
# Script de instalacion y preparacion de ceilometer
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

if [ -f /etc/openstack-control-script-config/ceilometer-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

echo ""
echo "Instalando paquetes para Ceilometer"
echo ""

if [ $ceilometer_in_compute_node = "no" ]
then
	echo "Instalando y configurando backend de base de datos MongoDB"
	echo ""
	aptitude -y install mongodb mongodb-clients mongodb-dev mongodb-server
	aptitude -y install libsnappy1 libgoogle-perftools4
	/etc/init.d/mongodb restart
fi

echo "ceilometer-api ceilometer/register-endpoint boolean false" > /tmp/ceilometer-seed.txt
echo "ceilometer-api ceilometer/region-name string $endpointsregion" >> /tmp/ceilometer-seed.txt
echo "ceilometer-api ceilometer/endpoint-ip string $ceilometerhost" >> /tmp/ceilometer-seed.txt
echo "ceilometer-api ceilometer/keystone-ip string $keystonehost" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/rabbit_password password $brokerpass" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/rabbit_userid string $brokeruser" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/rabbit_host string $messagebrokerhost" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/admin-password password $keystoneadminpass" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/admin-user string $keystoneadminuser" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/auth-host string $keystonehost" >> /tmp/ceilometer-seed.txt
echo "ceilometer-common ceilometer/admin-tenant-name string $keystoneadmintenant" >> /tmp/ceilometer-seed.txt

debconf-set-selections /tmp/ceilometer-seed.txt

echo ""
echo "Instalando paquetes de Ceilometer"
echo ""

if [ $ceilometer_in_compute_node == "no" ]
then
        echo ""
        echo "Paquetes para Controller o ALL-IN-ONE"

	aptitude -y install ceilometer-agent-central ceilometer-agent-compute ceilometer-api \
		ceilometer-collector ceilometer-common python-ceilometer python-ceilometerclient \
		libnspr4 libnspr4-dev python-libxslt1

	if [ $ceilometeralarms == "yes" ]
	then
		aptitude -y install ceilometer-alarm-evaluator ceilometer-alarm-notifier \
			ceilometer-agent-notification
	fi
else
	aptitude -y install ceilometer-agent-compute libnspr4 libnspr4-dev python-libxslt1
fi

if [ $ceilometer_in_compute_node = "no" ]
then
	sed -i "s/127.0.0.1/$mondbhost/g" /etc/mongodb.conf
	/etc/init.d/mongodb restart
fi

echo "Listo"
echo ""

if [ $ceilometer_in_compute_node == "no" ]
then
	/etc/init.d/ceilometer-agent-central stop
	/etc/init.d/ceilometer-agent-compute stop
	/etc/init.d/ceilometer-api stop
	/etc/init.d/ceilometer-collector stop

	if [ $ceilometeralarms == "yes" ]
	then
		/etc/init.d/ceilometer-alarm-evaluator stop
		/etc/init.d/ceilometer-alarm-notifier stop
		/etc/init.d/ceilometer-agent-notification stop
	fi
else
	/etc/init.d/ceilometer-agent-compute stop
fi

if [ $ceilometer_in_compute_node = "no" ]
then
	echo ""
	echo "Re-configurando backend de base de datos MongoDB"
	echo ""

	sed -i "s/127.0.0.1/$mondbhost/g" /etc/mongodb.conf
	sed -r -i "s/\#port\ =\ 27017/port\ =\ $mondbport/g" /etc/mongodb.conf
	echo "smallfiles = true" >> /etc/mongodb.conf

	/etc/init.d/mongodb stop
	/etc/init.d/mongodb stop
	killall -9 -u mongodb
	rm -f /var/lib/mongodb/journal/prealloc.*
	sleep 2
	sync
	sleep 2
	/etc/init.d/mongodb start
	sleep 2
	/etc/init.d/mongodb restart
	sleep 2
	/etc/init.d/mongodb status
	chkconfig mongodb on
	sync
	sleep 2

	mongo --host $mondbhost --eval "db = db.getSiblingDB(\"$mondbname\");db.addUser({user: \"$mondbuser\",pwd: \"$mondbpass\",roles: [ \"readWrite\", \"dbAdmin\" ]})"

fi

source $keystone_admin_rc_file

rm /tmp/ceilometer-seed.txt

echo ""
echo "Configurando Ceilometer"
echo ""

echo "#" >> /etc/ceilometer/ceilometer.conf

openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_host $keystonehost
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_user $ceilometeruser
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_password $ceilometerpass
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://$keystonehost:5000/v2.0
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken identity_uri http://$keystonehost:35357

openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT os_auth_url "http://$keystonehost:35357/v2.0"
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT os_tenant_name $keystoneservicestenant
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT os_password $ceilometerpass
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT os_username $ceilometeruser
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT os_auth_region $endpointsregion

openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials os_username $ceilometeruser
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials os_password $ceilometerpass
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name $keystoneservicestenant
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://$keystonehost:5000/v2.0/
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials os_region_name $endpointsregion
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials os_endpoint_type internalURL

openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT metering_api_port 8777
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT logdir /var/log/ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT os_auth_region $endpointsregion
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT host `hostname`
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT pipeline_cfg_file pipeline.yaml
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT collector_workers 2
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT notification_workers 2
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT hypervisor_inspector libvirt

openstack-config --del /etc/ceilometer/ceilometer.conf DEFAULT sql_connection
openstack-config --del /etc/ceilometer/ceilometer.conf DEFAULT sql_connection

openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT nova_control_exchange nova
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT glance_control_exchange glance
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT neutron_control_exchange neutron
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT cinder_control_exchange cinder

openstack-config --set /etc/ceilometer/ceilometer.conf publisher metering_secret $metering_secret

kvm_possible=`grep -E 'svm|vmx' /proc/cpuinfo|uniq|wc -l`
if [ $kvm_possible == "0" ]
then
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT libvirt_type qemu
else
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT libvirt_type kvm
fi

openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT debug false
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT verbose false
openstack-config --set /etc/ceilometer/ceilometer.conf database connection "mongodb://$mondbuser:$mondbpass@$mondbhost:$mondbport/$mondbname"
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT log_dir /var/log/ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT notification_topics notifications,glance_notifications
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT policy_file policy.json
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT policy_default_rule default
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT dispatcher database

case $brokerflavor in
"qpid")
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend ceilometer.openstack.common.rpc.impl_qpid
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_hostname $messagebrokerhost
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_port 5672
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_username $brokeruser
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_password $brokerpass
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_heartbeat 60
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_protocol tcp
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_tcp_nodelay true
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT qpid_topology_version 1
        ;;

"rabbitmq")
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend ceilometer.openstack.common.rpc.impl_kombu
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_host $messagebrokerhost
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_port 5672
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_use_ssl false
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_userid $brokeruser
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_password $brokerpass
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_virtual_host $brokervhost
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_retry_interval 1
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_retry_backoff 2
        openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_max_retries 0
        ;;
esac
 
 
openstack-config --set /etc/ceilometer/ceilometer.conf alarm evaluation_service ceilometer.alarm.service.SingletonAlarmService
openstack-config --set /etc/ceilometer/ceilometer.conf alarm partition_rpc_topic alarm_partition_coordination
openstack-config --set /etc/ceilometer/ceilometer.conf alarm evaluation_interval 60
openstack-config --set /etc/ceilometer/ceilometer.conf alarm record_history True
openstack-config --set /etc/ceilometer/ceilometer.conf api port 8777
openstack-config --set /etc/ceilometer/ceilometer.conf api host 0.0.0.0

openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT heat_control_exchange heat
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT control_exchange ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT http_control_exchanges nova
sed -r -i 's/http_control_exchanges\ =\ nova/http_control_exchanges=nova\nhttp_control_exchanges=glance\nhttp_control_exchanges=cinder\nhttp_control_exchanges=neutron\n/' /etc/ceilometer/ceilometer.conf
openstack-config --set /etc/ceilometer/ceilometer.conf publisher_rpc metering_topic metering

openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT instance_name_template $instance_name_template
openstack-config --set /etc/ceilometer/ceilometer.conf service_types neutron network
openstack-config --set /etc/ceilometer/ceilometer.conf service_types nova compute
openstack-config --set /etc/ceilometer/ceilometer.conf service_types kwapi energy
openstack-config --set /etc/ceilometer/ceilometer.conf service_types swift object-store

usermod -G nova ceilometer
usermod -G qemu ceilometer
usermod -G kvm ceilometer
usermod -G libvirt ceilometer
usermod -G libvirtd ceilometer
usermod -G libvirt-qemu ceilometer
usermod -G libvirt-kvm ceilometer


echo ""
echo "Aplicando reglas de IPTABLES"

iptables -A INPUT -p tcp -m multiport --dports 8777,$mondbport -j ACCEPT
/etc/init.d/iptables-persistent save

echo "Listo"

if [ $ceilometer_in_compute_node == "no" ]
then

	/etc/init.d/mongodb stop

	sync
	sleep 5
	sync

	/etc/init.d/mongodb start

	sync
	sleep 5
	sync
	chkconfig mongodb on

	if [ $ceilometer_without_compute == "no" ]
	then
		/etc/init.d/ceilometer-agent-compute start
		chkconfig ceilometer-agent-compute on
	else
		/etc/init.d/ceilometer-agent-compute stop
		chkconfig ceilometer-agent-compute off
	fi

	/etc/init.d/ceilometer-agent-central start
	chkconfig ceilometer-agent-central on

	/etc/init.d/ceilometer-api start
	chkconfig ceilometer-api on

	/etc/init.d/ceilometer-collector start
	chkconfig ceilometer-collector on

	if [ $ceilometeralarms == "yes" ]
	then
		/etc/init.d/ceilometer-alarm-notifier start
		chkconfig ceilometer-alarm-notifier on

		/etc/init.d/ceilometer-alarm-evaluator start
		chkconfig ceilometer-alarm-evaluator on

		/etc/init.d/ceilometer-agent-notification start
		chkconfig ceilometer-agent-notification on
	fi

else
	/etc/init.d/ceilometer-agent-compute start
	chkconfig ceilometer-agent-compute on
	/etc/init.d/ceilometer-agent-compute restart
fi

testceilometer=`dpkg -l ceilometer-common 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testceilometer == "0" ]
then
	echo ""
	echo "Falló la instalación de ceilometer - abortando el resto de la instalación"
	echo ""
	exit 0
else
        date > /etc/openstack-control-script-config/ceilometer-installed
        date > /etc/openstack-control-script-config/ceilometer
        if [ $ceilometeralarms == "yes" ]
        then
                date > /etc/openstack-control-script-config/ceilometer-installed-alarms
        fi
        if [ $ceilometer_in_compute_node == "no" ]
        then
                date > /etc/openstack-control-script-config/ceilometer-full-installed
        fi
        if [ $ceilometer_without_compute == "yes" ]
        then
                if [ $ceilometer_in_compute_node == "no" ]
                then
                        date > /etc/openstack-control-script-config/ceilometer-without-compute
                fi
        fi
fi

echo ""
echo "Ceilometer Instalado"
echo ""

