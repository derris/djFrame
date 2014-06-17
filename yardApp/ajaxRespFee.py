__author__ = 'blaczom@163.com'

import json
from django.db import transaction
from zdCommon.dbhelp import rawSql2JsonDict
from zdCommon.utils import log, logErr
from zdCommon.dbhelp import cursorSelect, cursorExec, cursorExec2, json2upd
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

        list_pre = rawSql2JsonDict("select bill_no,fee_typ,fee_cod,amount from pre_fee,contract "
                                   "where contract.id = pre_fee.contract_id"
                                   "  and ex_over = '%s'" % ls_exOver)
        list_pre.extend(rawSql2JsonDict("select bill_no,fee_typ,fee_cod,(0-amount) amount from pre_fee,contract "
                                        " where contract.id = pre_fee.contract_id"
                                        "   and ex_from = '%s'" % ls_exOver))
        list_act = rawSql2JsonDict("select client_id,fee_typ,amount,pay_type,invoice_no,check_no  from act_fee where ex_over = '%s'" % ls_exOver)
        list_act.extend(rawSql2JsonDict("select client_id,fee_typ,(0-amount) amount,pay_type,invoice_no,check_no from act_fee where ex_from = '%s'" % ls_exOver))

        # ls_pre = '''
        #     select a.contract_id,a.fee_cod,a.amount - sum(COALESCE(p.amount,0))
        #     from pre_fee p right join
        #     (select ex_over,contract_id,fee_cod,sum(amount) amount
        #     from pre_fee
        #     where ex_over = %s
        #     group by ex_over,contract_id,fee_cod) a
        #     on p.ex_from = a.ex_over and p.contract_id = a.contract_id and p.fee_cod = a.fee_cod
        #     group by a.contract_id,a.fee_cod,a.amount
        # '''
        # ls_act = '''
        #     select a.contract_id,a.fee_cod,a.amount - sum(COALESCE(p.amount,0))
        #     from act_fee p right join
        #     (select ex_over,contract_id,fee_cod,sum(amount) amount
        #     from act_fee
        #     where ex_over = %s
        #     group by ex_over,contract_id,fee_cod) a
        #     on p.ex_from = a.ex_over and p.contract_id = a.contract_id and p.fee_cod = a.fee_cod
        #     group by a.contract_id,a.fee_cod,a.amount
        # '''
        #
        # list_pre = rawSql2JsonDict(ls_pre % ls_exOver)
        # list_act = rawSql2JsonDict(ls_act % ls_exOver)

        l_result = { "act":list_act, "pre":list_pre }
        l_rtn.update( {"msg": "查询成功", "error":[], "stateCod" : 1, "result": l_result } )
    except Exception as e:
        l_rtn.update( {"msg": "查询失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn

def contrProFeeGen(aRequest, aDict):
    l_rtn = { }
    ls_contractid = str(aDict["ex_parm"]["contract_id"])
    #ls_fee = "select fun4fee_genlumpsum(%s)" % ls_contractid   # get the protocel fee.
    ls_fee = "select f_create_protocol_fee(%s,%s)" % (ls_contractid,str(1))   # get the protocel fee.
    l_fee = cursorSelect(ls_fee)
    #if l_fee[0][0] < 0 :
    if l_fee[0][0] != 'SUC' :
        #l_rtn.update( {"msg": "失败", "error":[str(l_fee[0][1])], "stateCod" : -1 } )
        l_rtn.update( {"msg": "失败", "error":[str(l_fee[0][0])], "stateCod" : -1 } )
    else:
        #l_rtn.update( {"msg": "查询成功", "error":[], "stateCod" : 101 } )
        l_rtn.update( {"msg": '生成成功', "error":[], "stateCod" : 202 } )
    return l_rtn

def update_oughtfee(request, adict):
    '''  应收费用  lock_flag=true or audit_id=true or ex_feeid='E' 不能更改   '''
    l_rtn = { }
    list_PreId = []
    for i_row in  adict['rows']: #
        if i_row['op'] in ('delete', 'update', 'updatedirty'):
            list_PreId.append( i_row['id'] )
    if len(list_PreId) > 0 :
        l_count = cursorSelect("select count(*) from pre_fee where id in ( %s ) and (lock_flag=true or audit_id=true or ex_feeid='E') " % ",".join(list_PreId))
        if l_count[0][0] > 0 :
            l_rtn.update( { "msg": "失败", "error":["变更委托应付费用被锁或者已经核销"], "stateCod" : -1 } )
            return l_rtn
    l_rtn.update( json2upd(adict) )
    return l_rtn

def update_gotfee(request, adict):
    '''  应收费用  lock_flag=true or audit_id=true or ex_feeid='E'   '''
    l_rtn = { }
    list_ActId = []
    for i_row in  adict['rows']: #
        if i_row['op'] in ('delete', 'update', 'updatedirty'):
            list_ActId.append( i_row['id'] )
    if len(list_ActId) > 0 :
        l_count = cursorSelect("select count(*) from act_fee where id in ( %s ) and (audit_id=true or ex_feeid='E') " % ",".join(list_ActId))
        if l_count[0][0] > 0 :
            l_rtn.update( { "msg": "失败", "error":["变更的已收费用被锁或者已经核销"], "stateCod" : -1 } )
            return l_rtn
    l_rtn.update( json2upd(adict) )
    return l_rtn

def clientFeeDetailReport(request, adict):
    '''  客户费用明细报表   ex_parm:{ client_id:'', //客户id  fee_typ:'', //费用类型  begin_tim:'', //开始时间 end_tim:'' //截止时间 }'''
    l_rtn = { }
    ls_sql = '''
        select c.bill_no,sum(case p.fee_cod when 1 then amount else 0 end) baogan,sum(case p.fee_cod when 2 then amount else 0 end) chaoqi,
        sum(case p.fee_cod when 3 then amount else 0 end) duicun,sum(case p.fee_cod when 4 then amount else 0 end) banyi,
        sum(case p.fee_cod when 5 then amount else 0 end) yanhuo,sum(case p.fee_cod when 6 then amount else 0 end) xunzheng,
        sum(case p.fee_cod when 7 then amount else 0 end) changdi,sum(case p.fee_cod when 8 then amount else 0 end) tuoche,
        sum(case p.fee_cod when 11 then amount else 0 end) zhibao,
        sum(case p.fee_cod in(1,2,3,4,5,6,7,8,11) when true then 0 else amount end) qita
        from pre_fee as p,contract as c
        where  p.client_id = %s and p.fee_typ = %s and p.ex_feeid = 'O'
        and (p.fee_financial_tim between %s and %s)
        and p.contract_id = c.id
        group by c.bill_no
        '''
    list_arg = [str(adict['ex_parm']['client_id']), str(adict['ex_parm']['fee_typ']), str(adict['ex_parm']['begin_tim']) ,str(adict['ex_parm']['end_tim'])]
    try:
        list_rtn = rawSql2JsonDict(ls_sql, list_arg)
        l_rtn.update( {"msg": "查询成功", "error":[], "stateCod" : 1, "rows": list_rtn } )
    except Exception as e:
        l_rtn.update( {"msg": "查询失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn


def getRptFeeStruct(request, adict):
    '''  费用报表结构
        func: '费用报表结构',
        ex_parm: {
            'rptid':'xxx' //费用报表id int型
        }
                        [
                            {"title": "包干费", "colspan": 1},
                            {"title": "海关费用", "colspan": 2},
                        ],
                        [
                            {"field": "1", "title": "包干费", "align": "right"},
                            {"field": "3", "title": "码头堆存费", "align": "right"},
                            {"field": "4", "title": "码头搬移费", "align": "right"}
                        ]
                };
        test:
from yardApp.ajaxRespFee import getRptFeeStruct
import yardApp.ajaxRespFee
from imp import reload
aaa = {
"func": '费用报表结构',
"ex_parm": {
'rptid':1 #费用报表id int型
}
}
 yardApp.ajaxRespFee.getRptFeeStruct(aaa, aaa)
    '''
    ls_rptid = str(adict["ex_parm"]["rptid"])
    l_rtn = {"msg": "成功", "stateCod": "001", "error": [], "result": [] }
    ls_sqlitem = 'select id,item_name from c_rpt_item where rpt_id = %s order by sort_no' % ls_rptid

    ls_sqlFee = ''' select c_rpt_fee.fee_id,c_fee.fee_name from c_rpt_fee,c_fee
                        where c_rpt_fee.rpt_id = %s and c_rpt_fee.item_id = %s
                       and c_rpt_fee.fee_id = c_fee.id;
               '''
    try:
        l_item = cursorSelect(ls_sqlitem)
        log(ls_sqlitem)
        l_cacheItem = []
        l_cacheFee = []
        for i_item in l_item:
            lx = ls_sqlFee % (str(ls_rptid), str(i_item[0]))   # id
            l_fee = cursorSelect( lx )
            l_cacheItem.append( {"title": i_item[1], "colspan": len(l_fee)} )   # i_item[1] -- name
            for i_fee in l_fee:
                l_cacheFee.append( {"field": str(i_fee[0]), "title": i_fee[1], "align": "right"} )
        l_rtn["result"].append(l_cacheItem)
        l_rtn["result"].append(l_cacheFee)
    except Exception as e:
        l_rtn.update( {"msg": "查询失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn
def queryRptFee(request, adict):
    '''
    {
    func:'客户费用明细报表',
    ex_parm:{
        client_id: 客户ID,
        fee_typ:费用类型,
        begin_tim: 开始日期,  #date型
        end_tim: 截止日期,    #date型
        rpt: 报表id
    }
}
select * from pre_fee where contract_id in    (
    select id from contract  where bill_no in   (
        select c.bill_no  from pre_fee as p,contract as c  where   p.contract_id = c.id   group by c.bill_no) );
import yardApp.ajaxRespFee
aaa = {
"func": '客户费用明细报表',
"ex_parm": {  "client_id": 53,
        "fee_typ": I ,
        "begin_tim": '2001-1-1',
        "end_tim": '2022-2-2',
        "rpt": 1   }
}
yardApp.ajaxRespFee.queryRptFee(aaa, aaa)
from imp import reload
reload(yardApp.ajaxRespFee)
'''
    l_rtn = {"msg": "成功", "stateCod": "001", "error": [], "rows": [] }
    ls_clientId = str(adict["ex_parm"]["client_id"])
    ls_feeType = str(adict["ex_parm"]["fee_typ"])
    ls_beginTim = str(adict["ex_parm"]["begin_tim"])
    ls_endTim = str(adict["ex_parm"]["end_tim"])
    ls_rptid = str(adict["ex_parm"]["rpt"])
    ls_sqlFee = '''select c_rpt_fee.fee_id,c_fee.fee_name from c_rpt_fee,c_fee
                      where c_rpt_fee.rpt_id = %s and c_rpt_fee.item_id in
                      (select id from c_rpt_item where rpt_id = %s )
                      and c_rpt_fee.fee_id = c_fee.id;''' % (ls_rptid, ls_rptid)
    try:
        l_fee = cursorSelect(ls_sqlFee)
        l_cacheFeeCod = []
        l_cacheFeeSql = []
        for i_fee in l_fee:
            l_cacheFeeSql.append( ' sum(case p.fee_cod when %s then amount else 0 end) "%s" ' % (str(i_fee[0]), str(i_fee[0]) ) )
            l_cacheFeeCod.append(str(i_fee[0]))
        if len(l_cacheFeeCod) > 0:
            ls_sqlAll = ''' select c.bill_no,%s,
                  sum(case p.fee_cod in(%s) when true then amount else 0 end) zongji
                  from pre_fee as p,contract as c
                  where  p.client_id = %s and p.fee_typ = '%s' and p.ex_feeid = 'O'
                  and (p.fee_financial_tim between '%s' and '%s')
                  and p.contract_id = c.id
                  group by c.bill_no
            ''' % ( ",".join(l_cacheFeeSql) ,  ",".join(l_cacheFeeCod), ls_clientId,ls_feeType,ls_beginTim,ls_endTim )
            l_result = rawSql2JsonDict(ls_sqlAll)
            l_rtn.update( {"msg": "查询成功", "error":[], "stateCod" : 1, "rows": l_result } )
        else:
            l_rtn.update( {"msg": "没定义查询数据列。", "error": [] , "stateCod" : 0 } )
    except Exception as e:
        l_rtn.update( {"msg": "查询失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn

def initProtElemContent(request, adict):
    '''  # 协议要素内容初始化
    import yardApp.ajaxRespFee
    import zdCommon.dbhelp
    aaa = { "func": '协议要素内容初始化',
        "reqtype": 'update',
        "ex_parm": {   "id": '1'  } }
    yardApp.ajaxRespFee.initProtElemContent(aaa, aaa)
    '''
    l_rtn = {"msg": "成功", "stateCod": "001", "error": [], "rows": [] }
    l_recnam = request.session['userid']
    ls_eleId = str(adict["ex_parm"]["id"])
    ls_sqlinit = "select init_data_sql from p_fee_ele where id = %s"
    lds_rtn = cursorSelect(ls_sqlinit, [ls_eleId])
    try:
        if lds_rtn:
            ls_sub = str(lds_rtn[0][0]).replace('"',"'")
            ls_sqlIns = ''' insert into p_fee_ele_lov(ele_id, lov_cod, lov_name, rec_nam, rec_tim)
                      select '%s' as ele_id , lov_cod, lov_name, %s, now()  from
                      ( %s ) tt2
                      where lov_cod not in (select lov_cod from p_fee_ele_lov where ele_id = '%s')
                  ''' %  (ls_eleId,  l_recnam , ls_sub, ls_eleId)
            cursorExec(ls_sqlIns)
        ls_sqlrtn = "select id,ele_id,lov_cod,lov_name,remark from p_fee_ele_lov where ele_id = %s "
        lds_rtn2 = cursorSelect(ls_sqlinit, [ls_eleId])
        l_result = rawSql2JsonDict(ls_sqlrtn, [ls_eleId])
        l_rtn.update( {"msg": "操作成功", "error":[], "stateCod" : 1, "rows": l_result } )
    except Exception as e:
        l_rtn.update( {"msg": "操作失败", "error": list( (str(e.args),) ) , "stateCod" : -1 } )
    return l_rtn


