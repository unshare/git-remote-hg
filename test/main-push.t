CAPABILITY_PUSH=t

test -n "$TEST_DIRECTORY" || TEST_DIRECTORY=$(dirname $0)/
. "$TEST_DIRECTORY"/main.t


# .. and some push mode only specific tests

test_expect_success 'remote delete bookmark' '
	test_when_finished "rm -rf hgrepo* gitrepo*" &&

	(
	hg init hgrepo &&
	cd hgrepo &&
	echo zero > content &&
	hg add content &&
	hg commit -m zero
	hg bookmark feature-a
	) &&

	git clone "hg::hgrepo" gitrepo &&
	check_bookmark hgrepo feature-a zero &&

	(
	cd gitrepo &&
	git push --quiet origin :feature-a
	) &&

	check_bookmark hgrepo feature-a ''
'

test_expect_success 'source:dest bookmark' '
	test_when_finished "rm -rf hgrepo gitrepo" &&

	(
	hg init hgrepo &&
	cd hgrepo &&
	echo zero > content &&
	hg add content &&
	hg commit -m zero
	) &&

	git clone "hg::hgrepo" gitrepo &&

	(
	cd gitrepo &&
	echo one > content &&
	git commit -a -m one &&
	git push --quiet origin master:feature-b &&
	git push --quiet origin master^:refs/heads/feature-a
	) &&

	check_bookmark hgrepo feature-a zero &&
	check_bookmark hgrepo feature-b one &&

	(
	cd gitrepo &&
	git push --quiet origin master:feature-a
	) &&

	check_bookmark hgrepo feature-a one
'

setup_check_hg_commits_repo () {
        (
	rm -rf hgrepo* &&
	hg init hgrepo &&
	cd hgrepo &&
	echo zero > content &&
	hg add content &&
	hg commit -m zero
	) &&

	git clone "hg::hgrepo" gitrepo &&
	hg clone hgrepo hgrepo.second &&

	(
	cd gitrepo &&
	git remote add second hg::../hgrepo.second &&
	git fetch second
	) &&

	(
	cd hgrepo &&
	echo one > content &&
	hg commit -m one &&
	echo two > content &&
	hg commit -m two &&
	echo three > content &&
	hg commit -m three &&
	hg move content content-move &&
	hg commit -m moved &&
	hg move content-move content &&
	hg commit -m restored
        )
}

git config --global remote-hg.check-hg-commits fail
test_expect_success 'check-hg-commits with fail mode' '
	test_when_finished "rm -rf gitrepo* hgrepo*" &&

	setup_check_hg_commits_repo &&

	(
	cd gitrepo &&
	git fetch origin &&
	git reset --hard origin/master &&
	! git push second master 2>../error
	)

	cat error &&
	grep rejected error | grep hg
'

git config --global remote-hg.check-hg-commits push
# codepath for push is slightly different depending on shared proxy involved
# so tweak to test both
check_hg_commits_push () {
	test_when_finished "rm -rf gitrepo* hgrepo*" &&

	setup_check_hg_commits_repo &&

	(
	cd gitrepo &&
	git fetch origin &&
	git reset --hard origin/master &&
	git push second master 2> ../error
	) &&

	cat error &&
	grep "hg changeset" error &&

	hg log -R hgrepo > expected &&
	hg log -R hgrepo.second | grep -v bookmark > actual &&
	test_cmp expected actual
}

unset GIT_REMOTE_HG_TEST_REMOTE
test_expect_success 'check-hg-commits with push mode - no local proxy' '
	check_hg_commits_push
'

GIT_REMOTE_HG_TEST_REMOTE=1 &&
export GIT_REMOTE_HG_TEST_REMOTE
test_expect_success 'check-hg-commits with push mode - with local proxy' '
	check_hg_commits_push
'

test_done
