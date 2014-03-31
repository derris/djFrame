__author__ = 'dh'

import json
from datetime import date,datetime
from django.db import connection, transaction
import re
from zdCommon.utils import logErr, log

tbDefCache = {}  # table的定义缓存。
def getColType(atable, aCol):
    global tbDefCache
    ls_tab = atable.lower()
    ls_col = aCol.lower()
    if ls_tab not in tbDefCache.keys():
        tbDefCache.update(  { ls_tab : getTableInfo(ls_tab)}  )
    if not ls_col in tbDefCache[ls_tab].keys():
        raise Exception(atable + "中不存在字段" + aCol)
    return(tbDefCache[ls_tab][ls_col])

def correctjsonfield(obj, atypecode):
    if obj:
        if isinstance(obj, datetime):
            return obj.strftime('%Y-%m-%d %H:%M:%S')
        elif isinstance(obj,date):
            return obj.strftime('%Y-%m-%d')
        elif isinstance(obj,bool):
            return "true"
        else:                 #
            return str(obj)
    else:
        if atypecode == 1043:    # varchar
            return ""
        elif atypecode == 1082:  # date
            return ""
        elif atypecode == 1083:  # time
            return ""
        elif atypecode == 16:    # bool
            return ""
        elif atypecode == 18:  # char            :
            return ""
        elif atypecode == 1114:  # datetime/ timestamp
            return ""
        elif atypecode in( 20, 21, 23, 700, 701, 1700):  # int2,4 8, float4,8, numberic
            return ""
        elif atypecode == 0:
            return ""
        else:
            logErr("无法识别的数据库对象类型代码d%，请查询：SELECT typname, oid FROM pg_type;" % atypecode)
            raise Exception("无法识别的数据库对象类型，请通知管理员。")
    return ""


def strip(aStr):
    return aStr.strip(" ") if aStr else ""

