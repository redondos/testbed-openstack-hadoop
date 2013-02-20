puppet-openstack-configure
==========================

Automate the configuration of OpenStack nodes using Puppet.

Easily spin off OpenStack Folsom (2012.2) controller, compute and storage nodes using Puppet on Amazon EC2/VPC.

* Controller:
    * mysql
    * rabbitmq
    * keystone
    * glance
    * nova

* Compute node:
    * nova (only compute and network components)

* Storage node:
    * swift (TODO)

Deployment
==========

Firewall
--------
Allow connectivity on Puppet, OpenStack and third party service ports.

* (EC2 -> Network & Security ->Elastic IPs)
Assigned Elastic IP address to controller: [CONTROLLER_IP]

* (EC2 -> Network & Security -> Security Groups)
    - Allowed incoming connections to port 8774 from any IP address.
    - Allowed incoming connections to ports 1-65535 from 10.0.0.0/8 subnet.

TODO: automate this process

FIXME: connectivity between controller and instances

VPC
---
Create a VPC according to http://docs.aws.amazon.com/AmazonVPC/latest/GettingStartedGuide/Wizard.html

* Create Internet Gateway
* Create Routing Table
* Create route 0.0.0.0/0 via IGW
* Associate route with VPC

Hostnames
---------
Controller hostname must match /master/
Compute hostnames must match /compute/

Configure node
--------------

    wget https://raw.github.com/redondos/puppet-openstack-configure/master/puppet-openstack-configure
    chmod +x puppet-openstack-configure
    sudo ./puppet-openstack-configure vpc-compute2.internal vpc-controller.internal 10.0.0.64

Sample output (compute node): http://pastebin.com/LAMKXPuu

Verify the setup
================

Services
--------

    root@openstack-puppet-controller:~# nova-manage service list
    Binary           Host                                 Zone             Status     State Updated_At
    nova-consoleauth openstack-puppet-controller.ec2.internal nova             enabled    :-)   2013-01-08 02:11:01
    nova-scheduler   openstack-puppet-controller.ec2.internal nova             enabled    :-)   2013-01-08 02:10:53
    nova-cert        openstack-puppet-controller.ec2.internal nova             enabled    :-)   2013-01-08 02:10:58
    nova-compute     openstack-puppet-compute1.ec2.internal nova             enabled    :-)   2013-01-08 02:10:58
    nova-network     openstack-puppet-compute1.ec2.internal nova             enabled    :-)   2013-01-08 02:10:58
    nova-network     openstack-puppet-compute2.ec2.internal nova             enabled    :-)   2013-01-08 02:11:00
    nova-compute     openstack-puppet-compute2.ec2.internal nova             enabled    :-)   2013-01-08 02:11:00
    nova-network     openstack-puppet-compute3.ec2.internal nova             enabled    :-)   2013-01-08 02:10:59
    nova-compute     openstack-puppet-compute3.ec2.internal nova             enabled    :-)   2013-01-08 02:10:59

Horizon web dashboard
---------------------

Check credentials in /root/openrc, by default 'admin'/'admin'

Login to horizon: http://[CONTROLLER_HOSTNAME]/horizon/

Sample: http://i.troll.ws/a0ab7990.png

Image upload and instance creation
----------------------------------

Script provided by Puppet recipes.

    wget https://raw.github.com/redondos/puppet-openstack-configure/master/test_nova.sh
    bash -x test_nova.sh


Credentials
-----------

    source /root/openrc

Keystone
--------

Default service token: keystone_admin_token

List tenants

    keystone --token keystone_admin_token tenant-list

List users

    keystone --token keystone_admin_token user-list

Change user password

    keystone --token keystone_admin_token user-password-update --pass admin <user id>

Glance
------

Upload image

    glance add name='cirros image' is_public=true container_format=bare disk_format=qcow2 < cirros-0.3.0-x86_64-disk.img

List images

    glance image-list

Nova
----

Upload keypair (use ssh-keygen if necessary)

    nova --no-cache keypair-add --pub_key ~/.ssh/id_rsa.pub $USER

List flavors

    nova flavor-list

Boot an instance

    imgid=$(glance index | awk '/cirros image/{print $1}')
    nova --no-cache boot --flavor 1 --image $imgid --key_name $USER cirros_test_vm

List and describe instances

    nova list
    nova show $(nova list | awk '/cirros_test_vm/{print $2}')

Spawn Ubuntu server instance
----------------------------

    wget http://uec-images.ubuntu.com/quantal/current/quantal-server-cloudimg-amd64.tar.gz
    tar zvxf quantal-server-cloudimg-amd64.tar.gz
    
    glance add name=quantal-server-cloudimg-amd64 disk_format=qcow2 container_format=bare < quantal-server-cloudimg-amd64.img
    
    imgid=$(glance index | awk '/quantal/{print $1; quit}')
    nova --no-cache boot --flavor 3 --image $imgid --key_name $USER quantal-server-amd64

Further reading
===============

Sharable openstack puppet dev environment. (vagrant/virtualbox) https://github.com/bodepd/puppetlabs-openstack_dev_env

