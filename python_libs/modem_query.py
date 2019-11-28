import sys
import argparse
import time
from fabric import Connection
from threading import Thread
from robot.api import logger
import modem_parameters
import random

CPE = {'10.240.206.81':'10.240.5.63','10.240.109.14':'10.247.44.90','10.240.110.20':'10.247.44.102','10.240.110.21':'10.247.44.107','10.240.206.91':'10.240.5.64','10.240.110.19':'10.247.44.89'}
utstatWOutput = 'utstat -W'

class MODEM_LIB:
    def  __init__(self,host):
        self.host = host
        self.conn = Connection(
        host=host,
        user=modem_parameters.MODEM_USERNAME,
        connect_timeout=8,
        connect_kwargs={
            "password": modem_parameters.MODEM_PASSWORD,
        },
        )

    def getMacAndOnline(self):
        utstats = {}
        commands = {"ledState":"utstat -M  | grep ledState | awk '{print $2}'","umacState":"utstat -M  | grep umacState | awk '{print $4}'",
                    "cspConnected":"utstat -C | grep connected | awk '{print $2}'","macAddress":"utstat -M  | grep macAddress | awk '{print $4}'"}
        for statusItem in commands.keys():
            try:
                result = self.conn.run(commands[statusItem],hide=True)
                utstats[statusItem] = result.stdout
            except:
                for statusItem in commands.keys():
                    if statusItem not in utstats:
                        utstats[statusItem] = 'timeout'
                break
        # remove \n from end of each value
        for key, item in utstats.items():
            if item != 'timeout':
                utstats[key] = item[:-1]
        return utstats
        
    def getName(self):
        try:
            result = self.conn.run('hostname', hide=True)
            result = result.stdout[:-1]
        except:
            result = 'timeout'
        return result
        
    def runCommand(self,command,warn=False):
        try:
            result = self.conn.run(command, hide=True, warn=warn)
        except:
            result = modem_parameters.RESPONSE_FAILURE
        return result
        
    def setReservationFile(self,online):
        if online==True:
            utstats = self.getMacAndOnline()
            if utstats['ledState']!='Online' or utstats['umacState']!='Online':
                if utstats['ledState']==modem_parameters.TIMEOUT:
                    return modem_parameters.RESPONSE_FAILURE
                else:
                    return modem_parameters.OFFLINE
        result = self.runCommand('ls -l /mnt/jffs2/reserve_bep', warn=True)
        reserveResult = modem_parameters.RESPONSE_FAILURE
        if hasattr(result,'return_code'):
            if result.return_code == 0:
                reserveResult = modem_parameters.IN_USE
            # return code = 1 if "ls" did not find reserve_bep file : good for us
            elif result.return_code == 1:
                result = self.runCommand('touch /mnt/jffs2/reserve_bep', warn=True)
                if hasattr(result,'return_code') and result.return_code == 0:
                    reserveResult = modem_parameters.RESERVATION_SUCCESS
                
        return reserveResult
 
    def unsetReservationFile(self):
        result = self.runCommand('ls -l /mnt/jffs2/reserve_bep', warn=True)
        freeResult = modem_parameters.RESPONSE_FAILURE
        if hasattr(result,'return_code'):
            # reservation file already deleted - not good but nothing to do here
            if result.return_code == 1:
                logger.warn("reservation file already deleted for ip = "+self.host)
                freeResult = modem_parameters.RELEASE_SUCCESS
            elif result.return_code == 0:
                result = self.runCommand('rm /mnt/jffs2/reserve_bep', warn=True)
                if hasattr(result,'return_code'):
                    if result.return_code == 0:
                        freeResult = modem_parameters.RELEASE_SUCCESS
        return freeResult 
           
    def getSDFIDList(self):
        try:
            result = self.conn.run('utstat -W', hide=True)
            utstatWOutput = result.stdout
        except:
            utstatWOutput = "no response"   
        copy = False
        line = ""
        sdfids = []
        for character in utstatWOutput:
            if character == '\n':
                if copy:
                    if "|" not in line:
                        break   
                    columns= line.split("|")
                    try:
                        result = columns[9].strip()
                    except Exception as e:
                        result = ('problem with split: '+str(e))
                    sdfids.append(int(result))
                elif "SDFID" in line:               
                    copy = True        
                line = ""
            else:
                line += character
        return sdfids
    
    def getAllInfo(self):
        name = self.getName()
        status = self.getMacAndOnline()
        status['name'] = name
        status['sdfids'] = str(self.getSDFIDList())
        self.conn.close()
        return status
    
    def close(self):
        self.conn.close()

