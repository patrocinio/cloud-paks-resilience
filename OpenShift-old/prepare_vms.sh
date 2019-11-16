#export POOL_ID=8a85f99967a2c0880167af1b2ded5d33
export POOL_ID=8a85f9996b49869e016bbca2b0e21edf

function change_certificate {
  cd /etc/rhsm/ca
  cp katello-server-ca.pem katello-server-ca.pem.original
  cp redhat-uep.pem katello-server-ca.pem
}

function register_satellite {
  subscription-manager unregister
  subscription-manager register --username=$REDHAT_USER --password=$REDHAT_PASSWORD \
   --serverurl=https://subscription.rhsm.redhat.com:443/subscription \
   --baseurl=https://cdn.redhat.com --force
}

function install_subscriptions {
  subscription-manager repos --disable="*"
  subscription-manager refresh
  subscription-manager attach --pool=$POOL_ID
}

function enable_yum_repos {
  subscription-manager repos --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.11-rpms" \
    --enable="rhel-7-server-ansible-2.6-rpms" \
    --enable="rh-gluster-3-client-for-rhel-7-server-rpms"
  yum update -y
}

function install_packages {
  yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct glusterfs-fuse
}

function install_docker {
  yum install -y docker-1.13.1
}

function configure_docker_storage {
  cat > /etc/sysconfig/docker-storage-setup <<EOF
STORAGE_DRIVER=overlay2
DEVS=/dev/xvdc
CONTAINER_ROOT_LV_NAME=dockerlv
CONTAINER_ROOT_LV_SIZE=100%FREE
CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
VG=dockervg
EOF

  wipefs --all --force /dev/xvdc
  docker-storage-setup
}

function stop_docker {
  systemctl stop docker
}

function start_docker {
  systemctl daemon-reload
  systemctl enable docker
  systemctl start docker
}

function enable_network_manager {
  service NetworkManager start
  chkconfig NetworkManager on
}

function set_selinux_enforcing {
  sed -i s/^SELINUX=.*$/SELINUX=enforcing/ /etc/selinux/config
  setenforce Enforcing
}

function remove_ip6_entries {
  sed -i "s/^::/#::/g" /etc/hosts
}

function fix_resolv_conf {
  echo "namesever 8.8.8.8" >  /etc/origin/node/resolv.conf
}

#change_certificate
#register_satellite
#install_subscriptions
#enable_yum_repos
#install_packages
#install_docker
#stop_docker
#configure_docker_storage
#start_docker
#enable_network_manager
#set_selinux_enforcing
remove_ip6_entries
fix_resolv_conf
