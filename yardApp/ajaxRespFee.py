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
    ls_sql1 = '''select s.client_id, s.fee_typ, s.ex_over,s.audit_tim,s.amount - sum(COALESCE(a.amount,0)) amount
                  from act_fee a right join
                ( select client_id, fee_typ, ex_over,audit_tim,sum(amount) amount from act_fee
            '''
    ls_sql2 = " where audit_id = true and " + ls_clientsql + ls_feesql + ls_timesql
    ls_sql3 = ''' group by client_id, fee_typ, ex_over,audit_tim) s
            on a.ex_from = s.ex_over
            group by s.client_id, s.fee_typ, s.ex_over,s.audit_tim,s.amount
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

        #list_pre = rawSql2JsonDict("select * from pre_fee where ex_over = '%s'" % ls_exOver)
        #list_pre.extend(rawSql2JsonDict("select * from pre_fee where ex_from = '%s'" % ls_exOver))
        #list_act = rawSql2JsonDict("select * from act_fee where ex_over = '%s'" % ls_exOver)
        #list_act.extend(rawSql2JsonDict("select * from act_fee where ex_from = '%s'" % ls_exOver))

        ls_pre = '''
            select a.contract_id,a.fee_cod,a.amount - sum(COALESCE(p.amount,0))
            from pre_fee p right join
            (select ex_over,contract_id,fee_cod,sum(amount) amount
            from pre_fee
            where ex_over = %s
            group by ex_over,contract_id,fee_cod) a
            on p.ex_from = a.ex_over and p.contract_id = a.contract_id and p.fee_cod = a.fee_cod
            group by a.contract_id,a.fee_cod,a.amount
        '''
        ls_act = '''
            select a.contract_id,a.fee_cod,a.amount - sum(COALESCE(p.amount,0))
            from act_fee p right join
            (select ex_over,contract_id,fee_cod,sum(amount) amount
            from act_fee
            where ex_over = %s
            group by ex_over,contract_id,fee_cod) a
            on p.ex_from = a.ex_over and p.contract_id = a.contract_id and p.fee_cod = a.fee_cod
            group by a.contract_id,a.fee_cod,a.amount
        '''

        list_pre = rawSql2JsonDict(ls_pre % ls_exOver)
        list_act = rawSql2JsonDict(ls_act % ls_exOver)

        l_result = { "act":list_act, "pre":list_pre }
        l_rtn.update( {"msg": "查询成功", "error":[], "stateCod" : 1, "result": l_result } )
    except Exception as e:
        l_rtn.update( {"msg": "查询失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn

def contrProFeeGen(aRequest, aDict):
    l_rtn = { }
    ls_contractid = str(aDict["ex_parm"]["contract_id"])

    ls_fee = "select * from c_fee where protocol_flag = true" # get the protocel fee.
    l_fee = cursorSelect(ls_fee)
    for i in l_fee:
        if i["fee_nam"] == "包干费":   # 生成前判断是否已有此费用，有此费用忽略。
            #从contract 取出client,contract_type. 从contract_action中取cntr_type、cntr_num，
            ls_contrsql = "select * from contract where contract_id = %s" % (ls_contractid)
            ls_action = "select * from contract_action where contract_id = %s" % (ls_contractid)
            # 循环读出箱子
            l_cntr = cursorSelect(ls_action)
            for j in l_cntr:
                 # 根据c_fee_protocol的费率产生费用。
                ls_1 = "select count(*) from pre_fee where contract_id = %s and fee_cod = %d" % (ls_contractid, i["id"])
                if int(cursorSelect(ls_1)[0][0]) < 1 :
                    # 根据c_fee_protocol的费率产生费用。 根据箱型得到费用费用。
                    pass
                else:
                    pass
    ls_t = "select * from c_client where id > 0 "  #查询有未结费用的客户。
    '''
    b.代收代付费用：对此contract_id下的所有应付费用，c_fee.pair_flag = true的，判断是否有对应的应收费用，如没有，
          插入一条金额相同的应收费用。

              '''