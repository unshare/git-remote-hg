#!/bin/sh
#
# Copyright (c) 2016 Mark Nauwelaerts
#
# Base commands from hg-git tests:
# https://bitbucket.org/durin42/hg-git/src
#

test_description='Test git-hg-helper'

test -n "$TEST_DIRECTORY" || TEST_DIRECTORY=$(dirname $0)/
. "$TEST_DIRECTORY"/test-lib.sh

if ! test_have_prereq PYTHON
then
	skip_all='skipping remote-hg tests; python not available'
	test_done
fi

if ! python2 -c 'import mercurial' > /dev/null 2>&1
then
	skip_all='skipping remote-hg tests; mercurial not available'
	test_done
fi

setup () {
	cat > "$HOME"/.hgrc <<-EOF &&
	[ui]
	username = H G Wells <wells@example.com>
	[extensions]
	mq =
	strip =
	EOF

	GIT_AUTHOR_DATE="2007-01-01 00:00:00 +0230" &&
	GIT_COMMITTER_DATE="$GIT_AUTHOR_DATE" &&
	export GIT_COMMITTER_DATE GIT_AUTHOR_DATE
}

setup

setup_repos () {
	(
	hg init hgrepo &&
	cd hgrepo &&
	echo zero > content &&
	hg add content &&
	hg commit -m zero
	) &&

	git clone hg::hgrepo gitrepo
}

test_expect_success 'subcommand help' '
	test_when_finished "rm -rf gitrepo* hgrepo*" &&

	setup_repos &&

	(
	cd gitrepo &&
	test_expect_code 2 git-hg-helper help 2> ../help
	)
	# remotes should be in help output
	grep origin help
'

test_expect_success 'subcommand repo - no local proxy' '
	test_when_finished "rm -rf gitrepo* hgrepo*" &&

	setup_repos &&

	(
	cd hgrepo &&
	pwd >../expected
	) &&

	(
	cd gitrepo &&
	git-hg-helper repo origin > ../actual
	) &&

	test_cmp expected actual
'

GIT_REMOTE_HG_TEST_REMOTE=1 &&
export GIT_REMOTE_HG_TEST_REMOTE

test_expect_success 'subcommand repo - with local proxy' '
	test_when_finished "rm -rf gitrepo* hgrepo*" &&

	setup_repos &&

	(
	cd gitrepo &&
	export gitdir=`git rev-parse --git-dir`
	# trick to normalize path
	( cd $gitdir/hg/origin/clone && pwd ) >../expected &&
	( cd `git-hg-helper repo origin` && pwd ) > ../actual
	) &&

	test_cmp expected actual
'

test_expect_success 'subcommands hg-rev and git-rev' '
	test_when_finished "rm -rf gitrepo* hgrepo*" &&

	setup_repos &&

	(
	cd gitrepo &&
	git rev-parse HEAD > rev-HEAD &&
	test -s rev-HEAD &&
	git-hg-helper hg-rev `cat rev-HEAD` > hg-HEAD &&
	git-hg-helper git-rev `cat hg-HEAD` > git-HEAD &&
	test_cmp rev-HEAD git-HEAD
	)
'

test_expect_success 'subcommand mark' '
	test_when_finished "rm -rf gitrepo* hgrepo*" &&

	(
	hg init hgrepo &&
	cd hgrepo &&
	echo zero > content &&
	hg add content &&
	hg commit -m zero
	echo one > content &&
	hg commit -m one &&
	echo two > content &&
	hg commit -m two &&
	echo three > content &&
	hg commit -m three &&
	hg identify -r 0 --id >../root
	) &&

	hgroot=`cat root` &&

	git clone hg::hgrepo gitrepo &&

	(
	cd hgrepo &&
	hg strip -r 1
	) &&

	(
	cd gitrepo &&
	git-hg-helper marks origin --keep $hgroot  > output &&
	cat output &&
	grep "hg marks" output &&
	grep "git marks" output &&
	grep "Updated" output | grep $hgroot
	)
'

test_expect_success 'subcommand [some-repo]' '
	test_when_finished "rm -rf gitrepo* hgrepo*" &&

	setup_repos &&

	(
	cd hgrepo &&
	echo one > content &&
	hg commit -m one
	) &&

	(
	cd gitrepo &&
	git fetch origin
	) &&

	hg log -R hgrepo > expected &&
	# not inside gitrepo; test shared path handling
	GIT_DIR=gitrepo/.git git-hg-helper origin log > actual

	test_cmp expected actual
'

test_done