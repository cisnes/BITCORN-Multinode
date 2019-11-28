# Useful variables
declare -r CRYPTOS=`ls -l config/ | egrep '^d' | awk '{print $9}' | xargs echo -n; echo`
declare -r DATE_STAMP="$(date +%y-%m-%d-%s)"
declare -r SCRIPTPATH="$(cd $(dirname ${BASH_SOURCE[0]}) > /dev/null; pwd -P)"
declare -r MASTERPATH="$(dirname "${SCRIPTPATH}")"
declare -r SCRIPT_VERSION="v3.0.0"
declare -r SCRIPT_LOGFILE="/tmp/nodemaster_${DATE_STAMP}_out.log"
declare -r IPV4_DOC_LINK="https://www.vultr.com/docs/add-secondary-ipv4-address"
declare -r DO_NET_CONF="/etc/network/interfaces.d/50-cloud-init.cfg"
declare -r NETWORK_BASE_TAG="$(dd if=/dev/urandom bs=2 count=1 2>/dev/null | od -x -A n | sed -e 's/^[[:space:]]*//g')"
COIN_SNAPSHOT='http://45.32.176.160/snapshot.zip'

function showbanner() {

    echo $(tput bold)$(tput setaf 3)
   cat << "EOF"
██████╗ ██╗████████╗ ██████╗ ██████╗ ██████╗ ███╗   ██╗
██╔══██╗██║╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗  ██║
██████╔╝██║   ██║   ██║     ██║   ██║██████╔╝██╔██╗ ██║
██╔══██╗██║   ██║   ██║     ██║   ██║██╔══██╗██║╚██╗██║
██████╔╝██║   ██║   ╚██████╗╚██████╔╝██║  ██║██║ ╚████║
╚═════╝ ╚═╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
                      ╚╗     THE BITCORN PROJECT     ╔╝
                       ╚╗ May the force be with you ╔╝      

                             ,:::::::::::.   
                       .::,:::::::::::::::  
                      .:::::::::::::::::::  
                  ,::::::::::::::::::::::::`
               `..::::,::::::::::::::::::,:.
  .;:.       .:::::::::::::::::::::::,::::: 
  ,;;;;;`    :::::::::::::::::::::::::::,:: 
    `;;;;;:::::::::::::::,::::::::::::,:::` 
     ;;;;;;::::::::::::::::,::::,:::::::`   
     ;;;;;;::::::::::::::::::::::::::,::`   
    `;;;;;;;::::::::::::::::::::::,::::`    
    .;;;;;;;::::::,::::::::::::::::::       
    ,;;;;;;;::::::::::::::::::,::,:::.      
    ;;;;;;;;:::::::::::::::::::,:::,        
   ,;;;;;;;:,:::::::::::::::::::::,         
  `;;;;;;;':::,,,,,,,,,,,,,,,,,,,,`         
  :;;;':,,,,,,,,,,,,::;;;;;;;;;;;;;;;.      
  ;;',,,,,,,,,:;';;;;;;;;;;;;;;;;;;;;;:     
 `;;,,,,,,:;;;;;;;;;;;;;;;;;:`     .;;;`    
 `;,,,,,;;;;;;;;;;;;;;;;;;.           .     
  ,,,,';;;;;;;;;;;;;;;;;.                   
 `:,;;;;;;;;;;;;;;;;;;:                     
.;;:;;;;;;;;;;;;;;;;:                       
 :;;;;;;;;;;;;;;;;`                         
   ;;: `.,:;;:.                                                   

EOF
}


# /*
# confirmation message as optional parameter, asks for confirmation
# get_confirmation && COMMAND_TO_RUN or prepend a message
# */
function get_confirmation() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            exit 1
            ;;
    esac
}

#
# /* no parameters, checks if we are running on a supported Ubuntu release */
#
function check_distro() {
    # currently only for Ubuntu 16.04 & 18.04
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        if [[ "${VERSION_ID}" != "16.04" ]] && [[ "${VERSION_ID}" != "18.04" ]] ; then
            echo "This script only supports Ubuntu 16.04 & 18.04 LTS, exiting."
            exit 1
        fi
    else
        echo "This script only supports Ubuntu 16.04 & 18.04 LTS, exiting."
        exit 1
    fi
}

#
# /* no parameters, installs the base set of packages that are required for all projects */
#
function install_packages() {
    # development and build packages
    # these are common on all cryptos
    echo "Repository installation"
    if [ ! -f ${MNODE_CONF_BASE}/${CODENAME}_n1.conf ]; then
        add-apt-repository -yu ppa:bitcorn/bitcorn  &>> ${SCRIPT_LOGFILE}
        apt-get update -yu &>> ${SCRIPT_LOGFILE}
        apt-get install -yu unzip &>> ${SCRIPT_LOGFILE}
    else
        echo "Repositories already installed"
    fi
}

function get_snapshot() {
    # individual data dirs for now to avoid problems
    echo ""
    echo ""
    echo "Initialising snapshots."
    cd ${MNODE_DATA_BASE}/
    pwd
    wget $COIN_SNAPSHOT 
    echo "Snapshot downloaded. Extracting to nodes"
            
    for (( c=${STARTNUM}; c<=$count; c++ )); do
        echo "**NODE${c}**"
        cd ${MNODE_DATA_BASE}/${CODENAME}${c}/
        pwd
        rm -rf blocks/ sporks/ zerocoin/ chainstate/
        cp ${MNODE_DATA_BASE}/snapshot.zip .
        echo "Unzipping snapshot"
        unzip snapshot.zip &>> ${SCRIPT_LOGFILE}
        echo "Cleaning up"
        rm snapshot.zip
    done

    cd ${MNODE_DATA_BASE}/
    rm snapshot.zip
    echo "Snapshot installation complete."
    echo ""
    echo ""
}

function create_key() {
  ${MNODE_DAEMON} -daemon -pid=${MNODE_DATA_BASE}/${CODENAME}${NUM}/${CODENAME}.pid -conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf -datadir=${MNODE_DATA_BASE}/${CODENAME}${NUM}
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $MNODE_DAEMON)" ]; then
   echo -e "${RED}$COINNAME server couldn't not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  priv_key=$($CODENAME-cli -conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf createmasternodekey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the GEN Key${NC}"
    sleep 30
    priv_key=$($CODENAME-cli -conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf createmasternodekey)
  fi
  $CODENAME-cli -conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf stop
  sleep 10
  echo "Waiting for node to shut down"
}
#
# /* no parameters, creates and activates a swapfile since VPS servers often do not have enough RAM for compilation */
#
function swaphack() {
#check if swap is available
if [ $(free | awk '/^Swap:/ {exit !$2}') ] || [ ! -f "/var/mnode_swap.img" ];then
    echo "No swap on drive. Creating."
    # needed because ant servers are ants
    rm -f /var/mnode_swap.img
    dd if=/dev/zero of=/var/mnode_swap.img bs=1024k count=${MNODE_SWAPSIZE} &>> ${SCRIPT_LOGFILE}
    chmod 0600 /var/mnode_swap.img
    mkswap /var/mnode_swap.img &>> ${SCRIPT_LOGFILE}
    swapon /var/mnode_swap.img &>> ${SCRIPT_LOGFILE}
    echo '/var/mnode_swap.img none swap sw 0 0' | tee -a /etc/fstab &>> ${SCRIPT_LOGFILE}
    echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf               &>> ${SCRIPT_LOGFILE}
    echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf		&>> ${SCRIPT_LOGFILE}
else
    echo "Swap already made."
fi
}

#
# /* no parameters, creates and activates a dedicated masternode user */
#
function create_mn_user() {

    # our new mnode unpriv user acc is added
    if id "${MNODE_USER}" >/dev/null 2>&1; then
        echo "user exists already, do nothing" &>> ${SCRIPT_LOGFILE}
    else
        echo "Adding new system user ${MNODE_USER}"
        adduser --disabled-password --gecos "" ${MNODE_USER} &>> ${SCRIPT_LOGFILE}
    fi

}

#
# /* no parameters, creates a masternode data directory (one per masternode)  */
#
function create_mn_dirs() {

    # individual data dirs for now to avoid problems
    echo "Creating masternode directories"
    mkdir -p ${MNODE_CONF_BASE}
    for NUM in $(seq 1 ${count}); do
        if [ ! -d "${MNODE_DATA_BASE}/${CODENAME}${NUM}" ]; then
             echo "creating data directory ${MNODE_DATA_BASE}/${CODENAME}${NUM}" &>> ${SCRIPT_LOGFILE}
             mkdir -p ${MNODE_DATA_BASE}/${CODENAME}${NUM} &>> ${SCRIPT_LOGFILE}
        fi
    done

}

#
# /* no parameters, creates a minimal set of firewall rules that allows INBOUND masternode p2p & SSH ports */
#
function configure_firewall() {

    echo "Configuring firewall rules"
    # disallow everything except ssh and masternode inbound ports
    ufw default deny                          &>> ${SCRIPT_LOGFILE}
    ufw logging on                            &>> ${SCRIPT_LOGFILE}
    ufw allow ${SSH_INBOUND_PORT}/tcp         &>> ${SCRIPT_LOGFILE}
    # KISS, its always the same port for all interfaces
    ufw allow ${MNODE_INBOUND_PORT}/tcp       &>> ${SCRIPT_LOGFILE}
    # This will only allow 6 connections every 30 seconds from the same IP address.
    ufw limit OpenSSH	                      &>> ${SCRIPT_LOGFILE}
    ufw --force enable                        &>> ${SCRIPT_LOGFILE}
    echo "Firewall ufw is active and enabled on system startup"

}

#
# /* no parameters, checks if the choice of networking matches w/ this VPS installation */
#
function validate_netchoice() {

    echo "Validating network rules"

    # break here of net isn't 4 or 6
    if [ ${net} -ne 4 ] && [ ${net} -ne 6 ]; then
        echo "invalid NETWORK setting, can only be 4 or 6!"
        exit 1;
    fi

    # generate the required ipv6 config
    if [ "${net}" -eq 4 ]; then
        echo "IPv4 address generation needs to be done manually atm!"  &>> ${SCRIPT_LOGFILE}
    fi	# end ifneteq4

}

#
# /* no parameters, generates one masternode configuration file per masternode in the default
#    directory (eg. /etc/masternodes/${CODENAME} and replaces the existing placeholders if possible */
#
function create_mn_configuration() {

        # always return to the script root
        cd ${SCRIPTPATH}

        # create one config file per masternode
        for NUM in $(seq 1 ${count}); do
        PASS=$(date | md5sum | cut -c1-24)

            # we dont want to overwrite an existing config file
            if [ ! -f ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf ]; then
                if [ -z "$STARTNUM" ]; then
                    STARTNUM=${NUM}
                fi

                echo "individual masternode config doesn't exist, generate it!"                  &>> ${SCRIPT_LOGFILE}

                # if a template exists, use this instead of the default
                if [ -e config/${CODENAME}/${CODENAME}.conf ]; then
                    echo "custom configuration template for ${CODENAME} found, use this instead"                      &>> ${SCRIPT_LOGFILE}
                    cp ${SCRIPTPATH}/config/${CODENAME}/${CODENAME}.conf ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf  &>> ${SCRIPT_LOGFILE}
                else
                    echo "No ${CODENAME} template found, using the default configuration template"			          &>> ${SCRIPT_LOGFILE}
                    cp ${SCRIPTPATH}/config/default.conf ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf                  &>> ${SCRIPT_LOGFILE}
                fi
                # replace placeholders

                # running sed fro IP and PORT
                NODEPORT=$(($baseport + $NUM - 1))
                echo "running sed on file ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf"                                &>> ${SCRIPT_LOGFILE}
                
                if [ "${manual}" -eq 1 ]; then
                    read -p "** IP for MN${NUM}: " manualip
                    echo ""
                    echo ""
                    sed -e "s/XXX_GIT_PROJECT_XXX/${CODENAME}/" -e "s/XXX_NUM_XXX/${NUM}/" -e "s/XXX_PASS_XXX/${PASS}/" -e "s/XXX_IPV4_XXX/${manualip}/" -e "s/XXX_MNODE_INBOUND_PORT_XXX/${NODEPORT}/" -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf &>> ${SCRIPT_LOGFILE}
                else
                    sed -e "s/XXX_GIT_PROJECT_XXX/${CODENAME}/" -e "s/XXX_NUM_XXX/${NUM}/" -e "s/XXX_PASS_XXX/${PASS}/" -e "s/XXX_IPV4_XXX/${IPV4}/" -e "s/XXX_MNODE_INBOUND_PORT_XXX/${NODEPORT}/" -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf &>> ${SCRIPT_LOGFILE}
                fi


                echo ""
                echo ""
                echo "*************************************************************************************"
                echo "****************************  INPUT MASTERNODE_${NUM} DATA *******************************"
                echo "*************************************************************************************"
                read -p "Genkey for MN${NUM} (ENTER to auto-generate): " priv_key                
                

                if [ -z "${priv_key}" ]; then
                    create_key
                    echo "Generated privkey is: ${priv_key}"
                fi
                echo ""
                echo "$(tput bold)$(tput setaf 3)Collateral required:"
                echo "$(tput bold)$(tput setaf 3)10 000 000 CORN"
                echo ""
                echo "By now you should have sent 10 000 000 (10 MILLION) corn to a unique address in your wallet. If not, see step X.X in the guide."
                echo "Please enter the wallet-address containing the 10mill for Masternode number ${NUM}"
                read -p "address: " address

                transaction=$(curl -s "45.32.176.160:42420/collateral?address=${address}")
                outputid=${transaction: -1}
                txhash=${transaction::-1}
                echo "Checking for collateral"
                
                if [ "$transaction" != "Not found" ]; then
                    echo "Collateral found. Proceeding"
                fi
                
                echo "${transaction}"
                if [ -z "${address}" ]; then
                    echo "No txhash supplied"
                fi


                

                

                sed -e "s/XXX_priv_XXX/${priv_key}/" -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf &>> ${SCRIPT_LOGFILE}
                if [ "$startnodes" -eq 1 ]; then
                    #uncomment masternode= and masternodeprivkey= so the node can autostart and sync
                    
                    sed 's/^#\(.*\)masternode\(.*\)/\1masternode\2/g' -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf
                fi
                echo ""
                echo ""
            fi
        done

}

#
# /* no parameters, generates a masternode configuration file per masternode in the default */
#
function create_control_configuration() {
    echo "*Creating control configuration"
    # delete any old stuff that's still around
    rm -f /tmp/${CODENAME}_masternode.conf &>> ${SCRIPT_LOGFILE}
    # create one line per masternode with the data we have
    for NUM in $(seq 1 ${count}); do
        tkey=$(sed -n 21p /etc/masternodes/bitcorn_n${NUM}.conf)
        key=${tkey#"masternodeprivkey="}
        
        tip=$(sed -n 11p /etc/masternodes/bitcorn_n${NUM}.conf)
        ip=${tip#"bind="}

		cat >> /tmp/${CODENAME}_masternode.conf <<-EOF
			MN${NUM} ${ip} ${key} TXHASH_MN${NUM} OUTPUTID_MN${NUM}
		EOF
    done

}

# priv_key

#
# /* no parameters, generates a a pre-populated masternode systemd config file */
#
function create_systemd_configuration() {

    echo "* (over)writing systemd config files for masternodes"
    # create one config file per masternode
    for NUM in $(seq 1 ${count}); do
    PASS=$(date | md5sum | cut -c1-24)
        echo "* (over)writing systemd config file ${SYSTEMD_CONF}/${CODENAME}_n${NUM}.service"  &>> ${SCRIPT_LOGFILE}
		cat > ${SYSTEMD_CONF}/${CODENAME}_n${NUM}.service <<-EOF
			[Unit]
			Description=${CODENAME} distributed currency daemon
			After=network.target

			[Service]
			User=${MNODE_USER}
			Group=${MNODE_USER}

			Type=forking
			PIDFile=${MNODE_DATA_BASE}/${CODENAME}${NUM}/${CODENAME}.pid
			ExecStart=${MNODE_DAEMON} -daemon -pid=${MNODE_DATA_BASE}/${CODENAME}${NUM}/${CODENAME}.pid -conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf -datadir=${MNODE_DATA_BASE}/${CODENAME}${NUM}

			Restart=always
			RestartSec=5
			PrivateTmp=true
			TimeoutStopSec=60s
			TimeoutStartSec=5s
			StartLimitInterval=120s
			StartLimitBurst=15

			[Install]
			WantedBy=multi-user.target
		EOF
    done

}

#
# /* set all permissions to the masternode user */
#
function set_permissions() {

	# maybe add a sudoers entry later
	mkdir -p /var/log/sentinel &>> ${SCRIPT_LOGFILE}
	chown -R ${MNODE_USER}:${MNODE_USER} ${MNODE_CONF_BASE} ${MNODE_DATA_BASE} /var/log/sentinel ${SENTINEL_BASE}/database &>> ${SCRIPT_LOGFILE}
    # make group permissions same as user, so vps-user can be added to masternode group
    chmod -R g=u ${MNODE_CONF_BASE} ${MNODE_DATA_BASE} /var/log/sentinel &>> ${SCRIPT_LOGFILE}

}

#
# /*
# remove packages and stuff we don't need anymore and set some recommended
# kernel parameters
# */
#
function cleanup_after() {

    #apt-get -qqy -o=Dpkg::Use-Pty=0 --force-yes autoremove
    apt-get -qqy -o=Dpkg::Use-Pty=0 --allow-downgrades --allow-change-held-packages autoclean

    echo "kernel.randomize_va_space=1" > /etc/sysctl.conf  &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.conf.all.rp_filter=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.icmp_echo_ignore_broadcasts=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.conf.all.log_martians=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.conf.default.log_martians=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv6.conf.all.accept_redirects=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.conf.all.send_redirects=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "kernel.sysrq=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.tcp_timestamps=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    echo "net.ipv4.icmp_ignore_bogus_error_responses=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
    sysctl -p

}

#
# /* project as parameter, sources the project specific parameters and runs the main logic */
#

function create_symlink () {
    cd /root/.bitcorn &>> ${SCRIPT_LOGFILE}
    for NUM in $(seq 1 ${count}); do
        if [ ! -z {NUM} ]; then
            ln -s /etc/masternodes/bitcorn_n${NUM}.conf /root/.bitcorn/${NUM} &>> ${SCRIPT_LOGFILE}
        fi
    done
}

#
# /* project as parameter, creates the mnode administration toolset */
#




#
# /* project as parameter, sources the project specific parameters and runs the main logic */
#

# source the default and desired crypto configuration files
function source_config() {

    SETUP_CONF_FILE="${SCRIPTPATH}/bitcorn.env"

    # first things first, to break early if things are missing or weird
    check_distro

    if [ -f ${SETUP_CONF_FILE} ]; then
        echo "$(tput setaf 7) Multinode ${SCRIPT_VERSION} for  BITCORN , running on Ubuntu ${VERSION_ID}"
        source "${SETUP_CONF_FILE}"

        # main block of function logic starts here
        
        echo "************************* Installation Plan *************************"
        NUMBERINSTALLED=0
        for number in $(seq 1 3); do
            if [ -f ${MNODE_CONF_BASE}/${CODENAME}_n${number}.conf ]; then
                    NUMBERINSTALLED=${number}
            fi
        done

        # exit if 3 nodes already installed
        if [ "${NUMBERINSTALLED}" -eq "3" ]; then
            echo ""
            echo ""
            echo "You are only allowed to install 3 nodes per server. Please create a new VPS."
            echo "This rule is set to force more decentralization of the network and mitigate for resource-related problems issues."
            echo ""
            echo ""
            exit 1
        fi

        echo ""
        echo "Number of Bitcorn nodes installed: ${NUMBERINSTALLED}"
        if [ ! "${NUMBERINSTALLED}" -eq 0 ]; then
            read -p "How many additional masternodes do you want to add?: " additional
            echo ""
            let "count = NUMBERINSTALLED + additional"
            
            if [ "$count" -gt "3" ]; then
                echo "You cannot install more than 3 nodes per server."
                exit 1
            fi

            echo "Valid number of nodes."
            echo "After installation, you will have a total of ${count} masternodes on this VPS."
            get_confirmation
        else
            read -p "** How many masternodes do you want want to install?: " count
        fi

        echo "Installing and configuring your server to a total of"
        echo "$(tput bold)$(tput setaf 2) => ${count} ${project} masternode(s) in version ${release} $(tput sgr0)"
        echo "for you now."
        # show a hint for MANUAL IPv4 configuration
        if [ "${manual}" -eq 1 ]; then
            
            echo "WARNING:"
            echo "You selected manual networking which leads to a manual workflow for this part."
            echo "You need to type in your IPs when asked. This feature is for people running custom servers"
        fi

        # start nodes after setup
        if [ "$startnodes" -eq 1 ]; then
            echo "Your nodes will start after the installation."
        fi
        echo ""
        echo "*************************************************************************************"
        sleep 5

        # main routine
        
        prepare_mn_interfaces
        swaphack
        
        install_packages
        build_mn_from_source
        
        create_mn_user
        create_mn_dirs
        configure_firewall
        create_mn_configuration
        create_control_configuration
        create_systemd_configuration
        get_snapshot
        create_symlink
        
        set_permissions
        cleanup_after
        final_call
    else
        echo "required file ${SETUP_CONF_FILE} does not exist, abort!"
        exit 1
    fi

}

#
# /* no parameters, builds the required masternode binary from sources. Exits if already exists and "update" not given  */
#
function build_mn_from_source() {
        # daemon not found compile it
        apt-get install -yu bitcornd &>> ${SCRIPT_LOGFILE}

        # if it's not available after compilation, theres something wrong
        if [ ! -f ${MNODE_DAEMON} ]; then
                echo "Daemon installation failed! Please notify Pineapple. Thank you!"
                exit 1
        fi
}

#
# /* no parameters, print some (hopefully) helpful advice  */
#

function final_call() {
    # note outstanding tasks that need manual work
    echo "************! ALMOST DONE !******************************"
    echo "There is still work to do locally on your computer."
    echo "You need to edit your masternodes.conf file and add the new entries"
    echo "Below is a list with the installed MNs:"
    cat /tmp/bitcorn_masternode.conf
    echo ""
    echo "=> $(tput bold)$(tput setaf 2) All configuration files are in: ${MNODE_CONF_BASE} $(tput sgr0)"
    echo "=> $(tput bold)$(tput setaf 2) All Data directories are in: ${MNODE_DATA_BASE} $(tput sgr0)"
    
    # place future helper script accordingly on fresh install
    cp ${SCRIPTPATH}/scripts/activate_masternodes.sh ${MNODE_HELPER}_${CODENAME}
    echo "">> ${MNODE_HELPER}_${CODENAME}

    for (( c=$STARTNUM; c<=$count; c++ )); do
        echo "systemctl daemon-reload" >> ${MNODE_HELPER}_${CODENAME}
        echo "systemctl enable ${CODENAME}_n${c}" >> ${MNODE_HELPER}_${CODENAME}
        echo "systemctl restart ${CODENAME}_n${c}" >> ${MNODE_HELPER}_${CODENAME}
    done
    chmod u+x ${MNODE_HELPER}_${CODENAME}
    

    if [ "$startnodes" -eq 1 ]; then
        echo ""
        echo "** Your nodes are starting up. Opening the wallet/loading blocks may take up to 20 minutes after starting."
        ${MNODE_HELPER}_${CODENAME}
    fi
    tput sgr0
}

#
# /* no parameters, create the required network configuration. IPv6 is auto.  */
#
function prepare_mn_interfaces() {

    # this allows for more flexibility since every provider uses another default interface
    # current default is:
    # * ens3 (vultr) w/ a fallback to "eth0" (Hetzner, DO & Linode w/ IPv4 only)
    #

    # check for the default interface status
    if [ ! -f /sys/class/net/${ETH_INTERFACE}/operstate ]; then
        echo "Default interface doesn't exist, switching to eth0"
        export ETH_INTERFACE="eth0"
    fi

    # check for the nuse case <3
    if [ -f /sys/class/net/ens160/operstate ]; then
        export ETH_INTERFACE="ens160"
    fi

    # get the current interface state
    ETH_STATUS=$(cat /sys/class/net/${ETH_INTERFACE}/operstate)

    # check interface status
    if [[ "${ETH_STATUS}" = "down" ]] || [[ "${ETH_STATUS}" = "" ]]; then
        echo "Default interface is down, fallback didn't work. Break here."
        exit 1
    fi

    # DO ipv6 fix, are we on DO?
    # check for DO network config file
    
    IPV4=$(ip addr | grep 'inet ' | grep -Ev 'inet 127|inet 192\.168|inet 10\.' | \
            sed "s/[[:space:]]*inet \([0-9.]*\)\/.*/\1/")

    validate_netchoice
}

##################------------Menu()---------#####################################

# Declare vars. Flags initalizing to 0.
wipe=0;
baseport=42420;
debug=0;
update=0;
sentinel=0;
startnodes=1;
advanced=0;
manual=0;
project="bitcorn"
net="4"

ARGS=$(getopt -o "hp:n:c:r:wmudx" -l "help,project:,net:,count:,release:,wipe,sentinel,update,debug,startnodes,manual" -n "install.sh" -- "$@");

#Bad arguments
if [ $? -ne 0 ];
then
    help;
fi

eval set -- "$ARGS";

while true; do
    case "$1" in
        -m|--manual)
            shift;
                    manual="1";
            ;;
        --)
            shift;
            break;
            ;;
    esac
done

# Check required arguments
if [ -z "$project" ]
then
    show_help;
fi

#################################################
# source default config before everything else
source ${SCRIPTPATH}/config/default.env
#################################################

main() {

    echo "starting" &> ${SCRIPT_LOGFILE}
    showbanner

    # debug
    if [ "$debug" -eq 1 ]; then
        echo "********************** VALUES AFTER CONFIG SOURCING: ************************"
        echo "START DEFAULTS => "
        echo "SCRIPT_VERSION:       $SCRIPT_VERSION"
        echo "SSH_INBOUND_PORT:     ${SSH_INBOUND_PORT}"
        echo "SYSTEMD_CONF:         ${SYSTEMD_CONF}"
        echo "NETWORK_CONFIG:       ${NETWORK_CONFIG}"
        echo "NETWORK_TYPE:         ${NETWORK_TYPE}"
        echo "ETH_INTERFACE:        ${ETH_INTERFACE}"
        echo "MNODE_CONF_BASE:      ${MNODE_CONF_BASE}"
        echo "MNODE_DATA_BASE:      ${MNODE_DATA_BASE}"
        echo "MNODE_USER:           ${MNODE_USER}"
        echo "MNODE_HELPER:         ${MNODE_HELPER}"
        echo "MNODE_SWAPSIZE:       ${MNODE_SWAPSIZE}"
        echo "NETWORK_BASE_TAG:     ${NETWORK_BASE_TAG}"        
        echo "CODE_DIR:             ${CODE_DIR}"
        echo "SCVERSION:            ${SCVERSION}"
        echo "RELEASE:              ${release}"
        echo "SETUP_MNODES_COUNT:   ${SETUP_MNODES_COUNT}"
        echo "END DEFAULTS => "
    fi

    # source project configuration
    source_config ${project}

    # debug
    if [ "$debug" -eq 1 ]; then
        echo "START PROJECT => "
        echo "CODENAME:             $CODENAME"
        echo "SETUP_MNODES_COUNT:   ${SETUP_MNODES_COUNT}"
        echo "MNODE_DAEMON:         ${MNODE_DAEMON}"
        echo "MNODE_INBOUND_PORT:   ${MNODE_INBOUND_PORT}"
        echo "GIT_URL:              ${GIT_URL}"
        echo "SCVERSION:            ${SCVERSION}"
        echo "RELEASE:              ${release}"
        echo "NETWORK_BASE_TAG:     ${NETWORK_BASE_TAG}"
        echo "END PROJECT => "

        echo "START OPTIONS => "
        echo "RELEASE: ${release}"
        echo "PROJECT: ${project}"
        echo "SETUP_MNODES_COUNT: ${count}"
        echo "NETWORK_TYPE: ${NETWORK_TYPE}"
        echo "NETWORK_TYPE: ${net}"

        echo "END OPTIONS => "
        echo "********************** VALUES AFTER CONFIG SOURCING: ************************"
    fi
}

main "$@"