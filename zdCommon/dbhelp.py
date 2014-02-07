__author__ = 'dh'

import json
from datetime import date,datetime
from django.db import connection
import re

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


def rawsql4request(aSql, aRequest):
    '''
        根据aRequest来的参数，生成aSql语句。
        select * from t where a = b and c = d order by c1 desc group by c2 limit 10 offset 1;
    '''
    ldict_req = {}
    if aRequest.method == 'GET':
        ldict_req =   dict(aRequest.Get)
    else:
        ldict_req =   dict(aRequest.POST)

    l_page = int(ldict_req.get('page', 1))
    l_rows = int(ldict_req.get('rows', 10))
    l_sort = str(ldict_req.get('sort', ''))
    l_filter = str(ldict_req.get('filter', ''))

    #============================= 处理得到的where条件。
    if len(l_filter) > 3:

        # { 'cod':'client_name','operatorTyp':'等于','value1':'值1','value2':'值2'  }
        ls_opersum = ''
        for i in json.loads(l_filter):
            l_dictwhere = i
            ls_oper = ''
            if l_dictwhere['operatorTyp'] == '等于':
                ls_oper = '='
            elif  l_dictwhere['operatorTyp'] == '大于':
                ls_oper = '='
            elif l_dictwhere['operatorTyp'] == '小于':
                ls_oper = '='
            elif l_dictwhere['operatorTyp'] == '大于等于':
                ls_oper = '='
            elif l_dictwhere['operatorTyp'] == '小于等于':
                ls_oper = '='
            elif l_dictwhere['operatorTyp'] == 'in':
                ls_oper = 'in'
            elif l_dictwhere['operatorTyp'] == 'between':
                ls_oper = 'between'
            else:
                raise Exception("无法识别的操作符号，请通知管理员")

            ls_value =  l_dictwhere['value1']
            ls_getwhere = ''
            if ls_oper == 'between':
                ls_getwhere = l_dictwhere['cod'] + ' between ' + ls_value.split(',')[0] + ' and ' + ls_value.split(',')[1]
            elif ls_oper == 'in':
                ls_getwhere = l_dictwhere['cod'] + ' in (' + ls_value + ')'
            else:
                ls_getwhere = l_dictwhere['cod'] + l_dictwhere['operatorTyp'] + l_dictwhere['value1']
            ls_opersum = ls_opersum + ls_getwhere
        # ls_opersum
        #------------------------------ get where ------------------------------

     #  'sort':'[{ 'cod':'client_name', 'order_typ':'升序' }]'
    if len(l_sort)> 3:
        l_dictsort = json.loads(l_sort)
    else:
        ls_sort = ' order by id desc '

    '''
    ls_sql = aSql if aSql.find(';') > 0 else aSql + ";"  # 保证分号结束。
    ls_rewhere = r'(\bwhere\b.*?)(\border\b|\bgroup\b|\blimit\b|;)'
    ls_reorder = r'(\border\b.*?)(\bgroup\b|\blimit\b|;)'
    ls_regroup = r'(\bgroup\b.*?)(\border\b|\blimit\b|;)'
    ls_relimit = r'(\blimit\b.*?);'
    ls_reselect = r'(.*?)(\bwhere\b|\blimit\b|\border\b|\bgroup\b|;)'
    ls_select = re.search(ls_reselect, ls_sql, re.IGNORECASE)
    ls_where =  re.search(ls_rewhere, ls_sql, re.IGNORECASE)
    ls_order =  re.search(ls_reorder, ls_sql, re.IGNORECASE)
    ls_group =  re.search(ls_regroup, ls_sql, re.IGNORECASE)
    ls_limit =  re.search(ls_relimit, ls_sql, re.IGNORECASE)
'''



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





