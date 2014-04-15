__author__ = 'dddh'

from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponse
import json
from django.db import transaction
from zdCommon.dbhelp import rawsql2json,rawsql4request,json2upd, rawSql2JsonDict
from zdCommon.sysjson import getMenuPrivilege, setMenuPrivilege
from zdCommon.utils import log, logErr
from zdCommon.dbhelp import cursorSelect, cursorExec, cursorExec2
from datetime import datetime
from yardApp.ajaxRespFee import *


##########################################################        GET    ----
def getsysmenu(request):
    '''功能查询'''
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_menu  "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getsysfunc(request):
    '''权限查询'''
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_func "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getsysmenufunc(request):
    '''功能权限查询'''
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_menu_func "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getuser(request):
    '''用户查询'''
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_user "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getpost(request):
    '''岗位查询'''
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_post "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getpostuser(request):
    '''岗位用户查询'''
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_postuser "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getclients(request):
    '''客户查询'''
    #ls_sql = "select id,client_name,client_flag,custom_flag, ship_corp_flag, yard_flag,port_flag,financial_flag,remark,rec_tim from c_client"
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from c_client "
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps( rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getclientsEx(request, aSql):
    '''客户查询'''
    ls_sql = aSql
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps( rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getsyscod(request):
    '''系统参数查询'''
    ls_sql = "select id,fld_eng,fld_chi,cod_name,fld_ext1,fld_ext2,seq,remark from sys_code"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getAuth(request):
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_menu where parent_id <> 0 "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getcntrtype(request):
    '''箱型查询'''
    ls_sql = "select id,cntr_type,cntr_type_name,remark from c_cntr_type"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getaction(request):
    '''动态类型查询'''
    ls_sql = "select id,action_name,require_flag,sortno,remark from c_contract_action"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getfeegroup(request):
    '''费用分组类型查询'''
    ls_sql = "select id,group_name,remark from c_fee_group"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getfeecod(request):
    '''费用名称查询'''
    ls_sql = "select id,fee_name,fee_group_id,pair_flag,protocol_flag,remark from c_fee"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getfeeprotocol(request):
    '''费用名称查询'''
    ls_sql = "select id,client_id,fee_id,contract_type,fee_cal_type,rate,free_day,remark from c_fee_protocol"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getpaytype(request):
    '''付款方式查询'''
    ls_sql = "select id,pay_name,remark from c_pay_type"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getprivilege(request):
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps( getMenuPrivilege(ldict['postid']),ensure_ascii = False) )
def getcontract(request):
    ls_sql = "select id,bill_no,vslvoy,cargo_name,origin_place,client_id,cargo_piece,cargo_weight," \
             "cargo_volume,booking_date,in_port_date,return_cntr_date,custom_id,ship_corp_id,port_id," \
             "yard_id,finish_flag,finish_time,remark from contract"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getcontractbybill(request):
    ls_sql = "select id,bill_no,vslvoy,cargo_name,client_id,in_port_date,remark from contract"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))

def getcontractaction(request):
    ls_sql = "select id,contract_id,action_id,finish_flag,finish_time,remark from contract_action"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getcontractcntr(request):
    ls_sql = "select id,contract_id,cntr_type,cntr_num,remark from contract_cntr"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getcontractprefeein(request):
    ls_sql = "select id,contract_id,fee_typ,fee_cod,client_id,amount,fee_tim,fee_financial_tim," \
             "lock_flag,audit_id,remark from pre_fee " \
             "where fee_typ = 'I' and ex_feeid = 'O'"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getcontractprefeeout(request):
    ls_sql = "select id,contract_id,fee_typ,fee_cod,client_id,amount,fee_tim,fee_financial_tim," \
             "lock_flag,audit_id,remark from pre_fee " \
             "where fee_typ = 'O' and ex_feeid = 'O'"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getJson4sql(request, aSql):
    '''已收核销查询'''
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(aSql, ldict)),ensure_ascii = False))

def getJson4sqlEx(request, aSql, aSqlCount):
    return HttpResponse(json.dumps(rawsql2json(aSql, aSqlCount),ensure_ascii = False))

