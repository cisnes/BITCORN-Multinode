# Bitcorn Multinode V3

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

### 1.0 - Clone and open project on your VPS

Paste the code below into the Bitvise terminal then press enter

    git clone https://github.com/BITCORNProject/BITCORN-Multinode.git && cd BITCORN-Multinode

![Example-clone](https://i.imgur.com/tAxaz2I.png)
## IMPORTANT

If you already have private keys and txhashes from your existing masternodes you want to migrate over to the script, you can reuse these. Just shut down the old servers and skip to step 2.0.

### 1.1 - Preparing the Local wallet

***Step 1***
* Download and install on the local PC / mac the Bitcorn wallet from [here](https://github.com/BITCORNProject/BITCORN/releases)
***

***Step 2***
* Send EXACTLY 10,000,000 Bitcorn to a new receiving address within your wallet. You must wait for 16 confirmations on the transaction before the masternode can be started.
* To make a new receiving address from inside the wallet go to - File > Receiving Addresses > New.
***

***Step 3***
* Create a text document to temporarily store information that you will need.
***

***step 4***
* Go to the console within the wallet, Tools > Debug Console 

![Example-console](https://i.imgur.com/sXWA7Ym.png)
***

***Step 5***

Back in the console type the command below and press enter

    masternode outputs
	
***

***Step 6***
* Copy the long key (this is your transaction ID) and the 0 or 1 at the end (this is your output index)
* Paste these into the text document you created earlier as you will need them in the next step.
***

***Step 7***
* Go to the tools tab within the wallet and click "Open Masternode Configuration File"
![Example-create](https://i.imgur.com/7wVJrIG.png)
***

***Step 8***

Enter the following data in this file for every masternode we want to setup as follows:

    MN01 IPGOESHERE PRIVATEKEYGOESHERE TXHASHGOESHERE OUTPUTIDGOESHERE
    MN02 IPGOESHERE PRIVATEKEYGOESHERE TXHASHGOESHERE OUTPUTIDGOESHERE

Note: The formatting of the file is very strict, and needs to be followed exactly as the example below. Do not have any empty lines in the project and do one MN per line:

* For `Alias` type something like "MN01" **don't use spaces**
* The `Address` is the IPv6 and port of your server; that you find in Step 2.2 below, make sure the port is set to **12211**.
* The `PrivateKey` is the private key/genkey of your masternode, which you can find in step 2.1 below
* The `TxHash` is the transaction ID/long key that you copied to the text file.
* The `Output Index` is the 0 or 1 that you copied to your text file.
![Example-create](https://i.imgur.com/zR8ImHQ.png)

Click "File Save".
Close the Bitcorn Wallet.
Open the Bitcorn Wallet again.
***

### 2.0 Install the masternodes
By now you have prepared your wallet with the necessary variables and it's time to initialize script and make masternodes. 

The first installation of this script will take up to 30mins to get everything set up, so be patient. Later installations of additional masternodes will take a couple of minutes.

The script you will be using is in the *BITCORN-Multinode* folder and is called install.sh. You're calling this by using ./ as a prefix. The script can take one flag which is -m by running `./install.sh -m`. By calling that flag you will be given the opportunity to enter your own IP addresses during the installation. This can be useful if you are running your own servers, and not through vultr. Do NOT type that unless you have your own IP-pool. 

The following command will start the script

    ./install.sh

The script will now tell you how many masternodes are installed on your server; and if it's a new server, how many you want to install. Type the number and press enter. 

### 2.1 Enter private keys

During the installation you are given the opportunity to either type in your old private keys or generate new ones. Just press enter if you want the script to generate the keys for you. You will be handed the keys once the installation is finished. 

### 2.2 Find IP-addresses and private keys
When the installation is done, you will be returned back to the normal console with a list of the current installed masternodes and it's data. Copy the information to masternodes.conf locally on your computer. 


### 2.4 Check masternode status
You can check the status of the blockchain sync process with this command

    bitcorn-cli -conf=bitcorn_n1 getinfo

You can use this command for each individual masternode number, just replace the node number (n1) with whatever number for the MN you want to check.

### 2.5 Check block-sync
The blockchain needs to be synced before you can start your MNs through the wallet. During the installation, the script downloaded 1gb+ worth of blocks, but it need to download the last week on it's own. You can check the status of this by typing 

    bitcorn-cli -conf=bitcorn_n1 mnsync status

For all masternodes (again change the number to check all). When it's returning true on synced, you can proceed to next step

### 2.6 Start masternode from wallet
Before you start the masternodes from your local wallet, make sure you have closed the local wallet and re-opened it after saving your updated masternode.conf file.

To start the MN from the wallet. Do it in the debug console of the wallet like this:

    startmasternode alias 0 MN01

Replace MN01 with the alias from masternodes.conf you want to start.
Confirm the MN is started by typing this on the VPS.

    bitcorn-cli -conf=bitcorn_n1 masternode status

Again replace the number with what you want to change. 

Now you're done!

## Adding more MNs to your already existing chunk of BITCORN masternodes

First make sure you are in the BITCORN-Multinode folder where the script is, type the command

	cd BITCORN-Multinode

Start the script

```bash
./install.sh
```

It will tell you how many masternodes are installed, and you will be given the opportunity to define how many *additional* nodes you want to install. If you already have two and want to install three more, simply type 3 and press enter

After that, do the steps described in the main-installation part.


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



# Troubleshooting

### Error, couldn't connect to server

This error will appear if the daemon for that node is not running and it's having issues. You can attempt to manually start her up by typing:

    bitcornd -daemon -pid=/var/lib/masternodes/bitcorn2/bitcorn.pid -conf=/etc/masternodes/bitcorn_n2.conf -datadir=/var/lib/masternodes/bitcorn2 

And

    systemctl restart bitcorn_n2

As always, replace the number with the number of the node failing. This will kickstart it and will say something like: "Bitcorn server starting" if it's successful.

This error can also appear if you did not enter the correct Masternode private key, make sure you entered a valid key and try again. If you still have no luck, reach out to Pineapple#5750 and he will take care of your node. 

### 
