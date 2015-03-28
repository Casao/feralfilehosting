#!/bin/bash
# Install Syncthing
scriptversion="1.0.5"
scriptname="install.syncthing"
syncthingversion="0.10.29"
# randomessence
#
# wget -qO ~/install.syncthing http://git.io/-MNlxQ && bash ~/install.syncthing
#
############################
#### Script Notes Start ####
############################
#
# https://github.com/syncthing/syncthing/releases/latest
#
############################
##### Script Notes End #####
############################
#
############################
## Version History Starts ##
############################
#
############################
### Version History Ends ###
############################
#
############################
###### Variable Start ######
############################
#
scripturl="https://raw.githubusercontent.com/feralhosting/feralfilehosting/master/Feral%20Wiki/Software/Syncthing%20-%20Basic%20Setup/scripts/install.syncthing.sh"
#
############################
####### Variable End #######
############################
#
# Disables the built in script updater permanently.
updaterenabled="1"
#
guiport=$(shuf -i 10001-49999 -n 1)
syncport=$(expr 1 + $guiport)
#
apacheconf="http://git.io/WqUqBQ"
nginxconf="http://git.io/TnhqpA"
#
############################
#### Self Updater Start ####
############################
#
if [[ ! -z $1 && $1 == 'qr' ]] || [[ ! -z $2 && $2 == 'qr' ]];then echo -n '' > ~/.quickrun; fi
#
if [[ ! -z $1 && $1 == 'nu' ]] || [[ ! -z $2 && $2 == 'nu' ]]
then
    echo
    echo "The Updater has been temporarily disabled"
    echo
    scriptversion=""$scriptversion"-nu"
else
    if [[ "$updaterenabled" -eq 1 ]]
    then
        [[ ! -d ~/bin ]] && mkdir -p ~/bin
        [[ ! -f ~/bin/"$scriptname" ]] && wget -qO ~/bin/"$scriptname" "$scripturl"
        #
        wget -qO ~/.000"$scriptname" "$scripturl"
        #
        if [[ $(sha256sum ~/.000"$scriptname" | awk '{print $1}') != $(sha256sum ~/bin/"$scriptname" | awk '{print $1}') ]]
        then
            echo -e "#!/bin/bash\nwget -qO ~/bin/$scriptname $scripturl\ncd && rm -f $scriptname{.sh,}\nbash ~/bin/$scriptname\nexit" > ~/.111"$scriptname"
            bash ~/.111"$scriptname"
            exit
        else
            if [[ -z $(ps x | fgrep "bash $HOME/bin/$scriptname" | grep -v grep | head -n 1 | awk '{print $1}') && $(ps x | fgrep "bash $HOME/bin/$scriptname" | grep -v grep | head -n 1 | awk '{print $1}') -ne "$$" ]]
            then
                echo -e "#!/bin/bash\ncd && rm -f $scriptname{.sh,}\nbash ~/bin/$scriptname\nexit" > ~/.222"$scriptname"
                bash ~/.222"$scriptname"
                exit
            fi
        fi
        cd && rm -f .{000,111,222}"$scriptname"
        chmod -f 700 ~/bin/"$scriptname"
        echo
    else
        echo
        echo "The Updater has been disabled"
        echo
        scriptversion=""$scriptversion"-DEV"
    fi
fi
#
if [[ -f ~/.quickrun ]];then updatestatus="y"; rm -f ~/.quickrun; fi
#
############################
##### Self Updater End #####
############################
#
############################
#### Core Script Starts ####
############################
#
if [[ "$updatestatus" == "y" ]]
then
    :
else
    echo -e "Hello $(whoami), you have the latest version of the" "\033[36m""$scriptname""\e[0m" "script. This script version is:" "\033[31m""$scriptversion""\e[0m"
    echo
    echo -e "The version of the" "\033[33m""Syncthing""\e[0m" "being used in this script is:" "\033[31m""$syncthingversion""\e[0m"
    echo
    read -ep "The script has been updated, enter [y] to continue or [q] to exit: " -i "y" updatestatus
    echo
