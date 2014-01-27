__author__ = 'dh'

import json
from datetime import date,datetime
from django.db import connection

def correctjsonfield(obj):
    if isinstance(obj,datetime):
        return obj.strftime('%Y-%m-%d %H:%M:%S')
    elif isinstance(obj,date):
        return obj.strftime('%Y-%m-%d')
    elif isinstance(obj,bool):
        if obj:
            return "true"
        else:
            return "false"
    else:
        return obj

def rawsql2json(aSql, aParm=None):
    l_cur = connection.cursor()
    if aParm:
        l_cur.execute(aSql, aParm)
    else:
        l_cur.execute(aSql)
    l_keys = [i.name for i in l_cur.description ]
    l_dict = {}
    l_count = 0
    for i in l_cur.fetchall():
        l_dictSub = {}
        for j in range(len(i)):
            l_dictSub.update( {l_keys[j]: correctjsonfield(i[j]) })
        l_dict.update( { l_count: l_dictSub } )
        l_count += 1
    return l_dict





