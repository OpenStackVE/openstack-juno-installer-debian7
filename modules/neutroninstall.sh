#!/bin/bash
#
# Instalador desatendido para Openstack Juno sobre DEBIAN
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Octubre del 2014
#
# Script de instalacion y preparacion de neutron
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

if [ -f /etc/openstack-control-script-config/neutron-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi

echo "Instalando Paquetes para NEUTRON"

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

echo "neutron-common neutron/admin-password password $keystoneadminpass" > /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-password password $keystoneadminpass" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/keystone-ip string $keystonehost" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/local_ip string $neutron_computehost" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/configure_db boolean false" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/region-name string $endpointsregion" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/region-name string $endpointsregion" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/register-endpoint boolean false" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/tenant_network_type select vlan" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/admin-user string $keystoneadminuser" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-user string $keystoneadminuser" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/tunnel_id_ranges string 0" >> /tmp/neutron-seed.txt
echo "neutron-plugin-openvswitch neutron-plugin-openvswitch/enable_tunneling boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/auth-host string $keystonehost" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/auth-host string $keystonehost" >> /tmp/neutron-seed.txt
echo "neutron-server neutron/endpoint-ip string $neutronhost" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/admin-tenant-name string $keystoneadmintenant" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-tenant-name string $keystoneadmintenant" >> /tmp/neutron-seed.txt
echo "openswan openswan/install_x509_certificate boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/rabbit_password password $brokerpass" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/rabbit_userid string $brokeruser" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/rabbit_host string $messagebrokerhost" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/tunnel_id_ranges string 1" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/tenant_network_type select vlan" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/enable_tunneling boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/configure_db boolean false" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/plugin-select select ml2" >> /tmp/neutron-seed.txt
echo "neutron-common neutron/local_ip string $neutron_computehost" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron-metadata/auth-host string $neutronhost" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/admin-user string $keystoneadminuser" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron/region-name string $endpointsregion" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron-metadata/admin-password password $keystoneadminuser" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron-metadata/metadata_secret password $metadata_shared_secret" >> /tmp/neutron-seed.txt
echo "neutron-metadata-agent neutron-metadata/region-name string $endpointsregion" >> /tmp/neutron-seed.txt


debconf-set-selections /tmp/neutron-seed.txt

echo ""

if [ $neutron_in_compute_node == "yes" ]
then
	aptitude -y install neutron-common \
		python-neutron \
		python-neutronclient \
		neutron-plugin-ml2 \
		neutron-plugin-openvswitch-agent
else
	echo "Instalando haproxy"
	dpkg -i ./libs/haproxy*.deb

	aptitude -y install neutron-server \
		neutron-common neutron-dhcp-agent \
		neutron-l3-agent neutron-lbaas-agent \
		neutron-metadata-agent python-neutron \
		python-neutronclient \
		neutron-plugin-ml2 \
		neutron-plugin-openvswitch-agent

	echo NEUTRON_PLUGIN_CONFIG=\"/etc/neutron/plugins/ml2/ml2_conf.ini\" > /etc/default/neutron-server

	if [ $vpnaasinstall == "yes" ]
	then
		aptitude -y install neutron-vpn-agent openswan openswan-modules-dkms
		/etc/init.d/ipsec stop
		chkconfig ipsec off
	fi

	if [ $neutronmetering == "yes" ]
	then
		aptitude -y install neutron-metering-agent
	fi
fi

echo ""
echo "Listo"

echo ""
echo "Preparando configuración inicial de Neutron"

# ML2
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

rm -f /tmp/neutron-seed.txt
rm -f /tmp/cinder-seed.txt
rm -f /tmp/glance-seed.txt
rm -f /tmp/keystone-seed.txt

if [ $neutron_in_compute_node == "yes" ]
then
	/etc/init.d/neutron-plugin-openvswitch-agent stop
	/etc/init.d/neutron-plugin-openvswitch-agent stop
else
	/etc/init.d/neutron-plugin-openvswitch-agent stop
	/etc/init.d/neutron-plugin-openvswitch-agent stop
	/etc/init.d/neutron-dhcp-agent stop
	/etc/init.d/neutron-dhcp-agent stop
	/etc/init.d/neutron-lbaas-agent stop
	/etc/init.d/neutron-lbaas-agent stop
	/etc/init.d/neutron-metadata-agent stop
	/etc/init.d/neutron-metadata-agent stop
	/etc/init.d/neutron-l3-agent stop
	/etc/init.d/neutron-l3-agent stop
	/etc/init.d/neutron-server stop
	/etc/init.d/neutron-server stop
	if [ $vpnaasinstall == "yes" ]
	then
		/etc/init.d/neutron-vpn-agent stop
		/etc/init.d/neutron-vpn-agent stop
	fi
	if [ $neutronmetering == "yes" ]
	then
		/etc/init.d/neutron-metering-agent stop
		/etc/init.d/neutron-metering-agent stop
	fi
fi

echo "Listo"


if [ $neutron_in_compute_node == "no" ]
then

	echo ""
	echo "Configurando dnsmasq para Neutron"

	sleep 5
	cat /etc/dnsmasq.conf > $dnsmasq_config_file
	mkdir -p /etc/dnsmasq-neutron.d
	echo "user=neutron" >> $dnsmasq_config_file
	echo "group=neutron" >> $dnsmasq_config_file
	echo "conf-dir=/etc/dnsmasq-neutron.d" >> $dnsmasq_config_file
	echo "# Extra options for Neutron-DNSMASQ" > /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# Samples:" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# dhcp-option=option:ntp-server,192.168.1.1" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# dhcp-option = tag:tag0, option:ntp-server, 192.168.1.1" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# dhcp-option = tag:tag1, option:ntp-server, 192.168.1.1" >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# expand-hosts"  >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# domain=dominio-interno-uno.home,192.168.1.0/24"  >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	echo "# domain=dominio-interno-dos.home,192.168.100.0/24"  >> /etc/dnsmasq-neutron.d/neutron-dnsmasq-extra.conf
	sync
	sleep 5

	echo "Listo"
	echo ""
fi

source $keystone_admin_rc_file

echo ""
echo "Aplicando Reglas de IPTABLES"
iptables -A INPUT -p tcp -m multiport --dports 9696 -j ACCEPT
iptables -A INPUT -p udp -m state --state NEW -m udp --dport 67 -j ACCEPT
iptables -A INPUT -p udp -m state --state NEW -m udp --dport 68 -j ACCEPT
iptables -t mangle -A POSTROUTING -p udp -m udp --dport 67 -j CHECKSUM --checksum-fill
iptables -t mangle -A POSTROUTING -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill
/etc/init.d/iptables-persistent save
echo "Listo"

echo ""
echo "Configurando Neutron"

sync
sleep 5
sync

echo "#" >> /etc/neutron/neutron.conf

openstack-config --set /etc/neutron/neutron.conf DEFAULT debug False
openstack-config --set /etc/neutron/neutron.conf DEFAULT verbose False
openstack-config --set /etc/neutron/neutron.conf DEFAULT log_dir /var/log/neutron
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host 0.0.0.0
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_port 9696
# openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
# WTF... Seriously !!
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin neutron.plugins.ml2.plugin.Ml2Plugin
openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf DEFAULT base_mac "$basemacspec"
openstack-config --set /etc/neutron/neutron.conf DEFAULT mac_generation_retries 16
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_lease_duration $dhcp_lease_duration
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_bulk True
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips False
openstack-config --set /etc/neutron/neutron.conf DEFAULT control_exchange neutron
openstack-config --set /etc/neutron/neutron.conf DEFAULT default_notification_level INFO
openstack-config --set /etc/neutron/neutron.conf DEFAULT notification_topics notifications
openstack-config --set /etc/neutron/neutron.conf DEFAULT state_path /var/lib/neutron
openstack-config --set /etc/neutron/neutron.conf DEFAULT lock_path /var/lib/neutron/lock

 
mkdir -p /var/lib/neutron/lock
chown neutron.neutron /var/lib/neutron/lock
 
openstack-config --set /etc/neutron/neutron.conf DEFAULT api_paste_config api-paste.ini


case $brokerflavor in
"qpid")
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname $messagebrokerhost
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_port 5672
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_username $brokeruser
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_password $brokerpass
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_heartbeat 60
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_protocol tcp
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_tcp_nodelay True
        openstack-config --set /etc/neutron/neutron.conf DEFAULT notification_driver neutron.openstack.common.notifier.rpc_notifier
        ;;

