__author__ = 'collector'

import os
from datetime import datetime
from yard.settings import BASE_DIR, DEBUG

def logger(aMsg, alogFile = BASE_DIR + 'djgw.log'):
    lMsg = datetime.now().strftime('%y-%m-%d %H:%M:%S -> ') + aMsg + os.linesep
    print(lMsg)
    if DEBUG:
        a = open(alogFile, 'a+')
        a.write(lMsg)
        a.close()
    # if os.path.exists(alogFile): raise Exception("our system log file does not exist") 直接写。

'''
>>> import zdCommon.utils
>>> zdCommon.utils.dump2file('sdfs', 'aa.txt')
>>> b = zdCommon.utils.load4file('aa.txt')
'''

from pickle import dump, load, dumps
def dump2file(aobj, afilename):
    ls_file = BASE_DIR + afilename
    a = open(ls_file, 'wb')
    dump(aobj, a)
    a.close()

def load4file(afilename):
    ls_file = BASE_DIR + afilename
    a = open(ls_file, 'rb')
    l_obj = load(a)
    a.close()
    return(l_obj)

