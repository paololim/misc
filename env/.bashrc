umask 0002

export PATH="$HOME/bin:$PATH:/web/apidoc-cli/bin:/Applications/Postgres.app/Contents/Versions/9.4/bin:/usr/local/share/scala-2.11.6/bin"

. ~/.alias

RED="\[\033[0;31m\]"
YELLOW="\[\033[33m"
GREEN="\[\033]0;\w\007\033[32m\]"
WHITE="\e[0;37m"
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SEPERATEOUTPUT=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWSTASHSTATE=1
export GIT_PS1_SHOWUPSTREAM="auto"
source /web/misc/env/git-completion.bash-10b2a48
source ~/.alias
export PS1="$GREEN\u@\h $YELLOW\w$RED\$(__git_ps1 \" (%s)\") $WHITE\t \n$ "

export GOPATH=~/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

eval "$(hub alias -s)"