"rabbitmq")
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_kombu
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_host $messagebrokerhost
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_password $brokerpass
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_userid $brokeruser
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_port 5672
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_use_ssl false
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_virtual_host $brokervhost
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_max_retries 0
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_retry_interval 1
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_ha_queues false
        openstack-config --set /etc/neutron/neutron.conf DEFAULT notification_driver neutron.openstack.common.notifier.rpc_notifier
        ;;
esac

openstack-config --set /etc/neutron/neutron.conf agent root_helper "sudo neutron-rootwrap /etc/neutron/rootwrap.conf"

openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_host $keystonehost
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_user $neutronuser
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken admin_password $neutronpass
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$keystonehost:5000/v2.0
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken identity_uri http://$keystonehost:35357

openstack-config --set /etc/neutron/neutron.conf DEFAULT agent_down_time 60
openstack-config --set /etc/neutron/neutron.conf DEFAULT router_scheduler_driver neutron.scheduler.l3_agent_scheduler.ChanceScheduler
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 1
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_agent_notification True


nova_admin_tenant_id=`keystone tenant-get $keystoneservicestenant|grep "id"|awk '{print $4}'`

openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_url http://$novahost:8774/v2
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_region_name $endpointsregion
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_username $novauser
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_tenant_id $nova_admin_tenant_id
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_password $novapass
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_admin_auth_url http://$keystonehost:35357/v2.0
openstack-config --set /etc/neutron/neutron.conf DEFAULT report_interval 20
openstack-config --set /etc/neutron/neutron.conf DEFAULT notification_driver neutron.openstack.common.notifier.rpc_notifier
openstack-config --set /etc/neutron/neutron.conf DEFAULT api_workers 0

