# Useful variables
declare -r CRYPTOS=`ls -l config/ | egrep '^d' | awk '{print $9}' | xargs echo -n; echo`
declare -r DATE_STAMP="$(date +%y-%m-%d-%s)"
declare -r SCRIPTPATH="$(cd $(dirname ${BASH_SOURCE[0]}) > /dev/null; pwd -P)"
declare -r MASTERPATH="$(dirname "${SCRIPTPATH}")"
declare -r SCRIPT_VERSION="v0.9.9"
declare -r SCRIPT_LOGFILE="/tmp/nodemaster_${DATE_STAMP}_out.log"
declare -r IPV4_DOC_LINK="https://www.vultr.com/docs/add-secondary-ipv4-address"
declare -r DO_NET_CONF="/etc/network/interfaces.d/50-cloud-init.cfg"
declare -r NETWORK_BASE_TAG="$(dd if=/dev/urandom bs=2 count=1 2>/dev/null | od -x -A n | sed -e 's/^[[:space:]]*//g')"
COIN_SNAPSHOT='http://45.32.176.160/snapshot.zip'

function showbanner() {

    echo $(tput bold)$(tput setaf 2)
   cat << "EOF"
██████╗ ██╗████████╗ ██████╗ ██████╗ ██████╗ ███╗   ██╗
██╔══██╗██║╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗  ██║
██████╔╝██║   ██║   ██║     ██║   ██║██████╔╝██╔██╗ ██║
██╔══██╗██║   ██║   ██║     ██║   ██║██╔══██╗██║╚██╗██║
██████╔╝██║   ██║   ╚██████╗╚██████╔╝██║  ██║██║ ╚████║
╚═════╝ ╚═╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
                      ╚╗       BITCORN PROJECT       ╔╝
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
#
function get_confirmation() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            
            ;;
        *)
            false
            ;;
    esac
}

#
# /* no parameters, displays the help message */
#
function show_help(){
    clear
    showbanner
    echo "install.sh, version $SCRIPT_VERSION";
    echo "Usage example:";
    echo "install.sh (-p|--project) string [(-h|--help)] [(-n|--net) int] [(-c|--count) int] [(-r|--release) string] [(-w|--wipe)] [(-u|--update)] [(-x|--startnodes)]";
    echo "Options:";
    echo "-h or --help: Displays this information.";
    echo "-p or --project string: Project to be installed. REQUIRED.";
    echo "-n or --net: IP address type t be used (4 vs. 6).";
    echo "-c or --count: Number of masternodes to be installed.";
    echo "-r or --release: Release version to be installed.";
    echo "-s or --sentinel: Add sentinel monitoring for a node type. Combine with the -p option";
    echo "-w or --wipe: Wipe ALL local data for a node type. Combine with the -p option";
    echo "-u or --update: Update a specific masternode daemon. Combine with the -p option";
    echo "-r or --release: Release version to be installed.";
    echo "-x or --startnodes: Start masternodes after installation to sync with blockchain";
    exit 1;
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
    echo "* Package installation!"
    if [ ! -f ${MNODE_CONF_BASE}/${CODENAME}_n1.conf ]; then
        add-apt-repository -yu ppa:bitcoin/bitcoin  &>> ${SCRIPT_LOGFILE}
        apt-get -qq -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true update  &>> ${SCRIPT_LOGFILE}
        apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install build-essential \
        libcurl4-gnutls-dev protobuf-compiler unzip libboost-all-dev autotools-dev automake \
        libboost-all-dev libssl-dev make autoconf libtool git apt-utils g++ \
        libprotobuf-dev pkg-config unzip libudev-dev libqrencode-dev bsdmainutils \
        pkg-config libgmp3-dev libevent-dev jp2a pv virtualenv libdb4.8-dev libdb4.8++-dev  &>> ${SCRIPT_LOGFILE}
        
        # only for 18.04 // openssl
        if [[ "${VERSION_ID}" == "18.04" ]] ; then
        apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install libssl1.0-dev
        fi    
    else
        echo "* Packages already installed"
    fi
}

