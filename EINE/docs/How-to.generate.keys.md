HOW TO generate keys for EINE
=============================

For deploying EINE solution, you need to generate your own SSH/Certificates.
Here is how to do these steps.

Pre-requisite
=============

On your FreeBSD developement machine, you need these packages installed
  * easy-rsa (for generating certificates)
  * openvpn (for generating the key)

Then, go into the BSD Router Project source directory and set the dir variable.
Example using tcsh shell:
```
setenv BSDRP_DIR `pwd`
```

Keys directory
==============

Create your local data directory:

```
mkdir ${BSDRP_DIR}/EINE/local.data
```

SSH keys
========

EINE use by default ED25519 SSH keys:
```
ssh-keygen -t ed25519 -b 256 -o -f ${BSDRP_DIR}/EINE/local.data/id_ed25519
```

And use a good password for protecting the private key.

Detail of ssh-keygen options used:
  * -o: new openSSH format (increased resistance to brute-force password cracking)
  * -t: ed25519 (recommanded curve)
  * -b: 256bits algo

OpenVPN certificate
===================

We will use easy-RSA for creating the CA and the "unregistered" common certificate.
Here is an example used for the DEMO keys:

```
cp /usr/local/share/easy-rsa/vars ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars
sed -i "" -e '/KEY_SIZE=/s/1024/2048/' ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars
sed -i "" -e '/KEY_COUNTRY=/s/US/FR/' ${BSDRP_DIR}/EINE/local.data/etc/easy-rsa.vars
sed -i "" -e '/KEY_PROVINCE=/s/CA/Bretagne/' ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars
sed -i "" -e '/KEY_CITY=/s/SanFrancisco/Rennes/' ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars
sed -i "" -e '/KEY_ORG=/s/Fort-Funston/Orange Business Services/' ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars
sed -i "" -e '/KEY_OU=/s/MyOrganizationalUnit/EINE DEMO unsecure certificate/' ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars
sed -i "" -e '/KEY_EMAIL=/s/me@myhost.mydomain/olivier.cochard@orange.com/' ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars
echo 'export RANDFILE=${KEY_DIR}/.rnd' >> ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars
sed 's/export/setenv/;s/=/ /' ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars > ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars.tcsh
cd /usr/local/share/easy-rsa
source ${BSDRP_DIR}/EINE/local.data/easy-rsa.vars.tcsh
sudo chmod g+w /usr/local/etc
./clean-all
./build-dh
env KEY_CN=CA KEY_NAME=CA ./pkitool --initca CA
env KEY_CN=unregistered KEY_NAME=unregistered ./pkitool unregistered
openvpn --genkey --secret ${KEY_DIR}/ta.key
openssl ca -gencrl -out ${KEY_DIR}/crl.pem -config "${KEY_CONFIG}"
mv keys ${BSDRP_DIR}/EINE/local.data/
sed -i "" -e '/KEY_DIR=/s/$EASY_RSA/\/usr\/local\/etc/' ${BSDRP_DIR}EINE/local.data/easy-rsa.vars
sed -i "" -e '/setenv KEY_DIR/s/$EASY_RSA/\/usr\/local\/etc/' ${BSDRP_DIR}EINE/local.data/easy-rsa.vars.tcsh
```

Generating keys archive
=======================

Once generated SSH keys and Certificates, we need to put them into an archive.
This archive will be copied to the EINE manager for initializing it.

```
tar cvfz ${BSDRP_DIR}/EINE/PROD.certs.tgz -C ${BSDRP_DIR}/EINE/local.data easy-rsa.vars easy-rsa.vars.tcsh keys id_ed25519
```