if [ $neutronmetering == "yes" ]
then
        thirdplugin=",metering"
else
        thirdplugin=""
fi

if [ $vpnaasinstall == "yes" ]
then
	# BUG: Existe un BUG en los paquetes de debian que previenen el uso de FWAAS
        # openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins "router,firewall,lbaas,vpnaas$thirdplugin"
        openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins "router,lbaas,vpnaas$thirdplugin"
else
	# BUG: Existe un BUG en los paquetes de debian que previenen el uso de FWAAS
        # openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins "router,firewall,lbaas$thirdplugin"
        openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins "router,lbaas$thirdplugin"
fi

echo "#" >> /etc/neutron/fwaas_driver.ini

openstack-config --set /etc/neutron/fwaas_driver.ini fwaas driver "neutron.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver"
openstack-config --set /etc/neutron/fwaas_driver.ini fwaas enabled True

if [ $vpnaasinstall == "yes" ]
then
        echo "#" >> /etc/neutron/vpn_agent.ini
        openstack-config --set /etc/neutron/vpn_agent.ini DEFAULT debug False
        openstack-config --set /etc/neutron/vpn_agent.ini DEFAULT interface_driver "neutron.agent.linux.interface.OVSInterfaceDriver"
        openstack-config --set /etc/neutron/vpn_agent.ini DEFAULT ovs_use_veth True
        openstack-config --set /etc/neutron/vpn_agent.ini DEFAULT use_namespaces True
        openstack-config --set /etc/neutron/vpn_agent.ini DEFAULT external_network_bridge ""
        openstack-config --set /etc/neutron/vpn_agent.ini vpnagent vpn_device_driver "neutron.services.vpn.device_drivers.ipsec.OpenSwanDriver"
        openstack-config --set /etc/neutron/vpn_agent.ini ipsec ipsec_status_check_interval 60
fi

if [ $neutronmetering == "yes" ]
then
        echo "#" >> /etc/neutron/metering_agent.ini
        openstack-config --set /etc/neutron/metering_agent.ini DEFAULT debug False
        openstack-config --set /etc/neutron/metering_agent.ini DEFAULT ovs_use_veth True
        openstack-config --set /etc/neutron/metering_agent.ini DEFAULT use_namespaces True
        openstack-config --set /etc/neutron/metering_agent.ini DEFAULT driver neutron.services.metering.drivers.iptables.iptables_driver.IptablesMeteringDriver
        openstack-config --set /etc/neutron/metering_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
        openstack-config --set /etc/neutron/metering_agent.ini DEFAULT measure_interval 30
        openstack-config --set /etc/neutron/metering_agent.ini DEFAULT report_interval 300
fi

echo "#" >> /etc/neutron/l3_agent.ini

openstack-config --set /etc/neutron/l3_agent.ini DEFAULT debug False
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT ovs_use_veth True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT use_namespaces True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT handle_internal_only_routers True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT send_arp_for_ha 3
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT periodic_interval 40
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT periodic_fuzzy_delay 5
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge ""
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT metadata_port 9697
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT enable_metadata_proxy True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT router_delete_namespaces True

sync
sleep 2
sync

echo "#" >> /etc/neutron/dhcp_agent.ini

openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT debug False
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT resync_interval 30
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT ovs_use_veth True
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT ovs_integration_bridge $integration_bridge
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT use_namespaces True
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT state_path /var/lib/neutron
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dnsmasq_config_file $dnsmasq_config_file
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_domain $dhcp_domain
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_delete_namespaces True
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT root_helper "sudo neutron-rootwrap /etc/neutron/rootwrap.conf"

sync
sleep 2
sync