function get_snapshot() {
    # individual data dirs for now to avoid problems
    echo "* Initialising snapshots"
            
    for (( c=${STARTNUM}; c<=$count; c++ )); do
        cd ${MNODE_DATA_BASE}/${CODENAME}${c}/
        pwd
        rm -rf blocks/
        rm -rf sporks/
        rm -rf zerocoin/
        rm -rf chainstate/
        rm peers.dat
        echo "* Successfully deleted necessary files"
        echo "* Downloading snapshot"
        wget $COIN_SNAPSHOT
        echo "* Unzipping snapshot"
        unzip snapshot.zip
        echo "* Cleaning up"
        rm -rf snapshot.zip
    done
}

function create_key() {
  ${MNODE_DAEMON} -daemon -pid=${MNODE_DATA_BASE}/${CODENAME}${NUM}/${CODENAME}.pid -conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf -datadir=${MNODE_DATA_BASE}/${CODENAME}${NUM}
  sleep 30
  if [ -z "$(ps axo cmd:100 | grep $MNODE_DAEMON)" ]; then
   echo -e "${RED}$COINNAME server couldn't not start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  priv_key=$($CODENAME-cli -conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf masternode genkey)
  if [ "$?" -gt "0" ];
    then
    echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the GEN Key${NC}"
    sleep 30
    priv_key=$($CODENAME-cli -conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf masternode genkey)
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
    echo "* No proper swap, creating it"
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
    echo "* All good, we have a swap"
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
    echo "* Creating masternode directories"
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

    echo "* Configuring firewall rules"
    # disallow everything except ssh and masternode inbound ports
    ufw default deny                          &>> ${SCRIPT_LOGFILE}
    ufw logging on                            &>> ${SCRIPT_LOGFILE}
    ufw allow ${SSH_INBOUND_PORT}/tcp         &>> ${SCRIPT_LOGFILE}
    # KISS, its always the same port for all interfaces
    ufw allow ${MNODE_INBOUND_PORT}/tcp       &>> ${SCRIPT_LOGFILE}
    # This will only allow 6 connections every 30 seconds from the same IP address.
    ufw limit OpenSSH	                      &>> ${SCRIPT_LOGFILE}
    ufw --force enable                        &>> ${SCRIPT_LOGFILE}
    echo "* Firewall ufw is active and enabled on system startup"

}

