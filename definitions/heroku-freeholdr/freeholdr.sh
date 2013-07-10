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
