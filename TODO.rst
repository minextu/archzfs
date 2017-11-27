============
Things To Do
============

* Fri Jul 28 12:20 2017: packer qemu provision should run in stdout

  No gui with all output going to stdout would be helpful for copying errors.

  https://stackoverflow.com/questions/19565116/redirect-qemu-window-output-to-terminal-running-qemu

* Mon Jul 17 00:30 2017: Finish documenting how to run tests in testing/README.rst

* Sat Sep 17 01:16 2016: ADD TESTS for run_hook

  Test the args! Make sure ash can parse them.

  These tests will close #76 and #77

* Wed Jul 26 20:25 2017: add run in qemu command for test.sh

  Runs the image built by packer in qemu

* Sun Feb 12 15:57 2017: more scraper stuff

  verify aur packages not flagged out of date

  verify should check kernel pkgrel versions

* Thu Sep 15 09:04 2016: test.sh mirrorlist should be regenerated after 24 hours

* Sun May 29 09:37 2016: auto increment numbers when building test packages

  New version for kernel change

  Pkgrel increase in case of build by user

* Sun May 29 03:32 2016: Add flag to disable signing in build.sh for testing purposes

  Signing should be done in repo.sh when adding the packages to the archzfs repo

- Mon Sep 12 22:32 2016: git_calc_check should not be used in repo.sh

  If commits are pushed after the git packages have been built, the version used in repo.sh will not be correct.

- Sun Apr 19 19:45 2015: Found more tests at https://github.com/behlendorf/xfstests

  Requires additional pools

- Sun Apr 19 19:51 2015: ztest slides http://blog.delphix.com/csiden/files/2012/01/ZFS_Backward_Compatability_Testing.pdf

- Sun Apr 19 20:05 2015: What I am trying to do is described here: https://github.com/zfsonlinux/zfs/issues/1534

- Mon Sep 12 22:27 2016: add a test for zfs-archiso-linux packages to install in current archiso

- Sat Sep 17 00:41 2016: Document ghetto linting the ash initcpio.hook file

  pacman -S dash
  dash
  . src/zfs-utils/zfs-utils.initcpio.hook
  run_hook

