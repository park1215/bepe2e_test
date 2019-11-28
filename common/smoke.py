import sys
from robot.api import logger
import resvno_query

def resvno_smoke_test():
    rl = resvno_query.RESVNO_LIB()
    status = rl.getStatus("all")
    if 'error' in status:     
        del status['in_error']
    return status