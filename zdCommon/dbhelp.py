__author__ = 'dh'

import json
from datetime import date,datetime
from django.db import connection

def correctjsonfield(obj, atypecode):
    if obj:
        if isinstance(obj, datetime):
            return obj.strftime('%Y-%m-%d %H:%M:%S')
        elif isinstance(obj,date):
            return obj.strftime('%Y-%m-%d')
        elif isinstance(obj,bool):
            return "true"
        else:
            return obj
    else:
        if atypecode == 1043:    # varchar
            return ""
        elif atypecode == 1082:  # date
            return "1899-01-01"
        elif atypecode == 1083:  # time
            return "00:00:00"
        elif atypecode == 16:    # bool
            return "false"
        elif atypecode == 18:  # char            :
            return ""
        elif atypecode in( 20, 21, 23, 700, 701, 1700):  # int2,4 8, float4,8, numberic
            return 0
        else:
            raise Exception("遇到不认识的类型代码d%，请查询：SELECT typname, oid FROM pg_type;" % atypecode)
            return 0


def rawsql2json(aSql, aParm=None):
    l_cur = connection.cursor()
    if aParm:
        l_cur.execute(aSql, aParm)
    else:
        l_cur.execute(aSql)
    l_keys = [i for i in l_cur.description ]
    l_sum = []
    l_count = 0
    for i in l_cur.fetchall():
        l_dictSub = {}
        for j in range(len(i)):
            l_dictSub.update( {l_keys[j].name: correctjsonfield(i[j], l_keys[j].type_code) })
        l_sum.append( l_dictSub )
        l_count += 1

    ls_sqlcount =  aSql[aSql.find('from'): (aSql.find('limit') if aSql.find('limit') > 0 else None)]
    ls_sqlcount = ls_sqlcount[: (aSql.find('order') if aSql.find('order') > 0 else None)]

    ls_sqlcount = "select count(*) " + ls_sqlcount


    l_cur.execute(ls_sqlcount)
    l_sqlcount = l_cur.fetchone()[0]

    l_rtn = {}
    l_rtn.update( {"msg": "", "stateCod":"", "total":l_sqlcount, "rows": l_sum } )
    # l_rtn =  '{"total":' + str(l_count) + ', "rows":' + str( l_sum) + '}'
    return l_rtn