def rawsql4request(aSql, aRequestDict):
    ldict_req = aRequestDict
    l_page = int(ldict_req.get('page', 1))
    l_rows = int(ldict_req.get('rows', 10))
    #l_sort = str(ldict_req.get('sort', '')).replace("'", '\"')        # json必须是双引号。否则loads错误。
    #l_filter = str(ldict_req.get('filter', '')).replace("'", '\"')
    l_sort = ldict_req.get('sort', {})
    l_filter = ldict_req.get('filter', {})
    #============================= filter 处理得到 where条件。============
    ls_wheresum = ''
    if len(str(l_filter)) > 10:
        # { 'cod':'client_name','operatorTyp':'等于','value1':'值1','value2':'值2'  }
        #for i in json.loads(l_filter):
        for i in l_filter:
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
                logErr("无法识别的操作符号%s" % l_dictwhere['operatorTyp'])
                raise Exception("无法识别的操作符号，请通知管理员")

            ls_value =  str(l_dictwhere['value'])
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
    #--------------得到前台通用查询的where语句。-filter 2 where  ->    ls_wheresum通用的。 ------------------------------

    # =============================================sort 2 order ===========
    ls_ordersum = ''
    if len(str(l_sort))> 3:
    #  'sort':'[{ 'cod':'client_name', 'order_typ':'升序' }]'
        #for i in json.loads(l_sort):
        for i in l_sort:
            l_dictsort = i
            ltmp_sort = ''
            if l_dictsort['order_typ'] == '升序':
                ltmp_sort = ' asc '
            elif l_dictsort['order_typ'] == '降序':
                ltmp_sort = ' desc '
            else:
                logErr("无法识别排序符号：%s" % l_dictsort['order_typ'])
                raise Exception("无法识别的排序符号，请通知管理员")
            ls_ordersum += l_dictsort['cod'] + ltmp_sort + ' ,'
        ls_ordersum = ls_ordersum[:-1]
    #-----------------------------得到前台通用查询的sort 语句-sort -> order -> ls_ordersum ------------------------------

    # 处理原来的sql语句，准备加上新的条件。
    ls_sql = aSql if aSql.find(';') > 0 else aSql + ";"  # 保证分号结束。 where group order limit
    ls_rewhere = r'(\bwhere\b.*?)(\border\b|\bgroup\b|\blimit\b|;)'
    ls_regroup = r'(\bgroup\b.*?)(\border\b|\blimit\b|;)'
    ls_reorder = r'(\border\b.*?)(\bgroup\b|\blimit\b|;)'
    ls_reselect = r'(.*?)(\bwhere\b|\blimit\b|\border\b|\bgroup\b|;)'

    l_tmp = re.search(ls_reselect, ls_sql, re.IGNORECASE)   # 得到select主题语句
    if l_tmp:
        ls_select = l_tmp.group(1)
    else:
        ls_select = ''
        logErr("得不到sql主体语句：%s" % ls_sql)
        raise Exception("得不到sql主体语句，请与管理员联系")

    l_tmp = re.search(ls_rewhere, ls_sql, re.IGNORECASE)
    ls_where = l_tmp.group(1) if l_tmp else None   # 后台的sql语句。where条件。

    l_tmp =  re.search(ls_regroup, ls_sql, re.IGNORECASE)
    ls_group = l_tmp.group(1) if l_tmp else None

    l_tmp = re.search(ls_reorder, ls_sql, re.IGNORECASE)
    ls_order = l_tmp.group(1) if l_tmp else None

    ls_finwhere = ''

    if len(strip(ls_where)) > 3:
        ls_finwhere = ls_where
        if len(strip(ls_wheresum)) > 3:
            ls_finwhere += ' and ' + ls_wheresum
    elif len(strip(ls_wheresum)) > 3:
        ls_finwhere += ' where ' + ls_wheresum

    ls_finorder = ''
    if len(strip(ls_order)) > 3:
        ls_finorder = ls_order
        if len(strip(ls_ordersum)) > 4:
            ls_finorder = ls_order + ' , ' + ls_ordersum
    elif len(strip(ls_ordersum)) > 3:
        ls_finorder = ' order by  ' + ls_ordersum

    ls_finSql = ls_select
    ls_tablename = re.search(r'\bfrom\b\s*(\w*)', ls_sql).group(1)
    ls_sqlcount = "select count(*) from " + ls_tablename

    if ls_finwhere:
        ls_finSql += ls_finwhere
        ls_sqlcount += ' ' + ls_finwhere
    if ls_group:
        ls_finSql += ls_group
        ls_sqlcount += ls_group
    if ls_finorder:
        ls_finSql += ls_finorder

    if l_rows > 0:
        ls_finSql += (" limit %d offset %d " % (l_rows, (l_page-1)*l_rows ))
    log( ls_finSql + " - page - " +  ls_sqlcount )
    return( (ls_finSql, ls_sqlcount) )

def rawsql2json(aSql, aSqlCount):
    '''
        根据sql语句，返回数据和记录总数。.
    '''
    l_cur = connection.cursor()
    l_rtn = {"msg": "查询完毕", "error":[] }
    try:
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
    except Exception as e:
        logErr("查询失败：%s" % str(e.args))
        raise e
    finally:
        l_cur.close()
    l_rtn.update( { "stateCod": 1 if l_sqlcount > 0 else 201  , "total":l_sqlcount, "rows": l_sum } )
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
        if atypecode in (1042,1043):    # varchar
            ls = "char"
        elif atypecode == 1082:  # date
            ls = 'date'
        elif atypecode == 1083:  # time
            ls = 'time'
        elif atypecode == 16:    # bool
            ls = 'bool'
        elif atypecode in (18,25,):  # char            :
            ls = 'char'
        elif atypecode == 1114:  # datetime/ timestamp
            ls = 'datetime'
        elif atypecode in( 20, 21, 23, 700, 701,790,1700):  # int2,4 8, float4,8, numberic
            ls = 'number'
        elif atypecode == 0:
            ls = "nouse"
        else:
            logErr("遇到不认识的数据库类型代码%d -> 字段 %s " % (atypecode, ))
            raise Exception("遇到不认识的类型代码d%，请查询：SELECT typname, oid FROM pg_type;" % atypecode)
        l_dict.update({ i[0] : ls  })
    return l_dict

