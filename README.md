[![Build Status](https://travis-ci.org/crimaniak/ifupdated.svg)](https://travis-ci.org/crimaniak/ifupdated)
[![license](https://img.shields.io/github/license/crimaniak/ifupdated.svg)](https://github.com/crimaniak/ifupdated/blob/master/LICENSE)

# ifupdated

IfUpdated - UNIX-only utility to run command only when source files was changed from last run

## How it works

When the command is started, the utility collects information about all the files used and divides them into two categories - source code and results, depending on the opening parameters. This data is saved in a separate file for each combination of the running command and its parameters, and the next time it is used to determine if the source files have changed since the last time it was run. In the event that the files have not changed, the command is canceled. This utility implements some of the functionality of the utility 'make', and in combination with shell files can replace it in simple cases.

To collect information, the [strace](https://strace.io/) utility is used, so it must be installed for the correct operation of the program.

## Restrictions

* The presence of a change is determined by the time (Last Modified), not by content.
* To reliably detect changes, the running command must use all the files on which the result depends. Therefore, the utility will work badly if the list of source files is not fixed and depends on their presence on the disk.