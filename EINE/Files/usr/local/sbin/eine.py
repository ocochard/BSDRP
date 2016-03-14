#!/usr/bin/env python2.7
# vim: sta:et:sw=4:ts=4:sts=4
# -*- coding: utf-8 -*-
"EINE module for all functions"
#
# Copyright (c) 2014-2016, Orange
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

import ConfigParser   # Permit to parse INI file
import hashlib        # Used for hashing CRL
import fileinput      # Used for replacing line in file
import glob           # Permit to use wildecard
import os             # Permit to call os.geteuid
import shutil         # Permit to copy file
import subprocess     # Call external commands
import sys            # Permit to call sys.exit

import yaml           # Permit to load ansible YAML file (just for the SSH port)
import netaddr        # Permit to convert IP address very easly

def check_duplicate(inv, args, gateway=False):
    "This check if some of the args members already exist in list inv"
    if args.hostname in inv:
        return False
    if args.loopback in inv:
        return False
    if gateway:
        if str(netaddr.IPNetwork(args.registered)) in inv:
            return False
        if str(netaddr.IPNetwork(args.unregistered)) in inv:
            return False
        if str(netaddr.IPNetwork(args.internal)) in inv:
            return False
        if str(netaddr.IPNetwork(args.external)) in inv:
            return False
    else:
        if str(netaddr.IPNetwork(args.lan)) in inv:
            return False
    return True

def pprint_table(out, table):
    """Prints out a table of data, padded for alignment
    @param out: Output stream (file-like object)
    @param table: The table to print. A list of lists.
    Each row must have the same number of columns.
    ginstrom.com/scribbles/2007/09/04/pretty-printing-a-table-in-python/"""

    def get_max_width(table1, index1):
        "Get the maximum width of the given column index"
        return max([len(str(row[index1])) for row in table1])

    col_paddings = []
    for i in range(len(table[0])):
        col_paddings.append(get_max_width(table, i))

    for row in table:
        # left col
        print >> out, row[0].ljust(col_paddings[0] + 1),
        # rest of the cols
        for i in range(1, len(row)):
            col = str(row[i]).rjust(col_paddings[i] + 2)
            print >> out, col,
        print >> out

def shell(cmd):
    "This send a shell command and return exit code and output"
    cmdline = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT)
    out = cmdline.communicate()[0]
    if cmdline.returncode != 0:
        return False, out
    else:
        return True, out


def ansible(command, inventory, group, hostname=None):
    "This send an Ansible command to group/hostname"
    cmd = ['ansible', '-i', inventory]
    cmd.append(group)
    if hostname is not None:
        cmd.append('--limit='+hostname)
    cmd.append('--sudo')
    cmd.append('-a')
    cmd.append(command)
    return shell(cmd)


def ansible_playbook(inventory, playbook, hostname=None, tags=None):
    "This execute ansible-playbook template"
    cmd = ['ansible-playbook', '-i', inventory]
    if hostname is not None:
        cmd.append('--limit='+hostname)
    if tags is not None:
        cmd.append('--tags')
        cmd.append(tags)
    cmd.append(playbook)
    return shell(cmd)


def is_online(address):
    "This test online status by a simple ping"
    return shell(['ping', '-c 2', address])

def pki_create(customer, pki_dir):
    "This create a pki for customer (including management)"
    return True

def cert_create(hostname, model, customer, template_dir, pki_dir, server_cert=False):
    "This create certificate using easy-rsa 3"
    environement['EASYRSA'] = pki_dir + '/' + customer
    if server_cert:
        cmd = ["easyrsa", "build-server-full", hostname, "nopass"]
    else:
        cmd = ["easyrsa", "build-client-full", hostname, "nopass"]
    easyrsa = subprocess.Popen(cmd,
                               env=environement, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT)
    out = easyrsa.communicate()[0]
    if easyrsa.returncode != 0:
        print out
        return False
    else:
        return True
    # Because we can't use the pktitool returncode (allways failed)
    # we need to check if crt size greater than 0
    if os.path.getsize(environement['EASYRSA'] + '/pki/issued/' + hostname
                       + '.crt') == 0:
        print out
        return False
    for key in glob.glob(environement['EASYRSA'] + '/' + pki_dir + '/issued/' + hostname + '.*'):
        shutil.copy2(key, template_dir + '/files/usr/local/etc/openvpn/')
    return True