case $dbflavor in
"mysql")
	openstack-config --set /etc/neutron/neutron.conf database connection mysql://$neutrondbuser:$neutrondbpass@$dbbackendhost:$mysqldbport/$neutrondbname
	;;
"postgres")
	openstack-config --set /etc/neutron/neutron.conf database connection postgresql://$neutrondbuser:$neutrondbpass@$dbbackendhost:$psqldbport/$neutrondbname
	;;
esac
 
openstack-config --set /etc/neutron/neutron.conf database retry_interval 10


#
# ML2
#

echo "#" >> /etc/neutron/plugins/ml2/ml2_conf.ini

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers "local,flat"
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers "openvswitch,l2population"
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types "flat"
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks "*"
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs enable_tunneling False
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs network_vlan_ranges $network_vlan_ranges
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip $neutron_computehost
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings $bridge_mappings

case $dbflavor in
"mysql")
        openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini database connection mysql://$neutrondbuser:$neutrondbpass@$dbbackendhost:$mysqldbport/$neutrondbname
        ;;
"postgres")
        openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini database connection postgresql://$neutrondbuser:$neutrondbpass@$dbbackendhost:$psqldbport/$neutrondbname
        ;;
esac

openstack-config --set /etc/neutron/neutron.conf database retry_interval 10
openstack-config --set /etc/neutron/neutron.conf database idle_timeout 3600
openstack-config --set /etc/neutron/neutron.conf database min_pool_size 1
openstack-config --set /etc/neutron/neutron.conf database max_pool_size 10
openstack-config --set /etc/neutron/neutron.conf database max_retries 100
openstack-config --set /etc/neutron/neutron.conf database pool_timeout 10

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini database retry_interval 10
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini database idle_timeout 3600
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini database min_pool_size 1
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini database max_pool_size 10
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini database max_retries 100
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini database pool_timeout 10

sync
sleep 2
sync
 
ln -f -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

echo "#" >> /etc/neutron/metadata_agent.ini
echo "#" >> /etc/neutron/api-paste.ini

openstack-config --set /etc/neutron/api-paste.ini filter:authtoken paste.filter_factory "keystonemiddleware.auth_token:filter_factory"
openstack-config --set /etc/neutron/api-paste.ini filter:authtoken auth_protocol http
openstack-config --set /etc/neutron/api-paste.ini filter:authtoken auth_host $keystonehost
openstack-config --set /etc/neutron/api-paste.ini filter:authtoken admin_tenant_name $keystoneservicestenant
openstack-config --set /etc/neutron/api-paste.ini filter:authtoken admin_user $neutronuser
openstack-config --set /etc/neutron/api-paste.ini filter:authtoken admin_password $neutronpass
openstack-config --set /etc/neutron/api-paste.ini filter:authtoken auth_port 35357
openstack-config --set /etc/neutron/api-paste.ini filter:authtoken auth_uri http://$keystonehost:5000/v2.0/
openstack-config --set /etc/neutron/api-paste.ini filter:authtoken identity_uri http://$keystonehost:35357

openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT debug False
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_url "http://$keystonehost:35357/v2.0"
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_region $endpointsregion
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_tenant_name $keystoneservicestenant
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_user $neutronuser
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT admin_password $neutronpass
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $novahost
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_port 8775
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $metadata_shared_secret


sync
sleep 2
sync

echo "#" >> /etc/neutron/lbaas_agent.ini

openstack-config --set /etc/neutron/lbaas_agent.ini DEFAULT periodic_interval 10
openstack-config --set /etc/neutron/lbaas_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/lbaas_agent.ini DEFAULT ovs_use_veth True
openstack-config --set /etc/neutron/lbaas_agent.ini DEFAULT device_driver neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver
openstack-config --set /etc/neutron/lbaas_agent.ini DEFAULT use_namespaces True
openstack-config --set /etc/neutron/lbaas_agent.ini DEFAULT user_group neutron
openstack-config --set /etc/neutron/lbaas_agent.ini haproxy user_group neutron

sync
sleep 2
sync

mkdir -p /etc/neutron/plugins/services/agent_loadbalancer
cp -v /etc/neutron/lbaas_agent.ini /etc/neutron/plugins/services/agent_loadbalancer/
chown root.neutron /etc/neutron/plugins/services/agent_loadbalancer/lbaas_agent.ini
sync

sync
sleep 2
sync

echo ""
echo "Listo"
echo ""