def json2exec(ajson, aCursor, artn, a2Replace):   # artn['effectnum'] + 1
    l_oldUUID = ""
    if a2Replace:
        l_UUID = a2Replace[0]
        l_NewId = a2Replace[1]
    try:
        for i_row in  ajson['rows']:
            #循环进行处理字符串，然后更新
            ls_sql = ""
            lb_updateValid = False
            if i_row['op'] == 'insert':
                ls_sql = "insert into %s" % i_row['table']
                ls_col = ls_val = ''
                for icol,ival in i_row['cols'].items():
                    if icol == "id":
                        pass # id字段不生成insert语句。
                    else:
                        ls_col += str(icol) + ','
                        if icol == "rec_tim":
                            ls_val += "'" + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "',"
                        else:
                            if (str(ival) != ""):
                                ls_val += "'" + str(ival) + "',"
                            else:
                                if getColType(i_row['table'], icol) == "char": # 是字符类型的字段。空不赋值为null，其余的，如果是空全部赋值为null。
                                    ls_val += "'" + str(ival) + "',"
                                else:
                                    ls_val += "null,"

                ls_col = ls_col[:-1]
                ls_val = ls_val[:-1]
                if 'rec_nam' in ls_col:
                    pass
                else:
                    ls_col += " , rec_nam "
                    ls_val += ", '1'"
                if 'rec_tim' in ls_col:
                    pass
                else:
                    ls_col += " , rec_tim "
                    ls_val += ", '" + datetime.now().strftime('%Y-%m-%d %H:%M:%S') +  "'"
                ls_sql += "(" + ls_col + ")" + " values (" + ls_val + ") returning id"
            #######################################################################
            elif i_row['op'] == 'update':
                ls_sql = "update %s set " % i_row['table']
                ls_set = ''
                ls_where = ' id = ' + str(i_row['id']) + ' and '
                for icol,ival in i_row['cols'].items():
                    lb_updateValid = True
                    if  str(ival[0]) == "":
                        if getColType(i_row['table'], icol) in ("number", "date", "time", "datetime", "bool"): # 是字符类型的字段。空不赋值为null，其余的，如果是空全部赋值为null。
                            ls_set += str(icol) + "= null,"
                        else:
                            ls_set += str(icol) + "= '" + str(ival[0]) +  "',"
                    else:
                        ls_set += str(icol) + "= '" + str(ival[0]) +  "',"

                    if str(ival[1]) == "":
                        if getColType(i_row['table'], icol) in ("number", "date", "time", "datetime", "bool"): # 是字符类型的字段。空不赋值为null，其余的，如果是空全部赋值为null。
                            ls_where += str(icol) + " is null and "
                        else:
                            ls_where += str(icol) + " = '" + str(ival[1]) + "' and "
                    else:
                        ls_where += str(icol) + " = '" + str(ival[1]) + "' and "
                ls_set = ls_set[:-1]
                ls_where = ls_where[:-5]
                if 'upd_nam' in ls_set:
                    pass
                else:
                    ls_set += " , upd_nam = 1 "
                if 'upd_tim' in ls_set:
                    pass
                else:
                    ls_set += " , upd_tim = current_timestamp(0) "
                ls_sql += ls_set + ' where ' + ls_where
            #######################################################################
            elif i_row['op'] == 'updatedirty':
                ls_sql = "update %s set " % i_row['table']
                ls_set = ''
                ls_where = ' id = ' + str(i_row['id'])
                for icol,ival in i_row['cols'].items():
                    lb_updateValid = True
                    if  str(ival[0]) == "":
                        if getColType(i_row['table'], icol) in ("number", "date", "time", "datetime", "bool"): # 是字符类型的字段。空不赋值为null，其余的，如果是空全部赋值为null。
                            ls_set += str(icol) + "= null,"
                        else:
                            ls_set += str(icol) + "= '" + str(ival[0]) +  "',"
                    else:
                        ls_set += str(icol) + "= '" + str(ival[0]) +  "',"
                ls_set = ls_set[:-1]
                if 'upd_nam' in ls_set:
                    pass
                else:
                    ls_set += " , upd_nam = 1 "
                if 'upd_tim' in ls_set:
                    pass
                else:
                    ls_set += " , upd_tim = current_timestamp(0) "
                ls_sql += ls_set + ' where ' + ls_where
            #######################################################################
            elif i_row['op'] == 'delete':
                lb_updateValid = True
                ls_sql = "delete from " + i_row['table'] + " where id = " + str(i_row['id'])
            ######################  处理完毕  sql  语句。  如果有替换需求，就需要全部处理。
            log(ls_sql)
            if len(l_UUID) > 10:
                ls_sql = ls_sql.replace(l_UUID, str(l_NewId))
                log(' 根据带入的UUID替换：' + ls_sql)
            if 'uuid' in i_row.keys() :
                l_oldUUID =  i_row['uuid']
            l_newInsertId = ""
            if i_row['op'] == 'insert':
                aCursor.execute(ls_sql)
                li_t = aCursor.cursor.rowcount
                l_newInsertId = aCursor.fetchone()[0]        # 返回的新的id，子记录需要把所有的都替换成。
                artn['changeid'].update({i_row["uuid"] : l_newInsertId})
                artn.update({ 'effectnum' : artn['effectnum'] + li_t  })
            elif i_row['op'] in ('delete', 'update', 'updatedirty'):
                if lb_updateValid:
                    aCursor.execute(ls_sql)
                    li_t = aCursor.cursor.rowcount
                    artn.update({ 'effectnum' : artn['effectnum'] + li_t  })
            if 'rows' in i_row['subs'].keys():
                json2exec(i_row['subs'], aCursor, artn, (l_oldUUID, l_newInsertId))
    except Exception as e:
        logErr("错误：%s" % str(e.args))
        raise e


