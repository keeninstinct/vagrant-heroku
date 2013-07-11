# postinstall.sh created from Mitchell's official lucid32/64 baseboxes

date > /etc/vagrant_box_build_time

# Apt-install various things necessary for Ruby, guest additions,
# etc., and remove optional things to trim down the machine.
apt-get -y update
apt-get -y upgrade
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install zlib1g-dev libssl-dev libreadline5-dev
apt-get -y install git-core vim

# Apt-install python tools and libraries
# libpq-dev lets us compile psycopg for Postgres
apt-get -y install python-setuptools python-dev libpq-dev pep8

# Setup sudo to allow no-password sudo for "admin"
cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=admin' /etc/sudoers
sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers

# Install NFS client
apt-get -y install nfs-common

# Install Ruby from source in /opt so that users of Vagrant
# can install their own Rubies using packages or however.
wget http://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p247.tar.bz2
tar jxf ruby-2.0.0-p247.tar.bz2
cd ruby-2.0.0-p247
./configure --prefix=/opt/ruby
make
make install
cd ..
rm -rf ruby-2.0.0-p247*
chown -R root:admin /opt/ruby
chmod -R g+w /opt/ruby

# Install RubyGems 2.0.3
wget http://production.cf.rubygems.org/rubygems/rubygems-2.0.3.tgz
tar xzf rubygems-2.0.3.tgz
cd rubygems-2.0.3
/opt/ruby/bin/ruby setup.rb
cd ..
rm -rf rubygems-2.0.3*

# Installing chef & Puppet
/opt/ruby/bin/gem install chef --no-ri --no-rdoc
/opt/ruby/bin/gem install puppet --no-ri --no-rdoc
/opt/ruby/bin/gem install bundler --no-ri --no-rdoc

# Add the Puppet group so Puppet runs without issue
groupadd puppet

# Install Foreman
/opt/ruby/bin/gem install foreman --no-ri --no-rdoc

# Install pip, virtualenv, and virtualenvwrapper
easy_install pip
pip install virtualenv
pip install virtualenvwrapper

# Add a basic virtualenvwrapper config to .bashrc
echo "export WORKON_HOME=/home/vagrant/.virtualenvs" >> /home/vagrant/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> /home/vagrant/.bashrc

# Install PostgreSQL 9.2.4
wget http://ftp.postgresql.org/pub/source/v9.2.4/postgresql-9.2.4.tar.bz2
tar jxf postgresql-9.2.4.tar.bz2
cd postgresql-9.2.4
./configure --prefix=/usr
make world
make install
cd ..
rm -rf postgresql-9.2.4*

# Initialize postgres DB
useradd -p postgres postgres
mkdir -p /var/pgsql/data
chown postgres /var/pgsql/data
su -c "/usr/bin/initdb -D /var/pgsql/data --locale=en_US.UTF-8 --encoding=UNICODE" postgres
mkdir /var/pgsql/data/log
chown postgres /var/pgsql/data/log

# Add 'vagrant' role
su -c 'createuser vagrant -s' postgres

# Start postgres
su -c '/usr/bin/pg_ctl start -l /var/pgsql/data/log/logfile -D /var/pgsql/data' postgres

# Start postgres at boot
sed -i -e 's/exit 0//g' /etc/rc.local
echo "su -c '/usr/bin/pg_ctl start -l /var/pgsql/data/log/logfile -D /var/pgsql/data' postgres" >> /etc/rc.local

# Install NodeJs for a JavaScript runtime
git clone https://github.com/joyent/node.git
cd node
git checkout v0.4.7
./configure --prefix=/usr
make
make install
cd ..
rm -rf node*

# Add /opt/ruby/bin to the global path as the last resort so
# Ruby, RubyGems, and Chef/Puppet are visible
echo 'PATH=$PATH:/opt/ruby/bin/'> /etc/profile.d/vagrantruby.sh

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /home/vagrant
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt

rm VBoxGuestAdditions_$VBOX_VERSION.iso

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp3/*

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

# Install Heroku toolbelt
wget -qO- https://toolbelt.heroku.com/install-ubuntu.sh | sh

# Install some libraries
apt-get -y install libxml2-dev libxslt-dev curl libcurl4-openssl-dev
apt-get -y install imagemagick libmagickcore-dev libmagickwand-dev

# Set locale
echo 'LC_ALL="en_US.UTF-8"' >> /etc/default/locale

### Install Freeholdr specific stuff ###

# Install Memcached 1.4.15
apt-get -y install libevent-dev libsasl2-dev

wget http://memcached.googlecode.com/files/memcached-1.4.15.tar.gz
tar xzf memcached-1.4.15.tar.gz
cd memcached-1.4.15
./configure --prefix=/usr --enable-sasl
make
make install
cd ..
rm -rf memcached-1.4.15*

# Install Redis
apt-get -y install tcl8.5 

wget http://download.redis.io/redis-stable.tar.gz
tar xzf redis-stable.tar.gz
cd redis-stable
make
cd src
cp redis-server /usr/bin/
cp redis-cli /usr/bin/
cp redis-benchmark /usr/bin/
cp redis-check-aof /usr/bin/
cp redis-check-dump /usr/bin/
cd ../..
rm -rf redis-stable*

# Install nginx 1.4.1
apt-get -y install libpcre3-dev 

wget http://nginx.org/download/nginx-1.4.1.tar.gz
tar xzf nginx-1.4.1.tar.gz
cd nginx-1.4.1
./configure --prefix=/usr --with-http_ssl_module
make
make install
cd ..
rm -rf nginx-1.4.1*

# Increase kernel shared memory for PostgreSQL so it can use more memory
printf "kernel.shmmax = 1053503488\nkernel.shmall = 257203" > /etc/sysctl.d/30-postgresql-shm.conf
sysctl -p /etc/sysctl.d/30-postgresql-shm.conf

# Allow vm.overcommit_memory for Redis or it complains and may not write to disk
printf "vm.overcommit_memory = 1" > /etc/sysctl.d/30-redis-overcommit.conf
sysctl -p /etc/sysctl.d/30-redis-overcommit.conf

# Manually adjust PostgreSQL configuration so it will use more memory if needed

# Clean up packages
apt-get clean

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces
exit
exit