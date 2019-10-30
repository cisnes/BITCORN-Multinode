# Bitcorn Multinode

----
## What is multinode?


The **Multinode** script is a collection of utilities to manage, setup and update multiple Bitcorn masternodes on 1 VPS.

Using this multinode script you are able to have around 4 or 5 Bitcorn masternodes running on one $5 1GB Ram Vultr VPS Server.

If you need support, contact Pineapple or MrAnthony in the <a href="https://discord.gg/eJQJeBB">CTTV Discord</a>

---

## Recommended VPS provider

**Vultr** is required for this script to work. Make sure to click "IPv6 during installation of the server.

Feel free to use our referral link to signup w/ vultr:

<a href="https://www.vultr.com/?ref=7755704"><img src="https://www.vultr.com/media/banner_2.png" width="468" height="60"></a>

---

## Features of Multinode

* 100% auto-compilation and 99% of configuration on the masternode side of things.
* Developed with 16.04 Ubuntu versions
* Installs 1-100 (or more!) masternodes in parallel on one machine, with individual config and data
* Compilation is currently from source for the desired git repo tag (configurable via config files)
* Some security hardening is done, including firewalling and a separate user
* Automatic startup for all masternode daemons
* This script needs to run as root, the masternodes will and should not!
* It's ipv6 enabled!

# Installation

Below is a guide meant to help you install your masternodes

### 0.0 - Create VPS

