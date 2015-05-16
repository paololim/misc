. ~/.bashrc

##
# Your previous /Users/mbryzek/.bash_profile file was backed up as /Users/mbryzek/.bash_profile.macports-saved_2014-06-17_at_22:44:14
##

# MacPorts Installer addition on 2014-06-17_at_22:44:14: adding an appropriate PATH variable for use with MacPorts.
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.


# Setting PATH for Python 3.4
# The orginal version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.4/bin:${PATH}"
export PATH

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
source ~/.rvm/scripts/rvm

export NVM_DIR="/Users/mbryzek/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
