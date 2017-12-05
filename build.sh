#!/bin/bash -e

DIR=$PWD

distro=$(lsb_release -cs)

git config --global user.name "Robert Nelson"
git config --global user.email robertcnelson@gmail.com

export NODE_PATH=/usr/local/lib/node_modules

npm_options="--unsafe-perm=true --progress=false --loglevel=error --prefix /usr/local"

echo "Resetting: /usr/local/lib/node_modules/"
rm -rf /usr/local/lib/node_modules/* || true

npm_git_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		echo "Resetting: /usr/local/lib/node_modules/${npm_project}/"
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		echo "Resetting: /tmp/${git_project}/"
		rm -rf /tmp/${git_project}/ || true
	fi

	git clone -b ${git_branch} ${git_user}/${git_project} /tmp/${git_project}
	if [ -d /tmp/${git_project}/ ] ; then
		echo "Cloning: ${git_user}/${git_project}"
		cd /tmp/${git_project}/
		package_version=$(cat package.json | grep version | awk -F '"' '{print $4}' || true)
		git_version=$(git rev-parse --short HEAD)

		cd /tmp/
		echo "TERM=dumb ${node_bin} ${npm_bin} pack ${npm_project}/"
		tmp_package=$(TERM=dumb ${node_bin} ${npm_bin} pack ${npm_project}/ | tail -1)

		echo "TERM=dumb ${node_bin} ${npm_bin} install -g ${tmp_package} ${npm_options}"
		TERM=dumb ${node_bin} ${npm_bin} install -g ${tmp_package} ${npm_options}

		cd $DIR/
	fi

	wfile="${npm_project}-${package_version}-${git_version}-${node_version}"
	cd /usr/local/lib/node_modules/
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -hcJf ${wfile}.tar.xz ${npm_project}/
	cd -

	if [ ! -f ./deploy/${distro}/${wfile}.tar.xz ] ; then
		cp -v /usr/local/lib/node_modules/${wfile}.tar.xz ./deploy/${distro}/
		echo "New Build: ${wfile}.tar.xz"
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		rm -rf /tmp/${git_project}/
	fi
}

npm_pkg_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	cd /tmp/
	echo "TERM=dumb ${node_bin} ${npm_bin} pack ${npm_project}@${package_version}"
	tmp_package=$(TERM=dumb ${node_bin} ${npm_bin} pack ${npm_project}@${package_version} | tail -1)

	echo "TERM=dumb ${node_bin} ${npm_bin} install -g ${tmp_package} ${npm_options}"
	TERM=dumb ${node_bin} ${npm_bin} install -g ${tmp_package} ${npm_options}

	cd $DIR/

	wfile="${npm_project}-${package_version}-${node_version}"
	cd /usr/local/lib/node_modules/
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -hcJf ${wfile}.tar.xz ${npm_project}/
	cd -

	if [ ! -f ./deploy/${distro}/${wfile}.tar.xz ] ; then
		cp -v /usr/local/lib/node_modules/${wfile}.tar.xz ./deploy/${distro}/
		echo "New Build: ${wfile}.tar.xz"
	fi
}

npm_install () {
	node_bin="/usr/bin/nodejs"
	npm_bin="/usr/bin/npm"

	unset node_version
	node_version=$(${node_bin} --version || true)

	unset npm_version
	npm_version=$(${node_bin} ${npm_bin} --version || true)


	echo "npm: [`${node_bin} ${npm_bin} --version`]"
	echo "node: [`${node_bin} --version`]"

	npm_project="npm"
	package_version="4.6.1"
	npm_pkg_install
}

npm_install
