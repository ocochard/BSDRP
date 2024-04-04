#
HOME=/root
export HOME
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:~/bin
export PATH
TERM=${TERM:-xterm}
export TERM
PAGER=less
export PAGER

# set ENV to a file invoked each time sh is started for interactive use.
ENV=$HOME/.shrc; export ENV

CLICOLOR=1; export CLICOLOR
XZ_DEFAULTS='--threads=0'; export XZ_DEFAULTS

# Query terminal size; useful for serial lines.
if [ -x /usr/bin/resizewin ] ; then /usr/bin/resizewin -z ; fi