def cert_delete(hostname, easyvars, client_tpl, gw_tpl, server=False):
    "This delete host's certificate"
    environement['EASYRSA'] = "/usr/local/etc/easy-rsa"
    environement = source(easyvars)
    environement['KEY_CN'] = hostname
    environement['KEY_NAME'] = hostname
    if not os.path.isfile(environement['KEY_DIR'] + '/' + hostname
                          + '.key'):
        return False

    # we start by getting the hash fo the CRL because revoke-full script
    # allways return failed
    oldhash = hashlib.sha256()
    with open(environement['KEY_DIR'] + '/crl.pem', 'rb') as crl:
        buf = crl.read()
        oldhash.update(buf)

    pkitool = subprocess.Popen(["./revoke-full", hostname],
                               cwd=environement['EASY_RSA'],
                               env=environement, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT)
    #out = pkitool.communicate()[0]
    pkitool.wait()

    # We recalculate the has of the CRL:
    newhash = hashlib.sha256()
    with open(environement['KEY_DIR'] + '/crl.pem', 'rb') as crl:
        buf = crl.read()
        newhash.update(buf)

    if oldhash == newhash:
        return False

    # delete certificate files in KEY_DIR
    for cert in glob.glob(environement['KEY_DIR'] + '/' + hostname + '.*'):
        os.remove(cert)

    if not server:
        # delete certificate files in client template
        for cert in glob.glob(client_tpl + '/files/usr/local/etc/openvpn/'
                              + hostname + '.*'):
            os.remove(cert)
        # Update the CRL on the gateways template
        # shutil.copy fails because os.chmod return "Operation not permitted"
        # shutil.copy2 fails because os.utime return "Operation not permitted"
        try:
            shutil.copy2(environement['KEY_DIR'] + '/crl.pem',
                         gw_tpl  + '/files/usr/local/etc/openvpn')
        except OSError:
            # Can't push permission on crl.pem
            pass
    return True


def is_in_hosts(hostname):
    "This check if parameter hostname is present in /etc/hosts"
    with open('/etc/hosts', 'r') as hostsfile:
        hosts = hostsfile.readlines()
    for item in hosts:
        if hostname in item:
            return True
    return False

def backup_hosts():
    "This backup hosts file"
    try:
        shutil.copy2('/etc/hosts', '/tmp/hosts')
    except:
        return False
    return True

def restore_hosts():
    "This restore hosts file"
    try:
        shutil.copy2('/tmp/hosts', '/etc/hosts')
    except:
        return False
    return True

def is_in_sshkey(hostname, known_hosts):
    "This check if hostname is present in "
    with open(known_hosts, 'r') as khfile:
        hosts = khfile.readlines()
    for item in hosts:
        if hostname in item:
            return True
    return False


