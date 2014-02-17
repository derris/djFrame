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
            return "1800-01-01"
        elif atypecode == 1083:  # time
            return "00:00:00"
        elif atypecode == 16:    # bool
            return "false"
        elif atypecode == 18:  # char            :
            return ""
        elif atypecode == 1114:  # datetime/ timestamp
            return "1800-01-01 00:00:00"
        elif atypecode in( 20, 21, 23, 700, 701, 1700):  # int2,4 8, float4,8, numberic
            return 0
        else:
            raise Exception("遇到不认识的类型代码d%，请查询：SELECT typname, oid FROM pg_type;" % atypecode)
            return 0


def rawsql4request(aSql, aRequestDict):
    '''
        根据aRequest来的参数，生成aSql语句。
        select * from t where a = b and c = d group by c2 order by c1 desc limit 10 offset 1;
        select count(*) from t where a = b and c = d group by c2

        if request.method == 'GET':
            ldict_req =   dict(request.Get)
        else:
            ldict_req =   dict(request.POST)

        l_testPost =   {
                'page':2,
                'rows':12,
                'filter':"[{ 'cod':'client_name', 'operatorTyp':'等于', 'value':'值' }]",
                'sort':"[{ 'cod':'client_name', 'order_typ':'升序' }]"
            }
    '''
    ldict_req = {}
    ldict_req = aRequestDict
    l_page = int(ldict_req.get('page', 1))
    l_rows = int(ldict_req.get('rows', 10))
    l_sort = str(ldict_req.get('sort', '')).replace("'", '\"')
    l_filter = str(ldict_req.get('filter', '')).replace("'", '\"')

    #============================= filter 处理得到 where条件。============
    ls_wheresum = ''
    if len(l_filter) > 3:
        # { 'cod':'client_name','operatorTyp':'等于','value1':'值1','value2':'值2'  }
        for i in json.loads(l_filter):
            l_dictwhere = i
            ls_oper = ''
            if l_dictwhere['operatorTyp'] == '等于':
                ls_oper = '='
            elif  l_dictwhere['operatorTyp'] == '大于':
                ls_oper = '>'
            elif l_dictwhere['operatorTyp'] == '小于':
                ls_oper = '<'
            elif l_dictwhere['operatorTyp'] == '大于等于':
                ls_oper = '>='
            elif l_dictwhere['operatorTyp'] == '小于等于':
                ls_oper = '<='
            elif l_dictwhere['operatorTyp'] == '不等于':
                ls_oper = '<>'
            elif l_dictwhere['operatorTyp'] == '包含':
                ls_oper = ' like '
            elif l_dictwhere['operatorTyp'] == '不包含':
                ls_oper = ' not like '
            elif l_dictwhere['operatorTyp'] == '属于':
                ls_oper = ' in '
            elif l_dictwhere['operatorTyp'] == '不属于':
                ls_oper = ' not in '
            elif l_dictwhere['operatorTyp'] == '介于':
                ls_oper = ' between '
            elif l_dictwhere['operatorTyp'] == '不介于':
                ls_oper = ' not between '
            else:
                raise Exception("无法识别的操作符号，请通知管理员")

            ls_value =  l_dictwhere['value']
            ls_getwhere = ''
            if ls_oper == (' between ', ' not between '):
                ls_getwhere = l_dictwhere['cod'] + " between '" + ls_value.split(',')[0] + "' and '" + ls_value.split(',')[1] + "'"
            elif ls_oper in (' in ', ' not in '):
                ls_getwhere = l_dictwhere['cod'] + ls_oper + "('" + ls_value.replace(",", "','") + "')"
            elif ls_oper in (' not like ', ' like '):
                ls_getwhere = l_dictwhere['cod'] + ls_oper + "'%" + ls_value + "%'"
            else:
                ls_getwhere = l_dictwhere['cod'] + ls_oper + "'" + ls_value + "'"
            ls_wheresum = ls_wheresum + ' ' +  ls_getwhere + ' and'
        ls_wheresum = ls_wheresum[:-3]
    #------------------------------filter 2 where  ->  ls_wheresum ------------------------------

    # =============================================sort 2 order ===========
    ls_ordersum = ''
    if len(l_sort)> 3:
    #  'sort':'[{ 'cod':'client_name', 'order_typ':'升序' }]'
        for i in json.loads(l_sort):
            l_dictsort = i
            ltmp_sort = ''
            if l_dictsort['order_typ'] == '升序':
                ltmp_sort = ' asc '
            elif l_dictsort['order_typ'] == '降序':
                ltmp_sort = ' desc '
            else:
                raise Exception("无法识别的排序符号")
            ls_ordersum += l_dictsort['cod'] + ltmp_sort + ' ,'
        ls_ordersum = ls_ordersum[:-1]
    #------------------------------sort -> order -> ls_ordersum ------------------------------

    # 处理原来的sql语句，准备加上新的条件。
    ls_sql = aSql if aSql.find(';') > 0 else aSql + ";"  # 保证分号结束。 where group order limit
    ls_rewhere = r'(\bwhere\b.*?)(\border\b|\bgroup\b|\blimit\b|;)'
    ls_regroup = r'(\bgroup\b.*?)(\border\b|\blimit\b|;)'
    ls_reorder = r'(\border\b.*?)(\bgroup\b|\blimit\b|;)'
    ls_reselect = r'(.*?)(\bwhere\b|\blimit\b|\border\b|\bgroup\b|;)'

    l_tmp = re.search(ls_reselect, ls_sql, re.IGNORECASE)
    if l_tmp:
        ls_select = l_tmp.group(1)
    else:
        ls_select = ''
        raise Exception("得不到sql主体语句，请与管理员联系")

    l_tmp = re.search(ls_rewhere, ls_sql, re.IGNORECASE)
    ls_where = l_tmp.group(1) if l_tmp else None

    l_tmp =  re.search(ls_regroup, ls_sql, re.IGNORECASE)
    ls_group = l_tmp.group(1) if l_tmp else None

    l_tmp = re.search(ls_reorder, ls_sql, re.IGNORECASE)
    ls_order = l_tmp.group(1) if l_tmp else None

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

    if ls_finorder.find(' id ') > 0:
        pass
    elif ls_finorder.find( ' order ') > 0:
        ls_finorder = ls_finorder + ', id desc'  #默认排序id倒置
    else:
        ls_finorder = ' order by id desc '

    ls_finSql = ls_select
    ls_tablename = re.search(r'\bfrom\b\s*(\w*)', ls_sql).group(1)
    ls_sqlcount = "select count(*) from " + ls_tablename

    if ls_finwhere:
        ls_finSql += ls_finwhere
        ls_sqlcount += ls_finwhere
    if ls_group:
        ls_finSql += ls_group
        ls_sqlcount += ls_group
    if ls_finorder:
        ls_finSql += ls_finorder

    ls_finSql += (" limit %d offset %d " % (l_rows, (l_page-1)*l_rows ))

    return( (ls_finSql, ls_sqlcount) )

