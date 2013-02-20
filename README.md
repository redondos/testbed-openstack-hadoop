OpenStack nodes on Amazon Web Services
======================================

Automate the creation of EC2 instances and the configuration of OpenStack nodes
using Puppet.

Software used:
- Puppet
- Ubuntu Server 12.04
- OpenStack Folsom (2012.2)

    * Controller:
        * mysql
        * rabbitmq
        * keystone
        * glance
        * nova

    * Compute node:
        * nova (only compute and network components)

Deployment
==========

Brief:
-----
    ./aws-setup testbed && ./node-setup testbed

This command will set up one OpenStack controller and one compute instance on
Amazon VPC.

Options can be passed to these script to modify its settings (like how many
instances to start), --help will show all command-line options.


Detailed:
--------

There are many ways to use these scripts, they can run standalone (in order to
have more fine-tuned control of the nodes, or using node-setup, which configures
the nodes automatically.

The first step is to start some instances on EC2. These instances need to run
inside our own Virtual Private Cloud (VPC), so that other EC2 users don't have
access to your machines.

aws-setup can set up VPCs, subnets, internet gateways, elastic IPs and spawn a
given number of instances.

    ./aws-setup [options] <testbed-name>

    e.g. ./aws-setup -n 10 -s 10.0.0.0/24 openstack

This command will create a VPC with subnet 10.0.0.0/24 and 10 EC2 instances.
The first one will be named "openstack-controller" and the rest will be
numbered: "openstack-computeN". The testbed configuration will be saved in
"openstack/openstack.desc", with items in key=value format.

After the nodes are created, they can be configured using node-setup:

    ./node-setup <testbed-name>

    e.g. ./node-setup openstack

This will read configuration from openstack/openstack.desc and set up the
nodes using puppet-openstack-configure, which installs a Puppet server on the
controller and runs the Puppet agent on all nodes. The puppetlabs-openstack
modules are used to configure the puppet manifest file, which defines how to
configure each instance.Progress will be output to the terminal and verbose
output will be saved to openstack/HOSTNAME.log (one file per instance).


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

Login to horizon: http://[CONTROLLER_HOSTNAME]/horizon/

Default username/password: 'admin'/'admin'

It can be changed in site.pp and re-running node-setup.

Project -> Images and snapshots -> Create image:
    Name: cirros
    Location: http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-i386-disk.img
    Format: QCOW2
    Public: yes

OpenStack instances can now be spawned from the Horizon dashboard by clicking
on the Launch button next to the image name. (Note: a keypair is not necessary to
access cirros images, but it will be for Ubuntu server cloud images.)

Credentials
-----------

    source <testbed-name>/openrc

Image upload and instance creation
----------------------------------

Script provided by Puppet recipes.

    bash -x test_nova.sh

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

