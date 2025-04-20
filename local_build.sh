#!/bin/bash
version="8.3"
printf " Building Janus for PHP $version\n"
./vendor/bin/zephir fullclean
./vendor/bin/zephir build
cp ext/modules/janus.so compiled/php$version-janus.so
sudo service php$version-fpm restart
echo " Janus build complete"