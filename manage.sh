#!/bin/bash

cd "$(/usr/bin/dirname "$0")"

PATH='/var/www'
REPO='nginx-config'
DIR="$(pwd)"
CURRENT_DIR="current\/"
NGINX_DIR='/etc/nginx'
SSL_DIR='/usr/local/ssl'

if [ "$2" = "local" ]; then
	CURRENT_DIR=""
	KEY=''
	SERVER='local.petrobids.com'
	DOMAIN='local.petrobids.com'
	BRANCH='development'
	if [ $3 ]; then
	PATH=$3
	fi
	if [ $4 ]; then
	NGINX_DIR=$4
	fi
else if [ "$2" = "development" ]; then
	KEY='etc/development.pem'
	SERVER='development.petrobids.com'
	DOMAIN='development.petrobids.com'
	BRANCH='development'
else if [ "$2" = "qa" ]; then
	KEY='etc/qa.pem'
	SERVER='demo.petrobids.com'
	DOMAIN='demo.petrobids.com'
	BRANCH='qa'
else if [ "$2" = "production" ]; then
	KEY='etc/production.pem'
	SERVER='app.petrobids.com'
	DOMAIN='app.petrobids.com'
	BRANCH='master'
fi
fi
fi
fi


function run_remote {
	/usr/bin/ssh -i $KEY ubuntu@$SERVER $1 
}

if [ "$1" = "bootstrap" ]; then
	echo "=================== update package manager"
    run_remote "sudo apt-get -y update"
	echo "=================== Installing dependencies"
	run_remote "sudo apt-get -y install python-software-properties libssl-dev git-core pkg-config build-essential curl gcc g++ openssl libreadline6 libreadline6-dev zlib1g zlib1g-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion traceroute"
	echo "=================== Install PostgreSQL Node.js NPM Redis Git and NGINX"
	run_remote "sudo apt-get -y install postgresql-9.3 nginx redis-server nodejs-dev nodejs npm git"
	echo "=================== Creating folders for use"
    run_remote "sudo mkdir -p /var/www"
    run_remote "sudo mkdir -p /var/www/source"
    run_remote "sudo mkdir -p /etc/nginx/certs"
	echo "=================== Done Bootstrapping, on to deploy!"
	$DIR/manage.sh deploy $2
else if [ "$1" = "deploy" ]; then
	echo "=================== clone repo"
	run_remote "test -d $PATH/$REPO || git clone git@bitbucket.org:satrails/$REPO.git $PATH/$REPO"
	echo "=================== update repo"
	run_remote "cd $PATH/$REPO && git fetch && git checkout $BRANCH && git merge origin/$BRANCH"
	echo "=================== install"
	run_remote "sudo $PATH/$REPO/manage.sh post-deploy $2"
else if [ "$1" = "post-deploy" ]; then
	echo "=================== add SSL certificates"
	#/usr/bin/sudo cat $DIR/ssl/satrailsCA.crt >> $DIR/ssl/petrobids.crt
	#/usr/bin/sudo ln -f -s $DIR/ssl/petrobids.crt $SSL_DIR/petrobids.crt
	#/usr/bin/sudo ln -f -s $DIR/ssl/petrobidsPK.key $SSL_DIR/petrobidsPK.key
	echo "=================== prepare config"
	#/usr/bin/sudo sed s/\${domain}/$DOMAIN/ $DIR/petrobids-app-conf.conf | /usr/bin/sudo sed s/\${subdir}/$CURRENT_DIR/ > $NGINX_DIR/sites-available/petrobids-app
	#/usr/bin/sudo ln -f -s $NGINX_DIR/sites-available/petrobids-app $NGINX_DIR/sites-enabled/petrobids-app
	echo "=================== restart nginx"
	/usr/bin/sudo service nginx status || /usr/bin/sudo service nginx start
    /usr/bin/sudo service nginx reload
else
	echo "USAGE"
	echo "./manage.sh bootstrap|deploy|post-deploy local|development|qa|production [path_to_apps path_to_nginx_dir]"
	echo "eg:"
	echo "./manage.sh deploy development"
	echo "./manage.sh install local"
fi
fi
fi