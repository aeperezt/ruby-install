#!/bin/sh
#check OS
RELEASE=`cat /etc/redhat-release`
echo $RELEASE
if [[ $RELEASE = *"CentOS"* ]]; then
  package_manager="yum"
  OS="CentOS"
fi
if [[ $RELEASE = *"Fedora"* ]]; then
  package_manager="dnf"
  OS="Fedora"
fi
#Install epel-release if centos
if [[ $OS = "CentOS" ]]; then
  $package_manager -y epel-release
fi
#install basic packages
BASIC=("vim" "wget" "firewalld" "zip" "xz")
for package in ${BASIC[@]}
do
  $package_manager -y install $package
done
#update the system
$package_manager -y update
#install servers require 
SERVERS=("mariadb-server" "mariadb" "nginx" "nodejs" "ImageMagick" "mariadb-devel")
for package in ${SERVERS[@]}
do
  $package_manager -y install $package
done
#install rpmbuild
$package_manager -y groupinstall "Development Tools"
#packages require to build ruby
RPMBUILD=("rpmdevtools" "rpm-build-libs"  "openssl" "libyaml" "libffi zlib" "gcc" "make" "readline-devel" "ncurses-devel" "gdbm-devel" "glibc-devel" "openssl-devel" "libyaml-devel" "libffi-devel" "zlib-devel")
for package in ${RPMBUILD[@]}
do
  $package_manager -y install $package
done
#installing Ruby, if we use Fedora we can use package version of Ruby, for use with RAILS 4.xx
if [[ $OS = "Fedora" ]]; then
  $package_manager -y install ruby ruby-devel rubygem-bundler
fi
if [[ $OS = "CentOS" ]]; then
  #create rpmbuild tree
  mkdir -p rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
  #download ruby version
  wget https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.9.tar.gz -P rpmbuild/SOURCES
  #download spec file
  wget https://raw.githubusercontent.com/tjinjin/automate-ruby-rpm/master/ruby22x.spec -P rpmbuild/SPECS
  #update spec ruby version
  sed -i 's/2.2.3/2.2.9/g' rpmbuild/SPECS/ruby22x.spec
  #build ruby 
  rpmbuild -bb rpmbuild/SPECS/ruby22x.spec
  #install ruby 
  yum -y localinstall rpmbuild/RPMS/x86_64/ruby-2.2.9-1.el7.centos.x86_64.rpm
  gem install bundler
fi
#start firewalld and set services
systemctl start firewalld
FW_Services=("http" "https")
for service in ${FW_Services[@]}
do
  firewall-cmd --add-service=$service
  firewall-cmd --permanent --add-service=$service
done
#enable servers
DAEMONS=("nginx" "mariadb" "firewalld")
for demon in ${DAEMONS[@]}
do
  systemctl enable $demon
  systemctl start $demon
done
