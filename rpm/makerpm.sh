#!/bin/bash
# Copyright 2017 Frank Breedijk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#set -x
UPSTREAM_VERSION=$1
COMMITS=$2
if [ -z $VERSION ]; then
    echo "Trying to determine version and commit count from git"
    FULLVERSION=$(git describe)
    UPSTREAM_VERSION=$(echo $FULLVERSION|sed 's/\-.*//')
    COMMITS=$(echo $FULLVERSION|sed 's/^[0-9\.]*\-//'|sed 's/\-.*//')
    if [[ "$UPSTREAM_VERSION" == "$COMMITS" ]]; then
        COMMITS=0
    fi
fi

[ -z $UPSTREAM_VERSION ] && echo "We need a version number as first argument" && exit
[ -z $COMMITS ] && echo "We a commit count as second argument" && exit

VERSION="$UPSTREAM_VERSION"
BRANCH=$(git branch | grep '*'|awk '{print $2}')

[ ! -d build ] && mkdir build
[ -d $DIR ] && rm -rf $DIR

if [[ "$BRANCH" == "master" ]] || [[ "$BRANCH" == "rpm-build" ]] ; then
    if [[ ! -z $SECCUBUS_GPG_KEY ]]; then
        echo Setting up gpg
        set +x
        echo $SECCUBUS_GPG_KEY | sed 's/\\n/\n/g' > /tmp/gpg.key
        gpg --import --batch --yes /tmp/gpg.key
        rm /tmp/gpg.key
        echo "%_gpg_name Frank Breedijk" > ~/.rpmmacros
        SIGN=" --sign "
    fi
fi

echo "Creating directories"
mkdir -p /root/rpmbuild/SOURCES

echo "Copying files"
(cd /tmp; rm -f seccubus-$VERSION ; ln -s /root/project /tmp/seccubus-$VERSION;tar -czf /root/rpmbuild/SOURCES/seccubus-$VERSION.tar.gz --exclude "seccubus-$VERSION/tmp" --exclude "seccubus-$VERSION/build" seccubus-$VERSION/*)

echo "Building"
cat /root/project/rpm/seccubus.spec | sed "s/master$/$VERSION/" | sed "s/^Release\\:    0$/Release:    $COMMITS/" >/root/rpmbuild/SOURCES/seccubus.spec
rpmbuild $SIGN -ba /root/rpmbuild/SOURCES/seccubus.spec
find /root/rpmbuild -name "*.rpm" -exec cp {} /root/project/build \;

exit