def getSequence(aDict):
    ''' aDict = {"ex_parm": {"seqname":"seq_4_auditfee"} }
        seq_4_auidtfee  费用核销。结单号的序列号
        create sequence seq_4_auditfee increment by 1 minvalue 1 no maxvalue start with 1;
        return:        "msg":"",     "stateCod":0 、 -10、 -100、-1000 。 "":"result":
    '''
    ldict_rtn = { "msg": "成功", "stateCod": "0" , "result":{} }
    ls_sql = "select nextval('" + str(aDict["ex_parm"]["seqnam"])  + "')"
    l_seq = cursorSelect(ls_sql)
    if len(l_seq) > 0 :
        ldict_rtn.update(  {"result":{ "seqno":str(l_seq[0][0]) } } )
    else:
        ldict_rtn.update(  {"stateCod": "-1" }  )
    return ldict_rtn
#############################################################    UPDATE    -----
def updateRaw(request):
    ''' 客户维护  '''
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(json2upd(ldict),ensure_ascii = False))
#####################################################  common interface ----------
def dealPAjax(request):
    ls_err = ""
    #request.session['userid'] = "1"
    try:
        ldict = json.loads( request.POST['jpargs'] )
        log(ldict)
        with transaction.atomic():
            #################################################  get
            if ldict['func'] == '功能查询':
                return(getsysmenu(request))
            elif ldict['func'] == '权限查询':
                return(getsysfunc(request))
            elif ldict['func'] == '功能权限查询':
                return(getsysmenufunc(request))
            elif ldict['func'] == '系统参数查询':
                return(getsyscod(request))
            elif ldict['func'] == '用户查询':
                return(getuser(request))
            elif ldict['func'] == '岗位查询':
                return(getpost(request))
            elif ldict['func'] == '岗位用户查询':
                return(getpostuser(request))
            elif ldict['func'] == '箱型查询':
                return(getcntrtype(request))
            elif ldict['func'] == '动态类型查询':
                return(getaction(request))
            elif ldict['func'] == '费用分组类型查询':
                return(getfeegroup(request))
            elif ldict['func'] == '费用名称查询':
                return(getfeecod(request))
            elif ldict['func'] == '协议费率查询':
                return(getfeeprotocol(request))
            elif ldict['func'] == '付款方式查询':
                return(getpaytype(request))
            elif ldict['func'] == '客户查询':
                return(getclients(request))
            elif ldict['func'] == '岗位权限查询':
                return(getprivilege(request))
            ############## 费用  ###################################
            elif ldict['func'] == '委托查询':
                return(getcontract(request))
            elif ldict['func'] == '委托动态查询':
                return(getcontractaction(request))
            elif ldict['func'] == '委托箱查询':
                return(getcontractcntr(request))
            elif ldict['func'] == '提单查询':
                return(getcontractbybill(request))
            elif ldict['func'] == '委托应收查询':
                return(getcontractprefeein(request))
            elif ldict['func'] == '委托应付查询':
                return(getcontractprefeeout(request))
            #-------核销费用查询--------------------------------------------------------
            elif ldict['func'] == '已收费用查询':
                ls_sql = "select id,client_id,fee_typ,amount,invoice_no,check_no,pay_type,fee_tim,audit_id " \
                         "from act_fee " \
                         "where ex_feeid = 'O' "
                return(getJson4sql(request, ls_sql))
            elif ldict['func'] == '已收核销已收查询':
                ls_sql = "select id,client_id,fee_typ,amount,invoice_no,check_no,pay_type,fee_tim,off_flag from act_fee"
                return(getJson4sql(request, ls_sql))
            elif ldict['func'] == '已收核销应收查询':
                l_clientid = str(ldict['ex_parm']['client_id'])
                ls_sql = "select  id,contract_id, fee_typ, fee_cod, client_id,amount,fee_tim,lock_flag, remark from pre_fee where client_id = %s" % l_clientid
                return(getJson4sql(request, ls_sql))
            elif ldict['func'] == '核销删除查询':
                l_rtn = auditDeleteQuery(request, ldict)
                return HttpResponse(json.dumps( l_rtn ,ensure_ascii = False))
            ###------------------------------核销删除功能
            elif ldict['func'] == '核销删除':
                l_rtn = auditDelete(request, ldict)
                return HttpResponse(json.dumps( l_rtn ,ensure_ascii = False))
            ##--------------------------------------------------
            elif ldict['func'] == '已收核销客户查询':
                ls_t = "select * from c_client where id > 0 "  #查询有未结费用的客户。
                return(getclientsEx(request, ls_t))
            ############################################################################## update
            elif ldict['func'] == '功能维护':
                return(updateRaw(request))
            elif ldict['func'] == '权限维护':
                return(updateRaw(request))
            elif ldict['func'] == '功能权限维护':
                return(updateRaw(request))
            elif ldict['func'] == '系统参数维护':
                return(updateRaw(request))
            elif ldict['func'] == '用户维护':
                return(updateRaw(request))
            elif ldict['func'] == '岗位维护':
                return(updateRaw(request))
            elif ldict['func'] == '岗位用户维护':
                return(updateRaw(request))
            elif ldict['func'] == '箱型维护':
                return(updateRaw(request))
            elif ldict['func'] == '动态类型维护':
                return(updateRaw(request))
            elif ldict['func'] == '费用分组类型维护':
                return(updateRaw(request))
            elif ldict['func'] == '费用名称维护':
                return(updateRaw(request))
            elif ldict['func'] == '协议费率维护':
                return(updateRaw(request))
            elif ldict['func'] == '付款方式维护':
                return(updateRaw(request))
            elif ldict['func'] == '客户维护':
                return(updateRaw(request))
            elif ldict['func'] == '委托维护':
                return(updateRaw(request))
            elif ldict['func'] == '委托锁定':
                return(updateRaw(request))
            elif ldict['func'] == '委托解锁':
                return(updateRaw(request))
            elif ldict['func'] == '应收付费用维护':
                return(updateRaw(request))
            elif ldict['func'] == '应收付费用锁定':
                return(updateRaw(request))
            elif ldict['func'] == '应收付费用解锁':
                return(updateRaw(request))
            elif ldict['func'] == '已收费用维护':
                return(updateRaw(request))
            elif  ldict['func'] == "menufuncpost" or ldict['func'] == "岗位权限维护":
                return(HttpResponse(json.dumps( setMenuPrivilege(request) ,ensure_ascii = False) ))
            ########################################
            elif ldict['func'] == "取序列号":
                return(HttpResponse(json.dumps( getSequence(ldict) ,ensure_ascii = False) ))
            ################################################  商务、核销     #######
            elif ldict['func'] == "核销":        # 导航
                return( HttpResponse(json.dumps( dealAuditFee(request),ensure_ascii = False) ))
            elif ldict['func'] == '实收付未核销查询':    # ajax 查询
                ls_sql = "select id,client_id,fee_typ,amount,invoice_no,check_no,pay_type,fee_tim,ex_feeid,remark " \
                         "from act_fee " \
                         "where COALESCE(audit_id,false) = false "
                return(getJson4sql(request, ls_sql))
            elif ldict['func'] == '应收付未核销查询':   # ajax 查询
                ls_sql = "select pre_fee.id,pre_fee.contract_id,contract.bill_no,pre_fee.fee_cod," \
                         "pre_fee.amount,pre_fee.fee_tim,pre_fee.ex_feeid,pre_fee.remark " \
                         "from pre_fee,contract " \
                         "where pre_fee.contract_id = contract.id and COALESCE(pre_fee.audit_id,false) = false "
                return(getJson4sql(request, ls_sql))
            elif ldict['func'] == '核销汇总查询':   # ajax 查询
                l_rtn = auditSumQuery(request, ldict)
                return HttpResponse(json.dumps( l_rtn ,ensure_ascii = False))
            ##3---------------------------------------------------------------------
            elif ldict['func'] == '核销明细查询':   # ajax 查询
                l_rtn = auditDetailQuery(request,ldict)
                return HttpResponse(json.dumps( l_rtn ,ensure_ascii = False))
            #########################################################3
            else:
                pass
    except Exception as e:
        logErr("数据库执行错误：%s" % str(e.args))
        ls_err = str(e.args)
    # 前面没有正确返回，这里返回一个错误。
    l_rtn = {
            "error": [ls_err],
            "msg":    ldict['func'] + "执行失败",
            "stateCod":  -1 ,
            }
    return( HttpResponse(json.dumps( l_rtn,ensure_ascii = False) ))