fi
#
if [[ "$updatestatus" =~ ^[Yy]$ ]]
then
#
############################
#### User Script Starts ####
############################
#
    echo "https://github.com/syncthing/syncthing/releases/latest"
    echo
    read -ep "What is the version of syncthing you want to install? (change version here if needed then press enter): " -i "$syncthingversion" mainversion
    echo
	wget -qO ~/syncthing.tar.gz "https://github.com/syncthing/syncthing/releases/download/v$mainversion/syncthing-linux-amd64-v$mainversion.tar.gz"
    tar xf ~/syncthing.tar.gz
    mv ~/syncthing-linux-amd64-v"$syncthingversion"/syncthing ~/bin/
    cd && rm -rf syncthing{-linux-amd64-v"$syncthingversion",.tar.gz}
    #
    ~/bin/syncthing -generate="~/.config/syncthing"
    sed -i -r 's#<address>127.0.0.1:(.*)</address>#<address>10.0.0.1:'"$guiport"'</address>#g' ~/.config/syncthing/config.xml
    sed -i 's#<listenAddress>0.0.0.0:22000</listenAddress>#<listenAddress>0.0.0.0:'"$syncport"'</listenAddress>#g' ~/.config/syncthing/config.xml
    # Apache proxypass
    if [[ ! -f ~/.apache2/conf.d/syncthing.conf ]]
    then
        wget -qO ~/.apache2/conf.d/syncthing.conf "$apacheconf"
        sed -i -r 's#PORT#'"$guiport"'#g' ~/.apache2/conf.d/syncthing.conf
        /usr/sbin/apache2ctl -k graceful > /dev/null 2>&1
    else
        configport=$(sed -nr 's#\s*<address>10.0.0.1:(.*)</address>#\1#p' ~/.config/syncthing/config.xml)
        wget -qO ~/.apache2/conf.d/syncthing.conf "$apacheconf"
        sed -i -r 's#PORT#'"$configport"'#g' ~/.apache2/conf.d/syncthing.conf
        /usr/sbin/apache2ctl -k graceful > /dev/null 2>&1
    fi
    # nginx proxypass
    if [[ -d ~/.nginx ]]
    then
        if [[ ! -f ~/.nginx/conf.d/000-default-server.d/syncthing.conf ]]
        then
            wget -qO ~/.nginx/conf.d/000-default-server.d/syncthing.conf "$nginxconf"
            sed -i -r 's#USERNAME#'"$(whoami)"'#g' ~/.nginx/conf.d/000-default-server.d/syncthing.conf
            sed -i -r 's#PORT#'"$guiport"'#g' ~/.nginx/conf.d/000-default-server.d/syncthing.conf
            /usr/sbin/nginx -s reload -c ~/.nginx/nginx.conf > /dev/null 2>&1
        else
            configport=$(sed -nr 's#\s*<address>10.0.0.1:(.*)</address>#\1#p' ~/.config/syncthing/config.xml)
            wget -qO ~/.nginx/conf.d/000-default-server.d/syncthing.conf "$nginxconf"
            sed -i -r 's#USERNAME#'"$(whoami)"'#g' ~/.nginx/conf.d/000-default-server.d/syncthing.conf
            sed -i -r 's#PORT#'"$configport"'#g' ~/.nginx/conf.d/000-default-server.d/syncthing.conf
            /usr/sbin/nginx -s reload -c ~/.nginx/nginx.conf > /dev/null 2>&1
        fi
    fi
    screen -dmS syncthing ~/bin/syncthing
    echo
    echo "https://$(hostname -f)/$(whoami)/syncthing/"
    echo
#
############################
##### User Script End  #####
############################
#
else
    echo -e "You chose to exit after updating the scripts."
    echo
    cd && bash
    exit 1
fi
#
############################
##### Core Script Ends #####
############################
#