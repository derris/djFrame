__author__ = 'blaczom@163.com'

import json
from django.db import transaction
from zdCommon.dbhelp import rawSql2JsonDict
from zdCommon.utils import log, logErr
from zdCommon.dbhelp import cursorSelect, cursorExec, cursorExec2
from datetime import datetime

def dealAuditFee(request):
    '''
     "func" : "处理已收费用核销",
     "ex_parm": {"actfeeid": l_actId , "prefeeid":l_preId}
    '''
    ldict = json.loads( request.POST['jpargs'] )
    list_actId = ldict['ex_parm']["actfeeid"]
    list_preId = ldict['ex_parm']["prefeeid"]
    #  前台bug排除，就没用了。
    if (len(set(list_actId)) != len(list_actId)):
        raise Exception("已收费用id重复")
    if (len(set(list_preId)) != len(list_preId)):
        raise Exception("应收费用id重复")
    # 得到一个处理的seq{"seqnam":aSeqNam }
    ls_sql = "select nextval('seq_4_auditfee')"
    l_seq = cursorSelect(ls_sql)
    ls_seq = ""
    if len(l_seq) > 0 :
        ls_seq = str(l_seq[0][0])
    else:
        raise Exception("取序列号失败")
    #
    l_sumact = 0.0    # 实收费用
    l_sumpre = 0.0
    list_actId.reverse()
    list_preId.reverse()
    l_actId = 0
    l_preId = 0
    ls_now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    l_recnam = request.session['userid']
    while True:
        if l_sumact <= l_sumpre:
            if len(list_actId) > 0 :  # 还有 实收 费用。
                l_actId = list_actId.pop()
                l_sumact += float( cursorSelect("select amount from act_fee where id =  " + str(l_actId))[0][0] )
                ls_exec = "update act_fee set ex_over = %s, audit_id=true, audit_tim='%s' where id = %s" % ( ls_seq, ls_now, str(l_actId))
                if cursorExec(ls_exec) < 0 :
                    raise Exception("数据库执行失败")
            else  :# 没有实际费用了，prefee要多，所以插入剩下的prefee
                l_actRecord = cursorSelect("select client_id, fee_typ, fee_cod, contract_id from pre_fee where id = " + str(l_preId ) )
                l_clientid = l_actRecord[0][0]
                l_feetyp = l_actRecord[0][1]
                l_feecod = l_actRecord[0][2]
                l_contractid = l_actRecord[0][3]
                ls_ins = "insert into pre_fee(client_id, contract_id, fee_typ, fee_cod, amount,  fee_tim, rec_nam, rec_tim, ex_from, ex_feeid, remark  )"
                ls_ins += "values(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
                la_list = list((l_clientid, l_contractid, l_feetyp, l_feecod, l_sumpre - l_sumact, ls_now, l_recnam, ls_now,  ls_seq, 'E','核销自动生成'))
                cursorExec2(ls_ins, la_list)
                break # 退出。没有实际费用
        else:
            if len(list_preId) > 0 :  # 还有 应收 费用。
                l_preId = list_preId.pop()
                l_sumpre += float(cursorSelect("select amount from pre_fee where id =  " + str(l_preId))[0][0] )
                ls_exec = "update pre_fee set ex_over = %s, audit_id=true, audit_tim='%s' where id = %s" % (ls_seq, ls_now, str(l_preId))
                if cursorExec(ls_exec) < 0 :
                    raise Exception("数据库执行失败")
            else:
                l_actRecord = cursorSelect("select client_id, fee_typ, pay_type from act_fee where id = " + str( l_actId ) )
                l_clientid = l_actRecord[0][0]
                l_feetyp = l_actRecord[0][1]
                l_paytype = l_actRecord[0][2]
                ls_ins = "insert into act_fee(client_id, fee_typ, amount, pay_type, fee_tim, rec_nam, rec_tim, ex_from, ex_feeid ,remark )"
                ls_ins += "values(%s, %s, %s, %s,  %s, %s, %s, %s, %s , %s)"
                la_list = list((l_clientid, l_feetyp, l_sumact-l_sumpre, l_paytype, ls_now, l_recnam, ls_now, ls_seq, 'E', '核销自动生成'))
                cursorExec2(ls_ins, la_list)
                break

    ldict_rtn = { "msg": "成功", "stateCod": "202" , "result":{} }
    return(ldict_rtn)