def getSDFIDs(ip):
    conn = MODEM_LIB(ip)
    response = conn.getSDFIDList()
    conn.close()
    return response
    
# from https://code.i-harness.com/en/q/693190
class ThreadWithReturnValue(Thread):
    def __init__(self, group=None, target=None, name=None, args=(), kwargs={}, Verbose=None):
        Thread.__init__(self, group, target, name, args, kwargs)
        self._return = None
    def run(self):
        if self._target is not None:
            self._return = self._target(*self._args, **self._kwargs)
    def join(self, *args):
        Thread.join(self, *args)
        return self._return

class modemQuery():
    def getAllModems():
        modemConn = {}
        t = {}
        for ip in MODEM_IPS:
            modemConn[ip] = MODEM_LIB(ip)
            t[ip] = ThreadWithReturnValue(target=modemConn[ip].getAllInfo)
            t[ip].start()
    
        # wait for all threads to complete   
        running = True
        result = {}
        while running == True:
            time.sleep
            running = False
            for ip in t:
                if t[ip].is_alive():
                    running = True
                else:
                    result[ip] = t[ip].join()
                    result[ip]['CPE'] = CPE[ip]
        return result
    
# returns RESERVATION_SUCCESS if successful    
def reserveModem(ip,online=False):
    conn = MODEM_LIB(ip)
    return conn.setReservationFile(online)

# returns RELEASE_SUCCESS if successful 
def freeModem(ip):
    conn = MODEM_LIB(ip)
    return conn.unsetReservationFile()

def pollModemsForReservation(modemType,timeoutDelta=0):
    macs = modem_parameters.MODEM_TYPE_MAPPINGS[modemType]
    random.shuffle(macs)
    reservedMac = None
    timeout = time.time() + timeoutDelta
    while True:
        for mac in macs:
            ip = modem_parameters.MODEM_IP_MAPPINGS[mac]
            result = reserveModem(ip)
            logger.info("reservation attempt for ip = "+ip+": "+result)
            if result == modem_parameters.RESERVATION_SUCCESS:
                reservedMac = mac
                break
        # continue searching until timeout
        if reservedMac == None:
            if time.time() > timeout:
                break
        else:
            break
    logger.info("reserveModem result = " + result)
    if reservedMac ==None:
        result = {"mac":None}
    else:
        for foundModemType in modem_parameters.MODEM_TYPE_MAPPINGS.keys():
            if mac in modem_parameters.SINGLE_MODEM_TYPE_MAPPINGS[foundModemType]:
                break
        result = {"mac":reservedMac,"ip":ip,"cpe":modem_parameters.MODEM_CPE_MAPPINGS[mac],"type":foundModemType}
    return result  

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("method", help="jira lib method to invoke")
    parser.add_argument("--host", help="ip address of host",default="10.240.109.9")
    args = parser.parse_args()

    if args.method=="getAllModems":
        modemConn = {}
        t = {}
        for ip in MODEM_IPS:
            modemConn[ip] = MODEM_LIB(ip)
            t[ip] = ThreadWithReturnValue(target=modemConn[ip].getAllInfo)
            t[ip].start()
    
        # wait for all threads to complete   
        running = True
        result = {}
        while running == True:
            time.sleep(10)
            running = False
            for ip in t:
                if t[ip].is_alive():
                    running = True
                else:
                    result[ip] = t[ip].join()
                    result[ip]['CPE'] = CPE[ip]
        print(str(result))
    else:
        modemConn = MODEM_LIB(args.host)
        utstats = modemConn.getMacAndOnline()
        print(utstats)