def json2upd(aJsonDict):
    l_rtn = {"error": [""],
             "msg":"",
             "stateCod":  0 ,
             "effectnum": 0 ,
             "changeid" : {'uuid1':'id1'} }
    try:
        l_cur = connection.cursor()
        json2exec(aJsonDict, l_cur, l_rtn, ("",""))
        l_rtn.update({"stateCod": 202})
    except Exception as e:
        logErr("数据库执行错误：%s" % str(e.args))
        l_rtn.update({"stateCod": -100, "error": str(l_rtn['error']), "msg":"执行失败" })
        raise e
    finally:
        l_cur.close()
    return(l_rtn)

def cursorExec(aSql):
    '''
        execute sql use cursor, return effect rows.
    '''
    l_rtn = -1
    log(aSql)
    try:
        l_cur = connection.cursor()
        l_cur.execute(aSql)
        l_rtn = l_cur.cursor.rowcount
    except Exception as e:
        logErr("数据库执行错误：%s" % str(e.args))
        raise e
    finally:
        l_cur.close
    return l_rtn

def cursorExec2(aSql, aList ):
    l_rtn = -1
    log(aSql + str(aList))
    try:
        l_cur = connection.cursor()
        l_cur.execute(aSql, aList)
        l_rtn = l_cur.cursor.rowcount
    except Exception as e:
        logErr("数据库执行错误：%s" % str(e.args))
        raise e
    finally:
        l_cur.close
    return l_rtn

def cursorSelect(aSql):
    '''
        execute sql use cursor, return all. fetchall()
        l_rtn[0][0]  单值。
    '''
    log(aSql)
    l_rtn = -1
    try:
        l_cur = connection.cursor()
        l_cur.execute(aSql)
        l_rtn = l_cur.fetchall()
    except Exception as e:
        logErr("数据库执行错误：%s" % str(e.args))
        raise e
    finally:
        l_cur.close
    return l_rtn

def fetchSeq(aSeqName):
    '''
        execute sql: select nextval(seqname)
        return seq_no
    '''
    ls_sql = "select nextval('" + aSeqName  + "')"
    l_seq = cursorSelect(ls_sql)
    if len(l_seq) > 0 :
        return str(l_seq[0][0])
    else:
        return -1