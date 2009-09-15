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
alias xorp xorpsh
alias include grep
alias reload 'system reboot'
alias halt 'system halt'
alias reboot 'system reboot'
alias vim 'vim -i /tmp/viminfo'
alias wr 'config save'

#Load command complete file
source ~/.complete

#Don't generate core file
limit coredumpsize 0

