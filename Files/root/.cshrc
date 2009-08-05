# $FreeBSD: src/etc/root/dot.cshrc,v 1.30 2007/05/29 06:37:58 dougb Exp $
#
# .cshrc - csh resource script, read at beginning of execution by each shell
#
# see also csh(1), environ(7).
#

alias h         history 25
alias j         jobs -l
alias la        ls -a
alias lf        ls -FA
alias ll        ls -lA

# A righteous umask
umask 22

set path = (/sbin /bin /usr/sbin /usr/bin /usr/games /usr/local/sbin /usr/local/bin $HOME/bin)

setenv  EDITOR  vim
setenv  PAGER   more
setenv  BLOCKSIZE       K

if ($?prompt) then
        # An interactive shell -- set some stuff up
        set prompt = "`/bin/hostname -s`# "
        set filec
        set history = 100
        set savehist = 100
        set mail = (/var/mail/$USER)
        if ( $?tcsh ) then
                bindkey "^W" backward-delete-word
                bindkey -k up history-search-backward
                bindkey -k down history-search-forward
        endif
endif

# BSDRP cool shell... Do not need to install bash :-)
set prompt='%B[%n@%m%b]%B%~%b%#'
set filec
set history = 100
set savehist = 100
set autolist
set nobeep
set color
set colorcat
alias ls ls -G
alias ll ls -hl
# Some BSDRP aliases:
alias cli vtysh
alias include grep
alias reload reboot
# Some BSDRP command complete
complete config  'p/1/(save diff apply rollback put get reset password help )/'
complete show  'p/1/(route process version license authors help )/'
complete route 'p/1/(add flush del change get monitor )/'
set iflist=`ifconfig -l`
complete ifconfig 'p/1/$iflist/'

# Others Command complete
# Lot's of these command complete were found here:
# http://hea-www.harvard.edu/~fine/Tech/tcsh.html

# directories
complete cd 'C/*/d/'
complete rmdir 'C/*/d/'
complete lsd 'C/*/d/'

# signal names
# also note that the initial - can be created with the first completion
# but without appending a space (note the extra slash with no
# append character specified)
complete kill 'c/-/S/' 'p/1/(-)//'

# use available commands as arguments for which, where, and man
complete which 'p/1/c/'
complete where 'p/1/c/'
complete man 'p/1/c/'

# aliases
complete alias 'p/1/a/'
complete unalias 'p/1/a/'

# variables
complete unset 'p/1/s/'
complete set 'p/1/s/'

# environment variables
complete unsetenv 'p/1/e/'
complete setenv 'p/1/e/'
#(kinda cool: complete first arg with an env variable, and add an =,
# continue completion of first arg with a filename.  complete 2nd arg
# with a command)
complete env 'c/*=/f/' 'p/1/e/=/' 'p/2/c/'

# limits
complete limit 'p/1/l/'

# key bindings
complete bindkey 'C/*/b/'

# groups
complete chgrp 'p/1/g/'

# users
complete chown 'p/1/u/'
complete passwd 'p/1/u/'
