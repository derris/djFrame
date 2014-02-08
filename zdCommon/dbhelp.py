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

    #============================= 处理得到的where条件。============
    ls_wheresum = ''
    if len(l_filter) > 3:
        # { 'cod':'client_name','operatorTyp':'等于','value1':'值1','value2':'值2'  }
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
            elif ls_oper == 'not in':
                ls_getwhere = l_dictwhere['cod'] + ' not in (' + ls_value + ')'
            else:
                ls_getwhere = l_dictwhere['cod'] + l_dictwhere['operatorTyp'] + l_dictwhere['value1']
            ls_wheresum = ls_wheresum + ' ' +  ls_getwhere + ' and'
        ls_wheresum = ls_wheresum[:-3]
    #------------------------------ get where ------------------------------

    # ============================================= order here ===========
    ls_ordersum = ''
    if len(l_sort)> 3:
    #  'sort':'[{ 'cod':'client_name', 'order_typ':'升序' }]'
        for i in json.loads(l_filter):
            l_dictsort = i
            ltmp_sort = ''
            if l_dictsort['order_typ'] == '升序':
                ltmp_sort = ' asc '
            elif l_dictsort['order_typ'] == '降序':
                ltmp_sort = ' desc '
            else:
                raise Exception("无法识别的排序符号")
            ls_ordersum = ls_ordersum + ' ' + ltmp_sort + ' ,'
        ls_ordersum = ls_ordersum[:-1]
    #------------------------------ get order ------------------------------


    ls_sql = aSql if aSql.find(';') > 0 else aSql + ";"  # 保证分号结束。 where group order limit
    ls_rewhere = r'(\bwhere\b.*?)(\border\b|\bgroup\b|\blimit\b|;)'
    ls_regroup = r'(\bgroup\b.*?)(\border\b|\blimit\b|;)'
    ls_reorder = r'(\border\b.*?)(\bgroup\b|\blimit\b|;)'
    ls_reselect = r'(.*?)(\bwhere\b|\blimit\b|\border\b|\bgroup\b|;)'

    l_tmp = re.search(ls_reselect, ls_sql, re.IGNORECASE)
    if l_tmp:
        ls_select = l_tmp.group(1)

    l_tmp = re.search(ls_rewhere, ls_sql, re.IGNORECASE)
    if l_tmp:
        ls_where =  l_tmp.group(1)

    l_tmp =  re.search(ls_regroup, ls_sql, re.IGNORECASE)
    if l_tmp:
        ls_group =  l_tmp.group(1)

    l_tmp = re.search(ls_reorder, ls_sql, re.IGNORECASE)
    if l_tmp:
        ls_orders = l_tmp.group(1)

    '''
    ls_countsql = l_tmp
    ls_sqlcount = "select count(*) " + ls_sqlcount
    '''

    ls_finwhere = ''
    if ls_where:
        ls_finwhere = ls_where + ' and ' + ls_wheresum
    elif len(ls_wheresum.strip(' ')) > 4:
        ls_finwhere = ' where ' + ls_wheresum

    ls_finorder = ''
    if ls_order:
        ls_finorder = ls_order + ' , ' + ls_ordersum
    elif len(ls_ordersum.strip(' ')) > 4:
        ls_finorder = ' order by  ' + ls_ordersum

    if ls_finorder.find(' id ') > 0 :
        pass
    elif ls_finorder.find( ' order ') > 0 :
        ls_finorder = ls_finorder + ', id desc'  #默认排序id倒置
    else:
        ls_finorder = ' order by id desc '

    ls_finSql = ls_select
    if ls_finwhere:
        ls_finSql += ls_finwhere
    if ls_finorder:
        ls_finSql += ls_finorder
    if ls_group:
        ls_finSql += ls_group


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