case $brokerflavor in
"qpid")
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_hostname $messagebrokerhost
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_port 5672
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_username $brokeruser
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_password $brokerpass
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_heartbeat 60
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_protocol tcp
        openstack-config --set /etc/neutron/neutron.conf DEFAULT qpid_tcp_nodelay True
        openstack-config --set /etc/neutron/neutron.conf DEFAULT notification_driver neutron.openstack.common.notifier.rpc_notifier
        ;;

"rabbitmq")
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend neutron.openstack.common.rpc.impl_kombu
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_host $messagebrokerhost
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_password $brokerpass
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_userid $brokeruser
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_port 5672
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_use_ssl false
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_virtual_host $brokervhost
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_max_retries 0
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_retry_interval 1
        openstack-config --set /etc/neutron/neutron.conf DEFAULT rabbit_ha_queues false
        openstack-config --set /etc/neutron/neutron.conf DEFAULT notification_driver neutron.openstack.common.notifier.rpc_notifier
        ;;
esac


sync
sleep 2
sync
 
echo ""
echo "Listo"
echo ""

echo ""
echo "Aprovisionando Base de Datos de NEUTRON"
echo ""

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade juno" neutron


echo "Activando Servicios de Neutron"
 
if [ $neutron_in_compute_node == "yes" ]
then
	/etc/init.d/neutron-server stop
	chkconfig neutron-server off

	/etc/init.d/neutron-dhcp-agent stop
	chkconfig neutron-dhcp-agent off

	/etc/init.d/neutron-l3-agent stop
	chkconfig neutron-l3-agent off

	/etc/init.d/neutron-lbaas-agent stop
	chkconfig neutron-lbaas-agent off

	/etc/init.d/neutron-metadata-agent stop
	chkconfig neutron-metadata-agent off

        if [ $vpnaasinstall == "yes" ]
        then
                /etc/init.d/neutron-vpn-agent stop
                chkconfig neutron-vpn-agent off
        fi

	if [ $neutronmetering == "yes" ]
	then
		/etc/init.d/neutron-metering-agent stop
		chkconfig neutron-metering-agent off
	fi

	/etc/init.d/neutron-plugin-openvswitch-agent start
	chkconfig neutron-plugin-openvswitch-agent on
else
	/etc/init.d/neutron-server start
	chkconfig neutron-server on

	/etc/init.d/neutron-dhcp-agent start
	chkconfig neutron-dhcp-agent on

	/etc/init.d/neutron-l3-agent start
	chkconfig neutron-l3-agent on

	/etc/init.d/neutron-lbaas-agent start
	chkconfig neutron-lbaas-agent on

	/etc/init.d/neutron-metadata-agent start
	chkconfig neutron-metadata-agent on


        if [ $vpnaasinstall == "yes" ]
        then
                /etc/init.d/neutron-vpn-agent start
                chkconfig neutron-vpn-agent on
        fi

	if [ $neutronmetering == "yes" ]
	then
		service neutron-metering-agent start
		chkconfig neutron-metering-agent on
	fi

	/etc/init.d/neutron-plugin-openvswitch-agent start
	chkconfig neutron-plugin-openvswitch-agent on
fi

echo "Listo"

echo ""
echo "Haciendo pausa de 10 segundos"
sync
sleep 10
sync
echo ""
echo "Continuando la instalación"
echo ""

# neutron net-create publica --shared --provider:network_type flat --provider:physical_network publica
if [ $neutron_in_compute_node == "no" ]
then
	if [ $network_create == "yes" ]
	then
		source $keystone_admin_rc_file

		for MyNet in $network_create_list
		do
			echo ""
			echo "Creando red $MyNet"
			neutron net-create $MyNet --shared --provider:network_type flat --provider:physical_network $MyNet
			echo ""
			echo "Red $MyNet creada !"
			echo ""
		done
	fi
fi

echo ""
echo "Haciendo pausa de 10 segundos"
echo ""
sync
sleep 10
sync
/etc/init.d/iptables-persistent save

echo "Continuando la instalación"

testneutron=`dpkg -l neutron-common 2>/dev/null|tail -n 1|grep -ci ^ii`
if [ $testneutron == "0" ]
then
	echo ""
	echo "Falló la instalación de neutron - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/neutron-installed
	date > /etc/openstack-control-script-config/neutron
	if [ $neutron_in_compute_node == "no" ]
	then
		date > /etc/openstack-control-script-config/neutron-full-installed
                if [ $vpnaasinstall == "yes" ]
                then
                        date > /etc/openstack-control-script-config/neutron-full-installed-vpnaas
                fi
		if [ $neutronmetering == "yes" ]
		then
			date > /etc/openstack-control-script-config/neutron-full-installed-metering
		fi
	fi
fi

echo ""
echo "Servicio Neutron Configurado y operativo"
echo ""