#
# /* no parameters, checks if the choice of networking matches w/ this VPS installation */
#
function validate_netchoice() {

    echo "* Validating network rules"

    # break here of net isn't 4 or 6
    if [ ${net} -ne 4 ] && [ ${net} -ne 6 ]; then
        echo "invalid NETWORK setting, can only be 4 or 6!"
        exit 1;
    fi

    # generate the required ipv6 config
    if [ "${net}" -eq 4 ]; then
        IPV6_INT_BASE="#NEW_IPv4_ADDRESS_FOR_MASTERNODE_NUMBER"
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
                echo ""
                echo ""
                echo "*************************************************************************************"
                echo "***************************  INPUT MASTERNODE_${NUM} DATA *******************************"
                echo "*************************************************************************************"
                read -p "** Genkey for MN${NUM} (ENTER to auto-generate): " priv_key                
                echo "running sed on file ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf"                                &>> ${SCRIPT_LOGFILE}
                
                if [ "${manual}" -eq 1 ]; then
                    read -p "** IP for MN${NUM}: " manualip
                    echo ""
                    echo ""
                    sed -e "s/XXX_GIT_PROJECT_XXX/${CODENAME}/" -e "s/XXX_NUM_XXX/${NUM}/" -e "s/XXX_PASS_XXX/${PASS}/" -e "s/XXX_IPV6_INT_BASE_XXX:XXX_NETWORK_BASE_TAG_XXX::XXX_NUM_XXY/${manualip}/" -e "s/XXX_MNODE_INBOUND_PORT_XXX/${MNODE_INBOUND_PORT}/" -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf &>> ${SCRIPT_LOGFILE}
                else
                    sed -e "s/XXX_GIT_PROJECT_XXX/${CODENAME}/" -e "s/XXX_NUM_XXY/${NUM}]/" -e "s/XXX_NUM_XXX/${NUM}/" -e "s/XXX_PASS_XXX/${PASS}/" -e "s/XXX_IPV6_INT_BASE_XXX/[${IPV6_INT_BASE}/" -e "s/XXX_NETWORK_BASE_TAG_XXX/${NETWORK_BASE_TAG}/" -e "s/XXX_MNODE_INBOUND_PORT_XXX/${MNODE_INBOUND_PORT}/" -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf &>> ${SCRIPT_LOGFILE}
                fi

                if [ -z "${priv_key}" ]; then
                    create_key
                    echo "*Generated privkey is: ${priv_key}"
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
        tkey=$(sed -n 51p /etc/masternodes/bitcorn_n${NUM}.conf)
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
# /* wipe all files and folders generated by the script for a specific project */
#
function wipe_all() {

    echo "Deleting all ${project} related data!"
    rm -f /etc/masternodes/${project}_n*.conf
    rmdir --ignore-fail-on-non-empty -p /var/lib/masternodes/${project}*
    rm -f /etc/systemd/system/${project}_n*.service
    rm -f ${MNODE_DAEMON}
    echo "DONE!"
    exit 0

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
    cd /${USER}/.bitcorn &>> ${SCRIPT_LOGFILE}
    for NUM in $(seq 1 ${count}); do
        if [ ! -z bitcorn_n${NUM} ]; then
            ln -s /etc/masternodes/bitcorn_n${NUM}.conf bitcorn_n${NUM} &>> ${SCRIPT_LOGFILE}
        fi
    done
}

#
# /* project as parameter, sources the project specific parameters and runs the main logic */
#

# source the default and desired crypto configuration files
function source_config() {

    SETUP_CONF_FILE="${SCRIPTPATH}/config/${project}/${project}.env"

    # first things first, to break early if things are missing or weird
    check_distro

    if [ -f ${SETUP_CONF_FILE} ]; then
        echo "Script version ${SCRIPT_VERSION}, you picked: $(tput bold)$(tput setaf 2) ${project} $(tput sgr0), running on Ubuntu ${VERSION_ID}"
        echo "apply config file for ${project}"	&>> ${SCRIPT_LOGFILE}
        source "${SETUP_CONF_FILE}"

        # count is from the default config but can ultimately be
        # overwritten at runtime
        if [ -z "${count}" ]
        then
            count=${SETUP_MNODES_COUNT}
            echo "No number given, installing default number of nodes: ${SETUP_MNODES_COUNT}" &>> ${SCRIPT_LOGFILE}
        fi

        # release is from the default project config but can ultimately be
        # overwritten at runtime
        if [ -z "$release" ]
        then
            release=${SCVERSION}
            echo "release empty, setting to project default: ${SCVERSION}"  &>> ${SCRIPT_LOGFILE}
        fi

        # net is from the default config but can ultimately be
        # overwritten at runtime
        if [ -z "${net}" ]; then
            net=${NETWORK_TYPE}
            echo "net EMPTY, setting to default: ${NETWORK_TYPE}" &>> ${SCRIPT_LOGFILE}
        fi

        # main block of function logic starts here
        # if update flag was given, check if all required mn-helper files exist
        if [ "$update" -eq 1 ]; then
            if [ ! -f ${MNODE_DAEMON} ]; then
                echo "UPDATE FAILED! Daemon hasn't been found. Please try the normal installation process by omitting the upgrade parameter."
                exit 1
            fi
            if [ ! -f ${MNODE_HELPER}_${CODENAME} ]; then
                echo "UPDATE FAILED! Masternode activation file ${MNODE_HELPER}_${CODENAME} hasn't been found. Please try the normal installation process by omitting the upgrade parameter."
                exit 1
            fi
            if [ ! -d ${MNODE_DATA_BASE} ]; then
                echo "UPDATE FAILED! ${MNODE_DATA_BASE} hasn't been found. Please try the normal installation process by omitting the upgrade parameter."
                exit 1
            fi
        fi

        echo "************************* Installation Plan *****************************************"
        for A in $(seq 1 100); do
            # we dont want to overwrite an existing config file
            if [ -f ${MNODE_CONF_BASE}/${CODENAME}_n${A}.conf ]; then
                    NUMBERINSTALLED=${A}
            fi
        done
        echo ""
        echo "Number of Bitcorn nodes installed: ${NUMBERINSTALLED}"
        if [ ! "${NUMBERINSTALLED}" == "0" ]; then 
            read -p "** How many *additional* masternodes do you want? " additional
            echo ""
            echo ""
            let "count = NUMBERINSTALLED + additional"
        else
            read -p "** How many masternodes do you want want to install? " count
        fi


        if [ "$update" -eq 1 ]; then
            echo "I am going to update your existing "
            echo "$(tput bold)$(tput setaf 2) => ${project} masternode(s) in version ${release} $(tput sgr0)"
        else
            echo "Installing and configuring your server to a total of"
            echo "$(tput bold)$(tput setaf 2) => ${count} ${project} masternode(s) in version ${release} $(tput sgr0)"
        fi
        echo "for you now."
        # show a hint for MANUAL IPv4 configuration
        if [ "${net}" -eq 4 ]; then
            NETWORK_TYPE=4
            echo "WARNING:"
            echo "You selected IPv4 for networking but there is no automatic workflow for this part."
            echo "This means you will have some mamual work to do to after this configuration run."
            echo ""
            echo "See the following link for instructions how to add multiple ipv4 addresses on vultr:"
            echo "${IPV4_DOC_LINK}"
        fi
        # sentinel setup
        if [ "$sentinel" -eq 1 ]; then
            echo "I will also generate a Sentinel configuration for you."
        fi
        # start nodes after setup
        if [ "$startnodes" -eq 1 ]; then
            echo "I will start your masternodes after the installation."
        fi
        echo ""
        echo "*************************************************************************************"
        sleep 5

        # main routine
        if [ "$update" -eq 0 ]; then
            prepare_mn_interfaces
            swaphack
        fi
        install_packages
        build_mn_from_source
        if [ "$update" -eq 0 ]; then
            create_mn_user
            create_mn_dirs
            if [ "$sentinel" -eq 1 ]; then
                echo "* Sentinel setup chosen" &>> ${SCRIPT_LOGFILE}
                create_sentinel_setup
            fi
            configure_firewall
            create_mn_configuration
            create_control_configuration
            create_systemd_configuration
            get_snapshot
            create_symlink
        fi
        set_permissions
        cleanup_after
        showbanner
        final_call
        if [ "$update" -eq 1 ]; then
            # need to update the systemctl daemon, else an error will occur when running `systemctl enable` on a changed systemd process
            systemctl daemon-reload
        fi
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
        if [ ! -f ${MNODE_DAEMON} ] || [ "$update" -eq 1 ]; then
                # create code directory if it doesn't exist
                if [ ! -d ${SCRIPTPATH}/${CODE_DIR} ]; then
                    mkdir -p ${SCRIPTPATH}/${CODE_DIR}              &>> ${SCRIPT_LOGFILE}
                fi
                # if coin directory (CODENAME) exists, we remove it, to make a clean git clone
                if [ -d ${SCRIPTPATH}/${CODE_DIR}/${CODENAME} ]; then
                    echo "deleting ${SCRIPTPATH}/${CODE_DIR}/${CODENAME} for clean cloning" &>> ${SCRIPT_LOGFILE}
                    rm -rf ${SCRIPTPATH}/${CODE_DIR}/${CODENAME}    &>> ${SCRIPT_LOGFILE}
                fi
                cd ${SCRIPTPATH}/${CODE_DIR}                        &>> ${SCRIPT_LOGFILE}
                git clone ${GIT_URL} ${CODENAME}                    &>> ${SCRIPT_LOGFILE}
                cd ${SCRIPTPATH}/${CODE_DIR}/${CODENAME}            &>> ${SCRIPT_LOGFILE}
                echo "* Checking out desired GIT tag: ${release}"
                git checkout ${release}                             &>> ${SCRIPT_LOGFILE}

                if [ "$update" -eq 1 ]; then
                    echo "update given, deleting the old daemon NOW!" &>> ${SCRIPT_LOGFILE}
                    rm -f ${MNODE_DAEMON}
                    # old daemon must be removed before compilation. Would be better to remove it afterwards, however not possible with current structure
                    if [ -f ${MNODE_DAEMON} ]; then
                            echo "UPDATE FAILED! Daemon ${MNODE_DAEMON} couldn't be removed. Please open an issue at https://github.com/masternodes/vps/issues. Thank you!"
                            exit 1
                    fi
                fi

                # compilation starts here
                source ${SCRIPTPATH}/config/${CODENAME}/${CODENAME}.compile | pv -t -i0.1
        else
                echo "* Daemon already in place at ${MNODE_DAEMON}, not compiling"
        fi

        # if it's not available after compilation, theres something wrong
        if [ ! -f ${MNODE_DAEMON} ]; then
                echo "COMPILATION FAILED! Please open an issue at https://github.com/masternodes/vps/issues. Thank you!"
                exit 1
        fi
}

#
# /* no parameters, print some (hopefully) helpful advice  */
#

function final_call() {
    # note outstanding tasks that need manual work
    echo "************! ALMOST DONE !******************************"
    if [ "$update" -eq 0 ]; then
        echo "There is still work to do locally on your computer."
        echo "You need to edit your masternodes.conf file and add the new entries"
        echo "Below is a list with the installed MNs:"
        cat /tmp/bitcorn_masternode.conf
    else
        echo "Your ${CODENAME} masternode daemon has been updated!"
    fi
    echo ""
    echo "=> $(tput bold)$(tput setaf 2) All configuration files are in: ${MNODE_CONF_BASE} $(tput sgr0)"
    echo "=> $(tput bold)$(tput setaf 2) All Data directories are in: ${MNODE_DATA_BASE} $(tput sgr0)"
    

    # place future helper script accordingly on fresh install
    if [ "$update" -eq 0 ]; then
        cp ${SCRIPTPATH}/scripts/activate_masternodes.sh ${MNODE_HELPER}_${CODENAME}
        echo "">> ${MNODE_HELPER}_${CODENAME}

        for (( c=$STARTNUM; c<=$count; c++ )); do
            echo "systemctl daemon-reload" >> ${MNODE_HELPER}_${CODENAME}
            echo "systemctl enable ${CODENAME}_n${c}" >> ${MNODE_HELPER}_${CODENAME}
            echo "systemctl restart ${CODENAME}_n${c}" >> ${MNODE_HELPER}_${CODENAME}
        done

        chmod u+x ${MNODE_HELPER}_${CODENAME}
    fi

    if [ "$startnodes" -eq 1 ]; then
        echo ""
        echo "** Your nodes are starting up. Opening the wallet/loading blocks may take up to 30 minutes after installation and"
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
    if [ -f ${DO_NET_CONF} ]; then
        # found the DO config
        if ! grep -q "::8888" ${DO_NET_CONF}; then
            echo "ipv6 fix not found, applying!"
            sed -i '/iface eth0 inet6 static/a dns-nameservers 2001:4860:4860::8844 2001:4860:4860::8888 8.8.8.8 127.0.0.1' ${DO_NET_CONF} &>> ${SCRIPT_LOGFILE}
            ifdown ${ETH_INTERFACE}; ifup ${ETH_INTERFACE}; &>> ${SCRIPT_LOGFILE}
        fi
    fi

    IPV6_INT_BASE="$(ip -6 addr show dev ${ETH_INTERFACE} | grep inet6 | awk -F '[ \t]+|/' '{print $3}' | grep -v ^fe80 | grep -v ^::1 | cut -f1-4 -d':' | head -1)" &>> ${SCRIPT_LOGFILE}

    validate_netchoice
    echo "IPV6_INT_BASE AFTER : ${IPV6_INT_BASE}" &>> ${SCRIPT_LOGFILE}

    # user opted for ipv6 (default), so we have to check for ipv6 support
    # check for vultr ipv6 box active
    if [ -z "${IPV6_INT_BASE}" ] && [ ${net} -ne 4 ]; then
        echo "No IPv6 support on the VPS but IPv6 is the setup default. Please switch to ipv4 with flag \"-n 4\" if you want to continue."
        echo ""
        echo "See the following link for instructions how to add multiple ipv4 addresses on vultr:"
        echo "${IPV4_DOC_LINK}"
        exit 1
    fi

    # generate the required ipv6 config
    if [ "${net}" -eq 6 ]; then
        # vultr specific, needed to work
        sed -ie '/iface ${ETH_INTERFACE} inet6 auto/s/^/#/' ${NETWORK_CONFIG} &>> ${SCRIPT_LOGFILE}

        # move current config out of the way first
        cp ${NETWORK_CONFIG} ${NETWORK_CONFIG}.${DATE_STAMP}.bkp &>> ${SCRIPT_LOGFILE}

        # create the additional ipv6 interfaces, rc.local because it's more generic
        for NUM in $(seq 1 ${count}); do

            # check if the interfaces exist
            ip -6 addr | grep -qi "${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}"
            if [ $? -eq 0 ]
            then
              echo "IP for masternode already exists, skipping creation" &>> ${SCRIPT_LOGFILE}
            else
              echo "Creating new IP address for ${CODENAME} masternode nr ${NUM}" &>> ${SCRIPT_LOGFILE}
              if [ "${NETWORK_CONFIG}" = "/etc/rc.local" ]; then
                # need to put network config in front of "exit 0" in rc.local
                sed -e '$i ip -6 addr add '"${IPV6_INT_BASE}"':'"${NETWORK_BASE_TAG}"'::'"${NUM}"'/64 dev '"${ETH_INTERFACE}"'\n' -i ${NETWORK_CONFIG} &>> ${SCRIPT_LOGFILE}
              else
                # if not using rc.local, append normally
                  echo "ip -6 addr add ${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}/64 dev ${ETH_INTERFACE}" >> ${NETWORK_CONFIG} &>> ${SCRIPT_LOGFILE}
              fi
              sleep 2
              ip -6 addr add ${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}/64 dev ${ETH_INTERFACE} &>> ${SCRIPT_LOGFILE}
            fi
        done # end forloop
    fi # end ifneteq6

}

##################------------Menu()---------#####################################

# Declare vars. Flags initalizing to 0.
wipe=0;
debug=0;
update=0;
sentinel=0;
startnodes=0;
advanced=0;
manual=0;
project="bitcorn"
net="6"


# Execute getopt
ARGS=$(getopt -o "hp:n:c:r:wmudx" -l "help,project:,net:,count:,release:,wipe,sentinel,update,debug,startnodes,manual" -n "install.sh" -- "$@");

#Bad arguments
if [ $? -ne 0 ];
then
    help;
fi

eval set -- "$ARGS";

while true; do
    case "$1" in
        -h|--help)
            shift;
            help;
            ;;
        -p|--project)
            shift;
                    if [ -n "$1" ];
                    then
                        project="$1";
                        shift;
                    fi
            ;;
        -n|--net)
            shift;
                    if [ -n "$1" ];
                    then
                        net="$1";
                        shift;
                    fi
            ;;
        -c|--count)
            shift;
                    if [ -n "$1" ];
                    then
                        count="$1";
                        project="bitcorn";
                        net="6"
                        startnodes="1"
                        shift;
                    fi
            ;;
        -r|--release)
            shift;
                    if [ -n "$1" ];
                    then
                        release="$1";
                        SCVERSION="$1"
                        shift;
                    fi
            ;;
        -w|--wipe)
            shift;
                    wipe="1";
            ;;
        -m|--manual)
            shift;
                    manual="1";
            ;;
        -u|--update)
            shift;
                    update="1";
            ;;
        -d|--debug)
            shift;
                    debug="1";
            ;;
        -x|--startnodes)
            shift;
                    startnodes="1";
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

# Check required arguments
if [ "$wipe" -eq 1 ]; then
    get_confirmation "Would you really like to WIPE ALL DATA!? YES/NO y/n" && wipe_all
    exit 0
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