#!/bin/bash
#
# assumes that openstack credentails are set in this file
source /root/openrc


# Grab an image.  Cirros is a nice small Linux that's easy to deploy
wget -nc https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img

# Add it to glance so that we can use it in Openstack
glance add name='cirros image' is_public=true container_format=bare disk_format=qcow2 < cirros-0.3.0-x86_64-disk.img

# Capture the Image ID so taht we can call the right UUID for this image
IMAGE_ID=`glance index | grep 'cirros image' | head -1 |  awk -F' ' '{print $1}'`

login_user='cirros'


# create a pub/priv keypair
ssh-keygen -f /tmp/id_rsa -t rsa -N ''

#add the public key to nova.
nova --no-cache keypair-add --pub_key /tmp/id_rsa.pub key_cirros


instance_name='cirros_test_vm'

# Commented out due to quantum being disabled
# quantum net-create net1
# quantum subnet-create net1 10.0.0.0/24
# quantum_net=`quantum net-list | grep net1 | awk -F' ' '{print $2}'`
# nova --no-cache boot --flavor 1 --image $IMAGE_ID --key_name key_cirros --nic net-id=$quantum_net $instance_name

nova --no-cache boot --flavor 1 --image $IMAGE_ID --key_name key_cirros $instance_name

# let the system catch up
sleep 15

# Show the state of the system we just requested.
nova --no-cache show $instance_name

# wait for the server to boot
sleep 15

# Now add the floating IP we reserved earlier to the machine.
nova --no-cache add-floating-ip $instance_name $floating_ip
# Wait  and then try to SSH to the node, leveraging the private key
# we generated earlier.
sleep 15
ssh $login_user@$floating_ip -i /tmp/id_rsa
