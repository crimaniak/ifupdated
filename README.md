[![Build Status](https://travis-ci.org/crimaniak/ifupdated.svg)](https://travis-ci.org/crimaniak/ifupdated)
[![license](https://img.shields.io/github/license/crimaniak/ifupdated.svg)](https://github.com/crimaniak/ifupdated/blob/master/LICENSE)

# ifupdated

IfUpdated - UNIX-only utility to run command only when source files were changed after the last run

## How it works

When the command is started, the utility collects information about all the files used and divides them into two categories - source code and results, depending on the opening parameters. This data is saved in a separate file for each combination of the running command and its parameters. When it is run for the next time, this data is used to determine if the source files have changed since the last time it was run. In the case that the files have not changed, the command is cancelled. This utility implements some of the functionality of the utility 'make', and in the combination with shell files it can replace 'make' in simple cases.

To collect information, the [strace](https://strace.io/) utility is used, so it must be installed for the correct operation of the program.

## Restrictions

* The presence of a change is determined by the time (Last Modified), not by content.
* To detect changes reliably, the running command must use all the files the result depends on. The utility will work unreliable if the list of dependencies is not determined by the source files content only. 