import sys
import argparse
import time
import json
import paramiko
import subprocess
from threading import Thread
from robot.api import logger
import random

class Conn_Lib:
    def jumpSsh(self, destHost, destUser, destPwd, jumpHost, jumpUser, jumpPwd):
        sshPort = 22
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(jumpHost, username=jumpUser, password=jumpPwd)
        
        sshTransport = ssh.get_transport()
        dest_addr = (destHost, sshPort) #edited#
        jump_addr = (jumpHost, sshPort) #edited#

        sshChannel = sshTransport.open_channel("direct-tcpip", dest_addr, jump_addr)

        ssh2 = paramiko.SSHClient()
        ssh2.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh2.connect(destHost, username=destUser, password=destPwd, sock=sshChannel)

        stdin, stdout, stderr = ssh2.exec_command("ip addr print")

        for line in stdout.read().splitlines():
            print(line)

        #print(stdout.read())
        
        ssh2.close()
        ssh.close() 
         