def rawsql2json(aSql, aSqlCount):
    '''
        根据sql语句，返回数据和记录总数。.
    '''
    l_cur = connection.cursor()
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
    l_cur.execute(aSqlCount)
    l_sqlcount = l_cur.fetchone()[0]
    l_cur.close()
    l_rtn = {}
    l_rtn.update( {"msg": "", "stateCod":"", "total":l_sqlcount, "rows": l_sum } )
    # l_rtn =  '{"total":' + str(l_count) + ', "rows":' + str( l_sum) + '}'
    return l_rtn

def getTableInfo(aTableName):
    '''
        根据表名，通过查询postgresql数据库系统表，得到信息。返回字典。dict['字段名'] 就可以得到字段类型:char, date, time, bool, datetime.
    '''
    ls_sql = ("select col.attname, col.atttypid, col_description(col.attrelid, col.attnum) from pg_class as tb, pg_attribute as col \
        where tb.relname = '%s' and col.attrelid = tb.oid and col.attnum > 0" % aTableName)
    l_cur = connection.cursor()
    l_cur.execute(ls_sql)
    l_desc = l_cur.fetchall()
    l_dict = {}
    for i in l_desc:
        atypecode = i[1]
        if atypecode == 1043:    # varchar
            ls = "char"
        elif atypecode == 1082:  # date
            ls = 'date'
        elif atypecode == 1083:  # time
            ls = 'time'
        elif atypecode == 16:    # bool
            ls = 'bool'
        elif atypecode == 18:  # char            :
            ls = 'char'
        elif atypecode == 1114:  # datetime/ timestamp
            ls = 'datetime'
        elif atypecode in( 20, 21, 23, 700, 701, 1700):  # int2,4 8, float4,8, numberic
            ls = 'int'
        else:
            raise Exception("遇到不认识的类型代码d%，请查询：SELECT typname, oid FROM pg_type;" % atypecode)
        l_dict.update({ i[0] : ls  })
    return l_dict

def json2insert(aJsonDict):
    ldict = eval(aJsonDict['jargs'])
    l_rows = ldict['rows']
    ldict_uuid2id = {}
    for i_row in l_rows:  # insert into table(a,b,c,d,e)  values('a','b','c','d','e')
        ls_sql = "insert into %s" % i_row['table']
        ls_col = ls_val = ''
        for icol,ival in i_row['cols'].items():
            ls_col += icol + ','
            ls_val += "'" + ival + "',"
        ls_col = ls_col[:-1]
        ls_val = ls_val[:-1]
        if 'rec_nam' in ls_col:
            pass
        else:
            ls_col += " , rec_nam "
            ls_val += ", 1"

        if 'rec_tim' in ls_col:
            pass
        else:
            ls_col += " , rec_tim "
            ls_val += ", '" + datetime.now().strftime('%Y-%m-%d %H:%M:%S') +  "'"

        ls_sql += "(" + ls_col + ")" + " values (" + ls_val + ") returning id"
        print(ls_sql)

        l_cur = connection.cursor()
        l_cur.execute(ls_sql)
        l_insId = l_cur.fetchone()[0]
        l_cur.close()
        ldict_uuid2id.update({i_row["uuid"] : l_insId})
    l_rtn = {}
    l_rtn.update( {"error": "", "stateCod":"0",
                       "effectnum":1 , "rows": "1",
                       "changeid": str(ldict_uuid2id) } )
    return l_rtn

