# Setup Highly Available applications with Docker Swarm and Gluster

A good design pattern for highly available applications is to deploy the application as a container on a Docker Swarm cluster with persistent storage provided by GlusterFS. GlusterFS is a fast shared filesystem that can keep the container volume in sync between multiple VMs running the Docker Swarm cluster. This pattern ensures high availability for your containerised application. In the event a VM dies, Docker Swarm will spin up the container on another VM. GlusterFS will ensure the container has access to the same data when it comes up.

## DockerSwarm-Glusterfs

Install the bash script that will install the Docker and GlusterFS in the VMs you have to set DNS settings for the installation process put below IP addresses to your IP cofiguration Netpan config or /etc/resolv.conf
```bash
178.22.122.100
185.51.200.2
```

-------------

## Create directories for GlusterFS storage

```bash

(DS-Worker01)# mkdir -p /gluster/bricks/1
(DS-Worker01)# echo '/dev/sdb /gluster/bricks/1 xfs defaults 0 0' >> /etc/fstab
(DS-Worker01)# mount -a
(DS-Worker01)# mkdir /gluster/bricks/1/brick(DS-Worker02)# mkdir -p /gluster/bricks/2
(DS-Worker02)# echo '/dev/sdb /gluster/bricks/2 xfs defaults 0 0' >> /etc/fstab
(DS-Worker02)# mount -a
(DS-Worker02)# mkdir /gluster/bricks/2/brick(DS-Worker03)# mkdir -p /gluster/bricks/3
(DS-Worker03)# echo '/dev/sdb /gluster/bricks/3 xfs defaults 0 0' >> /etc/fstab
(DS-Worker03)# mount -a
(DS-Worker03)# mkdir /gluster/bricks/3/brick
```

## Peer with other Gluster VMs

Now peer with other nodes from DS-Worker01:

```bash
(DS-Worker01)# gluster peer probe DS-Worker02
peer probe: success.
(DS-Worker01)# gluster peer probe DS-Worker03
peer probe: success.
(DS-Worker01)# gluster peer status
Number of Peers: 2Hostname: DS-Worker02
Uuid: 60861905-6adc-4841-8f82-216c661f9fe2
State: Peer in Cluster (Connected)Hostname: DS-Worker03
Uuid: 572fed90-61de-40dd-97a6-4255ed8744ce
State: Peer in Cluster (Connected)
```

## Setup the Gluster “replicated volume”

```bash
gluster volume create gfs \
replica 3 \
DS-Worker01:/gluster/bricks/1/brick \
DS-Worker02:/gluster/bricks/2/brick \
DS-Worker03:/gluster/bricks/3/brick

gluster volume start gfs
gluster volume status gfs

gluster volume info gfs

```

## Setup security and authentication for this volume

```bash
gluster volume set gfs auth.allow 172.18.81.54,172.18.81.55,172.18.81.56,172.18.81.57
```

## Mount the glusterFS volume where applications can access the files

We’ll mount the volume onto /mnt on each VM, and also append it to our /etc/fstab file so that it mounts on boot:

```bash
(DS-Worker01)# echo 'localhost:/gfs /mnt glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0' >> /etc/fstab
(DS-Worker01)# mount.glusterfs localhost:/gfs /mnt
(DS-Worker02)# echo 'localhost:/gfs /mnt glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0' >> /etc/fstab
(DS-Worker02)# mount.glusterfs localhost:/gfs /mnt
(DS-Worker03)# echo 'localhost:/gfs /mnt glusterfs defaults,_netdev,backupvolfile-server=localhost 0 0' >> /etc/fstab
(DS-Worker03)# mount.glusterfs localhost:/gfs /mnt
```

## Verify

```bash

df -Th
```

## Setup Docker Swarm

## Install docker to All Vms

Initialize Docker swarm from the DS-manager

```bash
docker swarm init --advertise-addr 172.18.81.54
```

## Add the three gluster VMs as swarm workers

```bash
DS-Worker01:~# docker swarm join --token SWMTKN-1-"TOKEN" 172.18.81.54:2377
This node joined a swarm as a worker.
DS-Worker02:~# docker swarm join --token SWMTKN-1-"TOKEN" 172.18.81.54:2377
This node joined a swarm as a worker.
DS-Worker03:~# docker swarm join --token SWMTKN-1-"TOKEN" 172.18.81.54:2377
This node joined a swarm as a worker.
DS-manager:~# docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
qjmuz0n8n770ryougk2tsb37x     DS-Worker01            Ready               Active                                  18.09.5
kcwsavrtzhvy038357p51lwl2     DS-Worker02            Ready               Active                                  18.09.5
ifnzgpk25p27y19vslee4v74x     DS-Worker03            Ready               Active                                  18.09.5
sz42o1yjz08t3x98aj82z33pe *   DS-manager             Ready               Active              Leader              18.09.5
```

## Use docker stack to deploy Wordpress and MySQL

```bash
docker stack deploy -c wordpress.yaml wordpress Ignoring unsupported options: restart
```