def auditDeleteQuery(request, ldict):
    l_rtn = {}
    l_clientid = str(ldict['ex_parm']['client_id'])
    l_feetyp = str(ldict['ex_parm']['fee_typ'])
    ls_sql = "select ex_over, audit_tim from act_fee where client_id=%s and fee_typ='%s' and audit_id=true order by id desc limit 1 " % (l_clientid, l_feetyp)
    l_actRecord = cursorSelect(ls_sql)
    if len(l_actRecord) > 0 :
        pass
    else:
        l_rtn.update( {"msg": "查询成功，但没有符合条件记录", "error": '',"stateCod":101,"result":{"act":[], "pre":[]} } )
        return l_rtn
    ls_auditTim = l_actRecord[0][1]
    ls_exOver = l_actRecord[0][0]
    ls_sqlpre1 = "select * from pre_fee where audit_id = true and audit_tim = '%s' and ex_over='%s' " % (ls_auditTim, ls_exOver)
    ls_sqlpre2 = "select * from pre_fee where audit_id = false and rec_tim = '%s' and ex_from='%s' " % (ls_auditTim, ls_exOver)
    ls_sqlact1 = "select * from act_fee where audit_id = true and audit_tim = '%s' and ex_over='%s' " % (ls_auditTim, ls_exOver)
    ls_sqlact2 = "select * from act_fee where audit_id = false and rec_tim = '%s' and ex_from='%s' " % (ls_auditTim, ls_exOver)
    try:
        list_pre = rawSql2JsonDict(ls_sqlpre1)
        list_pre.extend(rawSql2JsonDict(ls_sqlpre2))
        list_act = rawSql2JsonDict(ls_sqlact1)
        list_act.extend(rawSql2JsonDict(ls_sqlact2))
        l_result = { "act":list_act, "pre":list_pre }
        l_rtn.update( {"msg": "查询成功", "error":[], "stateCod" : 1, "result": l_result } )
    except Exception as e:
        l_rtn.update( {"msg": "查询失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn

def auditDelete(request, ldict):
    ls_exOver = str(ldict['ex_parm']['ex_over'])
    l_rtn = { }
    if len(ls_exOver) < 1 :
        l_rtn.update( {"msg": "核销删除失败", "error":"没有核销号。请选择已核销的单据" , "stateCod" : -1 } )
        return l_rtn
    ls_sqlPre = "select count(*) from pre_fee where ex_from ='%s' and ex_over<>'' " % ls_exOver
    ls_sqlAct = "select count(*) from act_fee where ex_from ='%s' and ex_over<>'' " % ls_exOver

    li_pre = int(cursorSelect(ls_sqlPre)[0][0])
    li_act = int(cursorSelect(ls_sqlAct)[0][0])
    if li_act + li_pre > 0 :
        l_rtn.update( {"msg": "核销删除失败", "error":"核销号不是最后一次。请选择最后一次进行核销" , "stateCod" : -1 } )
    else:  # 可以删除该核销，删除掉生成的记录，然后update回去原来的号码。
        try:
            l_sql = []
            with transaction.atomic():
                l_sql.append("delete from pre_fee where ex_from='%s'" % ls_exOver)
                l_sql.append("delete from act_fee where ex_from='%s'" % ls_exOver)
                l_sql.append("update act_fee set ex_over = '', audit_id=false, audit_tim=null where ex_over='%s'" % ls_exOver)
                l_sql.append("update pre_fee set ex_over = '', audit_id=false, audit_tim=null where ex_over='%s'" % ls_exOver)
                for i in l_sql:
                    cursorExec(i)
                l_rtn.update( {"msg": "删除成功", "error":[], "stateCod" : 101, "result": [] } )
        except Exception as e:
            l_rtn.update( {"msg": "删除失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn

def auditSumQuery(request, ldict):
    l_rtn = { }
    ls_clientid = str(ldict['ex_parm']['client_id'])
    ls_feetyp = str(ldict['ex_parm']['fee_typ'])
    ls_begin = str(ldict['ex_parm']['begin_audit_tim'])
    ls_end = str(ldict['ex_parm']['end_audit_tim'])
    # 处理参数
    ls_clientsql = " client_id > 0 " if len(ls_clientid) < 1 or int(ls_clientid) < 1 else (" client_id = " + ls_clientid)
    ls_feesql = " " if len(ls_feetyp) < 1 else (" and fee_typ = '%s' " % ls_feetyp)
    ls_timesql = ""
    if len(ls_begin) > 0 : ls_timesql += " and audit_tim > '%s' " % ls_begin
    if len(ls_end) > 0 : ls_timesql  += " and audit_tim < '%s' " % ls_end
    # 生成sql语句
    ls_sql1 = '''select s.ex_over,s.audit_tim,s.amount - sum(COALESCE(a.amount,0)) amount
                  from act_fee a right join
                ( select ex_over,audit_tim,sum(amount) amount from act_fee
            '''
    ls_sql2 = " where audit_id = true and " + ls_clientsql + ls_feesql + ls_timesql
    ls_sql3 = ''' group by ex_over,audit_tim) s
            on a.ex_from = s.ex_over
            group by s.ex_over,s.audit_tim,s.amount
        '''
    # 执行并返回。
    try:
        l_result = rawSql2JsonDict(ls_sql1 + ls_sql2 + ls_sql3)
        l_rtn.update( {"msg": "查询成功", "error":[], "stateCod" : 1, "rows": l_result } )
    except Exception as e:
        l_rtn.update( {"msg": "查询失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn

def auditDetailQuery(request,ldict):
    l_rtn = {}
    ls_exOver = str(ldict['ex_parm']['ex_over'])
    if len(ls_exOver) < 1:
        l_rtn.update( {"msg": "查询失败", "error": list( ("缺少核销参数",) ) , "stateCod" : -1 } )
        return l_rtn

    try:
        list_pre = rawSql2JsonDict("select * from pre_fee where ex_over = '%s'" % ls_exOver)
        list_pre.extend(rawSql2JsonDict("select * from pre_fee where ex_from = '%s'" % ls_exOver))
        list_act = rawSql2JsonDict("select * from act_fee where ex_over = '%s'" % ls_exOver)
        list_act.extend(rawSql2JsonDict("select * from act_fee where ex_from = '%s'" % ls_exOver))
        l_result = { "act":list_act, "pre":list_pre }
        l_rtn.update( {"msg": "查询成功", "error":[], "stateCod" : 1, "result": l_result } )
    except Exception as e:
        l_rtn.update( {"msg": "查询失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn
