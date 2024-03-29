# Configure single node and multi-node openstack instances

# deploy a script that can be used to test nova
class { 'openstack::test_file': }

####### shared variables ##################
# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments

# assumes that eth0 is the public interface
$public_interface        = 'eth0'
# assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it.
$private_interface       = 'eth1'
# credentials
$admin_email             = 'root@localhost'
$admin_password          = 'admin'
$keystone_db_password    = 'keystone_db_pass'
$keystone_admin_token    = 'keystone_admin_token'
$nova_db_password        = 'nova_pass'
$nova_user_password      = 'nova_pass'
$glance_db_password      = 'glance_pass'
$glance_user_password    = 'glance_pass'
$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'
$fixed_network_range     = '172.16.0.0/24'
$floating_network_range  = '192.168.101.64/28'
$mysql_root_password     = 'root'
$cinder_root_password    = 'cinder_pass'
$cinder_user_password    = 'cinder_pass'
# switch this to true to have all service log at verbose
$verbose                 = false
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = false

#### end shared variables #################

# multi-node specific parameters
$controller_node_address  = 'openstack-puppet-controller.ec2.internal'
$controller_node_public   = $controller_node_address
$controller_node_internal = $controller_node_address
$sql_connection         = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"

# all nodes whose certname matches openstack_all should be
# deployed as all-in-one openstack installations.
node /openstack_all/ {

  include 'apache'

  class { 'openstack::all':
    public_address          => $ipaddress_eth0,
    public_interface        => $public_interface,
    private_interface       => $private_interface, 
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    libvirt_type            => 'qemu',
    floating_range          => $floating_network_range,
    fixed_range             => $fixed_network_range,
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => '127.0.0.1',
  }
}

node /controller/ {
  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => $floating_network_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => true,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    mysql_root_password     => $mysql_root_password,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    # export_resources        => false,
    secret_key              => secret,
    cinder                  => false
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }
}

node /compute/ {
  class { 'openstack::compute':
    public_interface   => $public_interface,
    private_interface  => $private_interface,
    internal_address   => $ipaddress_eth0,
    libvirt_type       => 'qemu',
    fixed_range        => $fixed_network_range,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
    multi_host         => true,
    sql_connection     => $sql_connection,
    nova_user_password => $nova_user_password,
    rabbit_host        => $controller_node_internal,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    glance_api_servers => "${controller_node_internal}:9292",
    vncproxy_host      => $controller_node_public,
    vnc_enabled        => true,
    verbose            => $verbose,
    manage_volumes     => true,
    nova_volume        => 'nova-volumes',
    cinder              => false
  }
}