***Step 1***
* Register at [Vultr](https://www.vultr.com/?ref=7755704)
***

***Step 2***
* After you have added funds to your account go [here](https://my.vultr.com/deploy/) to create your Server
***

***Step 3***
* Choose a server location (preferably somewhere close to you)
![Example-Location](https://i.imgur.com/ozi7Bkr.png)
***

***Step 4***
* Choose a server type: Ubuntu 16.04
![Example-OS](https://i.imgur.com/aSMqHUK.png)
***

***Step 5***
* Choose a server size: We recommend to purchase the $5 Vultr VPS with 1GB of Ram, this will allow you to install around 4 or 5 masternodes on this 1 VPS. Do not install more than this on the $5 VPS as you will run into space issues as you are only allowed 25GB max per VPS.

![Example-OS](https://i.imgur.com/WRiYXxt.png)
***

***Step 6***
* Under Additional Features tick Enable IPv6

![Example-hostname](https://i.imgur.com/jb05zjj.png)
***

***Step 7***
* Set a Server Hostname & Label (name it whatever you want)
![Example-hostname](https://i.imgur.com/UxGFmqD.png)
***

***Step 8***
* Click "Deploy now"

### 0.1 - Connect to the VPS 

***Step 1***
* Copy your VPS IP (find this within the server tab @ Vultr and clicking on your server.)
![Example-Vultr](https://i.imgur.com/spEVVCy.png)
***

***Step 2***
* Open the bitvise application, Click New Profile and fill in the "Hostname" box with the IP of your VPS then Port number "22".

![Example-PuttyInstaller](https://i.imgur.com/uvc0Ysp.png)
***

***Step 3***
* Input the username "root" and copy your password from the VULTR Server Page.  
* If you want you can save your password to your Bitvise profile just tick the Store Encrypted password in profile.
![Example-RootPass](https://i.imgur.com/JnXQXav.png)
![Example-BitvisePass](https://i.imgur.com/BxVCWFA.png)
***

***Step 4***
* Save your profile

![Example-Save](https://i.imgur.com/uMwBz0N.png)
***

***Step 5***
* Click login at the bottom of the Bitvise client.
![Example-LoginBitvise](https://i.imgur.com/BJAGVr6.png)
***

### 1.0 Install the masternodes
Paste the code below into the Bitvise terminal then press enter

    git clone https://github.com/BITCORNProject/BITCORN-Multinode.git && cd BITCORN-Multinode

![Example-clone](https://i.imgur.com/tAxaz2I.png)

The first installation of this script will take up to 30mins to get everything set up, so be patient. Later installations of additional masternodes will take a couple of minutes.

The script you will be using is in the *BITCORN-Multinode* folder and is called install.sh. You're calling this by using ./ as a prefix. The script can take one flag which is -m by running `./install.sh -m`. By calling that flag you will be given the opportunity to enter your own IP addresses during the installation. This can be useful if you are running your own servers, and not through Vultr. Do NOT type that unless you have your own IP-pool. 

The following command will start the script

    ./install.sh

The script will now tell you how many masternodes are installed on your server; and if it's a new server, how many you want to install. Type the number and press enter. 

### 2.1 Enter private keys

During the installation you are given the opportunity to either type in your old private keys or generate new ones. Just press enter if you want the script to generate the keys for you. You will be handed the keys once the installation is finished. 

### 2.4 Check masternode status
You can check the status of the blockchain sync process with this command

    bitcorn-cli -conf=bitcorn_n1 getinfo

You can use this command for each individual masternode number, just replace the node number (n1) with whatever number for the MN you want to check.

### 2.5 Check block-sync
The blockchain needs to be synced before you can start your MNs through the wallet. During the installation, the script downloaded 1gb+ worth of blocks, but it need to download the last week on it's own. You can check the status of this by typing 

    bitcorn-cli -conf=bitcorn_n1 mnsync status

For all masternodes (again change the number to check all). When it's returning true on IsBlockchainSynced, you can proceed to next step.

### 1.0 - Clone and open project on your VPS
## IMPORTANT

### 1.1 - Preparing the Local wallet

***Step 1***
* Download and install on the local PC / mac the Bitcorn wallet from [here](https://github.com/BITCORNProject/BITCORN/releases)
***

***Step 2***
* Make sure you have 10M CORN free in your wallet (or more if you need to set up several nodes).
***

***Step 3***
* Open your local PC / Mac wallet and head to the Masternodes tab. In the bottom right corner, click "Create Masternode Controller". You should see a pop-up like the following:
![Example-create](https://imgur.com/gXjZnyM)
***

***step 4***
* Click next, and you will see a field where you can enter your alias of your node. This is just a visual representation/name of your node in the wallet, so you stand freely to choose whatever you'd like. Though, it is recommended to numericly mark them for easier debugging.

![Example-console](https://imgur.com/Qh2REfW)
***

***Step 5***

* Click next, and you will see a field to enter your masternodes IP and port. Leave the port at 12211 and paste your IP address the masternode install script gave you once it was completed. 

![Example-console](https://imgur.com/jWtDXAg)
***

***Step 6***
* Click next and you should see the pop-up disappearing and a banner at the bottom telling you its a success.

![Example-console](https://imgur.com/U6XtOAp)
***

***Step 7***
* Repeat step 1-6 for all the nodes you want to install. 
***

***Step 8***

* After your installation on the VPS is finished, you will see a big CORN logo and lines like this. One line for each node installed on your VPS.

    MN1 [2001:19f0:7923:43v1:67fd::1]:12211 2nxKSKTDXws1w6ksurlt62RuKMZLHJrxSPSWyv7Bby9XMsCdGTfC TXHASH_MN1 OUTPUTID_MN1

Open up your masternodes.conf file locally on your computer. 
* For windows: Go to Start > Run > %APPDATA%\BitCorn
* For mac: Go to ~/Library/Application Support/BitCorn

In this file you will see one line for each node initialized in your local wallet. These lines are very similar to what the masternode outputted once the install was finished. 
***

***Step 9***

Copy the priv-key you got from your masternode and replace the one in masternodes.conf for each node. Privkey is the next string/text coming after :12211. 

End state is when both masternodes.conf and the output on your VPS have similar IPs and priv-keys. (And only masternodes.conf have the txhash and outputid.)

Note: Please note formatting of the file is very strict, and needs to be followed exactly as the example below. Do not have any empty lines in the project and do one MN per line:

It should look like this:
![Example-create](https://i.imgur.com/zR8ImHQ.png)

Click "File Save".
Close the Bitcorn Wallet.
Open the Bitcorn Wallet again.
***

***Step 10***

* Open the wallet and go to the Masternodes tab. Click on each new node and press "Start". 


***Step 11***

* Verify the node started by opening your VPS and typing this for each node (replace the number)

    bitcorn-cli -conf=bitcorn_n1 getmasternodestatus

If you get Status 4, everything is working.

***

## How to Move a Masternode from one Multinode VPS to another Multinode VPS

If you want to move a masternode from a VPS where you have multinode setup, perhaps to another multinode VPS with more resources you need to follow these steps:

***Step 1***

Setup another masternode on the new vps, Let the new node install and sync to latest block.

***Step 2***

Then once the new masternode is synced, run this command on the OLD vps you want to stop the node on

	systemctl stop bitcorn_n5

Replace "5" in n5 with the number of the masternode you are moving.

***Step 3***

Open your local wallets Masternode Configuration file and copy the masternode genkey from the masternode you want to move.

***Step 4***

On the new VPS edit the /etc/masternodes/bitcorn_n1.conf file and paste over the masternode key with the one you just copied.
Replace "1" in n1 with the number of the new masternode.

***Step 5***

Copy the IP address of the new masternode.

Save the edited .conf file.

***Step 7***

In your local wallets Masternode Configuration file paste over the old IP for that node with the new IP address you just copied.

***Step 8***

Then on the new VPS run the command

	systemctl restart bitcorn_n1
	
Replace "1" in n1 with the number of the new masternode.	

***Step 9***

Close and reopen the local Bitcorn wallet

***Step 10***

Then start the masternode from your local wallet.

If you did it successfully when you run the check masternode status command, it will return status 4 and show the new IP address.

	bitcorn-cli -conf=bitcorn_n1 masternode status


## Adding more MNs to your already existing chunk of BITCORN masternodes

First make sure you are in the BITCORN-Multinode folder where the script is, type the command

	cd BITCORN-Multinode

Start the script

```bash
./install.sh
```

It will tell you how many masternodes are installed, and you will be given the opportunity to define how many *additional* nodes you want to install. If you already have two and want to install three more, simply type 3 and press enter

After that, do the steps described in the main-installation part.


## How to update masternode core to a newer version

If you want to update the BITCORN core on a VPS running the multinode setup, please follow the steps. Multinode 2.0+ required!

***Step 1***

Kill all bitcorn processes by typing:

    killall -9 bitcornd

***Step 2***

Open the Multinode directory

    cd BITCORN-Multinode

***Step 3***

Make the update file executable

    chmod +x update.sh

***Step 4***

Start the update

    ./update.sh

This will take up to 30 minutes. You will see the Bitcorn logo once it's done.

***Step 5*** 

Start all nodes back up (do one at a time for faster loading)

    systemctl start bitcorn_n1

Repeat for the other nodes if you have any by replacing the number.
Check status with:

    bitcorn-cli -conf=/etc/masternodes/bitcorn_n1.conf getinfo

Once you get a static block number (and not -1, it's finished loading the blocks)

***Step 6*** 

Activate your nodes from your local wallet

Open your new wallet (v2.0), go to the Masternode tab, click on the node you want to start and click 'start'.

***Step 7***

Verify that your masternode have started by typing

    bitcorn-cli -conf=/etc/masternodes/bitcorn_n1.conf getmasternodestatus

You should see status 4.

***If any issues:***

Contact Pineapple on Discord.


# Troubleshooting

### Error, couldn't connect to server

This error will appear if the daemon for that node is not running and it's having issues. You can attempt to manually start her up by typing:

    bitcornd -daemon -pid=/var/lib/masternodes/bitcorn2/bitcorn.pid -conf=/etc/masternodes/bitcorn_n2.conf -datadir=/var/lib/masternodes/bitcorn2 

And

    systemctl restart bitcorn_n2

As always, replace the number with the number of the node failing. This will kickstart it and will say something like: "Bitcorn server starting" if it's successful.

This error can also appear if you did not enter the correct Masternode private key, make sure you entered a valid key and try again. If you still have no luck, reach out to Pineapple#5750 and he will take care of your node. 

### 
