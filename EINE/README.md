Easy Internet vpN Extender (EINE)
=================================

EINE is a solution for large-scale plug&play x86 network appliance deployment over Internet.

License: BSD 2-clause

Author: [Orange Business Services] (http://www.orange-business.com) 

EINE, a sub-project of BSD Router Project,  permit to generate an x86 raw image disk (appliance firmware) to be use for deploying this solution:

![EINE big picture](docs/images/big-picture.png)

The demo EINE firmware include build-in DEMO certificate and passwords that NEED to be customized for your usage.
Private AND public keys/certificates are embedded in the demo firmware, then are totally unsecure.

For building your own EINE firmware, you NEED:
  - A FreeBSD Operating system (10.1 minimum)
  - with an Internet access for downloading sources

Then you had to follow these steps:

1. Download source
```
svnlite co https://github.com/ocochard/BSDRP/trunk BSDRP
cd BSDRP
```
2. [Generate your own SSH keys and certificate](docs/How-to.generate.keys.md)
3. Create an EINE/local.data/data.conf file for declaring:
    - ADMIN_USERNAME: admin username
    - CONSOLE_PASSWORD: Root password
    - DOMAIN_NAME: domain name
    - GATEWAYS: List of of gateways hostname
    - OVPN_UNREG_PORT: UDP port to be used for unregistered gateway
    - SSH_PORT: Port used by sshd
    - check examples in [EINE/DEMO.data/data.conf](DEMO.data/data.conf)
4. Generate EINE x86 disk image using BSD Router Project build script
```
./make.sh -p EINE
```