def sshkey_add(hostname, known_hosts):
    "This add host SSH key to known_hosts"
    # But for that we need to know the SSH port to used first
    with open('/usr/local/etc/ansible/group_vars/freebsd', 'r') as var:
        group_vars = yaml.load(var)
    ssh = subprocess.Popen('ssh-keyscan -t ed25519 -p '
                           + str(group_vars['ansible_ssh_port']) + ' '
                           + hostname + ' >> ' + known_hosts, shell=True,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    #out = ssh.communicate()[0]
    ssh.wait()
    if ssh.returncode != 0:
        return False
    return True


def sshkey_del(hostname, known_hosts):
    "This delete host SSH key from known_hosts"
    # Can't use ssh-keygen -R: It's buggy
    found = False
    for line in fileinput.input(known_hosts, inplace=1):
        line = line.strip()
        if hostname not in line:
            print line
        else:
            found = True
    return found

def hosts_add(ipaddress, hostname):
    "This add entry to the /etc/hosts"
    with open('/etc/hosts', 'a') as hosts:
        hosts.writelines(ipaddress + '\t' + hostname + '\n')
    return True


def hosts_del(hostname):
    "This delete lines containing hostname"
    # Very stupid way of doing this, should use a smarter method
    with open('/etc/hosts', 'r') as hostsfile:
        hosts = hostsfile.readlines()
    with open('/etc/hosts', 'w') as hostsfile:
        for line in hosts:
            if hostname not in line:
                hostsfile.write(line)
    return True


def source(script):
    " Source variables from a shell script "
    # Insipred from :
    # http://pythonwise.blogspot.fr/2010/04/sourcing-shell-script.html
    pipe = subprocess.Popen(". %s 2>&1 >/dev/null; env" % script,
                            stdout=subprocess.PIPE, shell=True)
    data = pipe.communicate()[0]
    try:
        env = dict((line.split("=", 1) for line in data.splitlines()))
    except ValueError:
        print "Can't source this output:"
        print data
    return env


def is_root():
    " This check if root user"
    if os.geteuid() == 0:
        return True
    else:
        return False


def inventory_list(group, inv_file, hostvars_dir):
    " This get all inventory item of group"
    inventory = ConfigParser.SafeConfigParser(allow_no_value=True)
    inventory.read(inv_file)
    if inventory.has_section(group):
        full_inv = []
        for hosts in inventory.items(group):
            for host in hosts:
                if os.path.isfile(hostvars_dir + '/' + host):
                    variables = parse_config(hostvars_dir + '/' + host,
                                             ':', '-')
                    if group is 'vpn_wifi_routers':
                        full_inv.append([host, variables['if_lo_inet4_addr'],
                                         variables['if_lan_inet4_addr']+'/'
                                         +variables['if_lan_inet4_prefix']])
                    elif group is 'gateways':
                        full_inv.append([host, variables['if_lo_inet4_addr'],
                                         variables['if_int_inet4_addr'],
                                         variables['registered_inet4_net'],
                                         variables['unregistered_inet4_net']])
                    else:
                        sys.exit('ERROR: Unknown group {}'.format(group))
        return full_inv
    else:
        return False


def inventory_add(hostname, customer, model, inv_file):
    " This add host to ansible inventory file"
    # Loading Parser
    inventory = ConfigParser.SafeConfigParser(allow_no_value=True)
    inventory.read(inv_file)
    # Adding group section and add device
    group = customer + '_' + model
    if not inventory.has_section(group):
        inventory.add_section(group)
    if inventory.has_option(group, hostname):
        sys.exit('There is already a client named {} in inventory'
                 .format(hostname))
    else:
        inventory.set(group, hostname)
    if not inventory.has_option('freebsd:children', group):
        inventory.set('freebsd:children', group)
    if not inventory.has_option(model+':children', group):
        inventory.set(model+':children', group)
    with open(inv_file, 'w') as inv:
        inventory.write(inv)
    return True


def inventory_del(hostname, group, inv_file):
    " This remove host from ansible inventory file"
    # Loading Parser
    inventory = ConfigParser.SafeConfigParser(allow_no_value=True)
    inventory.read(inv_file)
    # Removing client, and section if empty after
    if inventory.has_option(group, hostname):
        inventory.remove_option(group, hostname)
        if not inventory.options(group):
            inventory.remove_section(group)
            inventory.remove_option('freebsd:children', group)
        with open(inv_file, 'w') as inv:
            inventory.write(inv)
    return True

def parse_config(filename, option_char, comment_char):
    " This parse a configuration file and return a dict "
    # http://www.decalage.info/fr/python/configparser
    options = {}
    with open(filename) as config:
        for line in config:
            # First, remove comments:
            if comment_char in line:
                # split on comment char, keep only the part before
                line, comment = line.split(comment_char, 1)
            # Second, find lines with an option=value:
            if option_char in line:
                # split on option char:
                option, value = line.split(option_char, 1)
                # strip spaces:
                option = option.strip()
                value = value.strip()
                # store in dictionary:
                options[option] = value
    return options
