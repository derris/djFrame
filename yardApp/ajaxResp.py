__author__ = 'dddh'
from zdCommon.sysjson import getMenuPrivilege, setMenuPrivilege, getFunc4User, checkPrivilege
from yardApp.ajaxRespFee import *
from yardApp.ajaxRespBase import *
from yardApp.ajaxRespQuery import *

##########################################################        GET    ----
def getsysmenu(request):
    '''功能查询'''
    ldict = json.loads(request.POST['jpargs'])
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_menu  "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getsysfunc(request):
    '''权限查询'''
    ldict = json.loads(request.POST['jpargs'])
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_func "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getsysmenufunc(request):
    '''功能权限查询'''
    ldict = json.loads(request.POST['jpargs'])
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_menu_func "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getuser(request):
    '''用户查询'''
    ldict = json.loads(request.POST['jpargs'])
    #加上密码字段过滤
    if 'password' in ldict['cols']:
        del ldict['cols'][ldict['cols'].index('password')]
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_user where username <> 'Admin'"
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getpost(request):
    '''岗位查询'''
    ldict = json.loads(request.POST['jpargs'])
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_post "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getpostuser(request):
    '''岗位用户查询'''
    ldict = json.loads(request.POST['jpargs'])
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_postuser "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getclients(request):
    '''客户查询'''
    #ls_sql = "select id,client_name,client_flag,custom_flag, ship_corp_flag, yard_flag,port_flag,financial_flag,remark,rec_tim from c_client"
    ldict = json.loads(request.POST['jpargs'])
    ls_sql = "select " + ", ".join(ldict['cols']) + " from c_client "
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getclientsEx(request, aSql):
    '''客户查询'''
    ls_sql = aSql
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getsyscod(request):
    '''系统参数查询'''
    ls_sql = "select id,fld_eng,fld_chi,cod_name,fld_ext1,fld_ext2,seq,remark from sys_code"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getAuth(request):
    ldict = json.loads(request.POST['jpargs'])
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_menu where parent_id <> 0 "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getcntrtype(request):
    '''箱型查询'''
    ls_sql = "select id,cntr_type,cntr_type_name,remark from c_cntr_type"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getaction(request):
    '''动态类型查询'''
    ls_sql = "select id,action_name,sortno,remark from c_contract_action"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getdispatch(request):
    '''发货地查询'''
    ls_sql = "select id,place_name,remark from c_dispatch"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getcargo(request):
    '''货物查询'''
    ls_sql = "select id,cargo_name,remark from c_cargo"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getcargotype(request):
    '''货物分类查询'''
    ls_sql = "select id,type_name,remark from c_cargo_type"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getplace(request):
    '''产地查询'''
    ls_sql = "select id,place_name,remark from c_place"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getfeecod(request):
    '''费用名称查询'''
    ls_sql = "select id,fee_name,pair_flag,remark from c_fee"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getpaytype(request):
    '''付款方式查询'''
    ls_sql = "select id,pay_name,remark from c_pay_type"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getprivilege(request):
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(getMenuPrivilege(ldict['postid']), ensure_ascii=False))
def getrpt(request):
    '''费用报表头查询'''
    ls_sql = "select id,rpt_name from c_rpt"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getrptitem(request):
    '''费用报表项目查询'''
    ls_sql = "select id,rpt_id,item_name,sort_no from c_rpt_item order by sort_no"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getrptfee(request):
    '''费用报表费用查询'''
    ls_sql = "select id,rpt_id,item_id,fee_id from c_rpt_fee"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getprotocol(request):
    '''协议查询'''
    ls_sql = "select id,protocol_name,write_date,validate_date,remark from p_protocol"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getprotocolele(request):
    '''协议要素查询'''
    ls_sql = "select id,ele_name,init_data_sql,remark from p_fee_ele"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getprotocolelelov(request):
    '''协议要素内容查询'''
    ls_sql = "select id,ele_id,lov_cod,lov_name,remark from p_fee_ele_lov"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getprotocolmod(request):
    '''协议模式查询'''
    ls_sql = "select id,mod_name,col_1,col_2,col_3,col_4,col_5,col_6,col_7,col_8,col_9,col_10," \
             "mod_descript,remark from p_fee_mod"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getprotocolmodremark(request):
    '''协议模式备注查询'''
    ls_sql = "select id,mod_name,mod_descript from p_fee_mod"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))

def getprotocolfeemod(request):
    '''协议费用模式查询'''
    ls_sql = "select id,protocol_id,fee_id,mod_id,sort_no,active_flag,remark from p_protocol_fee_mod"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getprotococlrat(request):
    ls_sql = "select id,protocol_id,fee_id,mod_id,fee_ele1,fee_ele2,fee_ele3,fee_ele4,fee_ele5," \
             "fee_ele6,fee_ele7,fee_ele8,fee_ele9,fee_ele10,fee_rat,discount_rat from p_protocol_rat"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))

def getcontract(request):
    ls_sql = "select id,bill_no,vslvoy,cargo_name,origin_place,client_id,cargo_piece,cargo_weight," \
             "cargo_volume,booking_date,in_port_date,return_cntr_date,custom_id,ship_corp_id,port_id," \
             "yard_id,finish_flag,finish_time,remark,contract_no,dispatch_place,custom_title1," \
             "custom_title2,landtrans_id,check_yard_id,unbox_yard_id,credit_id,cargo_type,cntr_freedays from contract"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getcontractbybill(request):
    ls_sql = "select id,bill_no,vslvoy,cargo_name,client_id,in_port_date,remark from contract"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getcontractaction(request):
    ls_sql = "select id,contract_id,action_id,finish_flag,finish_time,remark from contract_action"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getcontractcntr(request):
    ls_sql = "select id,contract_id,cntr_type,cntr_num,check_num,remark from contract_cntr"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getcontractprefeein(request):
    ls_sql = "select id,contract_id,fee_typ,fee_cod,client_id,amount,fee_tim,fee_financial_tim," \
             "lock_flag,audit_id,ex_feeid,remark from pre_fee " \
             "where fee_typ = 'I' and ex_feeid = 'O'"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getcontractprefeeout(request):
    ls_sql = "select id,contract_id,fee_typ,fee_cod,client_id,amount,fee_tim,fee_financial_tim," \
             "lock_flag,audit_id,ex_feeid,remark from pre_fee " \
             "where fee_typ = 'O' and ex_feeid = 'O'"
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)), ensure_ascii=False))
def getJson4sql(request, aSql):
    '''已收核销查询'''
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(aSql, ldict)), ensure_ascii=False))
def getJson4sqlEx(request, aSql, aSqlCount):
    return HttpResponse(json.dumps(rawsql2json(aSql, aSqlCount), ensure_ascii=False))
def getSequence(aDict):
    ''' aDict = {"ex_parm": {"seqname":"seq_4_auditfee"} }
        seq_4_auidtfee  费用核销。结单号的序列号
        create sequence seq_4_auditfee increment by 1 minvalue 1 no maxvalue start with 1;
        return:        "msg":"",     "stateCod":0 、 -10、 -100、-1000 。 "":"result":
    '''
    ldict_rtn = {"msg": "成功", "stateCod": "0", "result": {}}
    ls_sql = "select nextval('" + str(aDict["ex_parm"]["seqnam"]) + "')"
    l_seq = cursorSelect(ls_sql)
    if len(l_seq) > 0:
        ldict_rtn.update({"result": {"seqno": str(l_seq[0][0])}})
    else:
        ldict_rtn.update({"stateCod": "-1"})
    return ldict_rtn

#############################################################    UPDATE    -----
def updateRaw(request):
    ''' 客户维护  '''
    ldict = json.loads(request.POST['jpargs'])
    return HttpResponse(json.dumps(json2upd(ldict), ensure_ascii=False))

#####################################################  common interface ----------
def dealPAjax(request):
    ls_err = ""
    if ('userid' not in request.session):
        l_rtn = {
            'error': [],
            'msg': '登录过期，请重新登录',
            'stateCod': -101
        }
        return ( HttpResponse(json.dumps(l_rtn, ensure_ascii=False)))
    ls_userid = str(request.session['userid'])
    try:
        ldict = json.loads(request.POST['jpargs'])
        log(ldict)
        # 判断是否有调用的权限。
        if (ls_userid == '1') \
                or (ldict['func'] in ('功能查询', '权限查询', '功能权限查询', 'excel导出', '文件导出',
                                      '查询条件查询', '查询体查询', '查询增加', '查询条件删除',
                                      '费用报表结构')):
            pass
        elif (ldict['func'] in getFunc4User(ls_userid)):
            # check if the function is valid
            if checkPrivilege(ldict):
                pass
            else:
                ls_errmsg = "功能溢出权限：操作数据库表非法"
                l_rtn = {"error": [ls_errmsg],
                         "msg": ldict['func'] + " " + ls_errmsg,
                         "stateCod": -1}
                return ( HttpResponse(json.dumps(l_rtn, ensure_ascii=False)))
        else:
            l_rtn = {"error": [ls_err],
                     "msg": ldict['func'] + "没有执行权限",
                     "stateCod": -1}
            return ( HttpResponse(json.dumps(l_rtn, ensure_ascii=False)))

        with transaction.atomic():
            #################################################  get
            if ldict['func'] == '功能查询':
                return (getsysmenu(request))
            elif ldict['func'] == '权限查询':
                return (getsysfunc(request))
            elif ldict['func'] == '功能权限查询':
                return (getsysmenufunc(request))
            elif ldict['func'] == '系统参数查询':
                return (getsyscod(request))
            elif ldict['func'] == '查询条件查询':
                return (getfilterhead(request))
            elif ldict['func'] == '查询体查询':
                return (getfilterbody(request))
            elif ldict['func'] == '用户查询':
                return (getuser(request))
            elif ldict['func'] == '岗位查询':
                return (getpost(request))
            elif ldict['func'] == '岗位用户查询':
                return (getpostuser(request))
            elif ldict['func'] == '箱型查询':
                return (getcntrtype(request))
            elif ldict['func'] == '动态类型查询':
                return (getaction(request))
            elif ldict['func'] == '发货地查询':
                return (getdispatch(request))
            elif ldict['func'] == '费用名称查询':
                return (getfeecod(request))
            elif ldict['func'] == '付款方式查询':
                return (getpaytype(request))
            elif ldict['func'] == '客户查询':
                return (getclients(request))
            elif ldict['func'] == '岗位权限查询':
                return (getprivilege(request))
            elif ldict['func'] == '货物查询':
                return (getcargo(request))
            elif ldict['func'] == '货物分类查询':
                return (getcargotype(request))
            elif ldict['func'] == '产地查询':
                return (getplace(request))
            ##-----------计费协议----------------------------------
            elif ldict['func'] == '协议查询':
                return (getprotocol(request))
            elif ldict['func'] == '协议要素查询':
                return (getprotocolele(request))
            elif ldict['func'] == '协议要素内容查询':
                return (getprotocolelelov(request))
            elif ldict['func'] == '协议模式查询':
                return (getprotocolmod(request))
            elif ldict['func'] == '模式描述查询':
                return (getprotocolmodremark(request))

            elif ldict['func'] == '协议费用模式查询':
                return (getprotocolfeemod(request))
            elif ldict['func'] == '协议费率查询':
                return (getprotococlrat(request))

            ############## 费用  ###################################
            elif ldict['func'] == '委托查询':
                return (getcontract(request))
            elif ldict['func'] == '业务明细报表查询':
                return (getContractDetail(request, ldict))
            elif ldict['func'] == '委托动态查询':
                return (getcontractaction(request))
            elif ldict['func'] == '委托箱查询':
                return (getcontractcntr(request))
            elif ldict['func'] == '提单查询':
                return (getcontractbybill(request))
            elif ldict['func'] == '委托应收查询':
                return (getcontractprefeein(request))
            elif ldict['func'] == '委托应付查询':
                return (getcontractprefeeout(request))
            #-------核销费用查询--------------------------------------------------------
            elif ldict['func'] == '已收付费用查询':
                ls_sql = "select id,client_id,fee_typ,amount,invoice_no,check_no,accept_no,pay_type,fee_tim,audit_id,ex_feeid " \
                         "from act_fee " \
                         "where ex_feeid = 'O' "
                return (getJson4sql(request, ls_sql))
            elif ldict['func'] == '已收核销已收查询':
                ls_sql = "select id,client_id,fee_typ,amount,invoice_no,check_no,pay_type,fee_tim,off_flag from act_fee"
                return (getJson4sql(request, ls_sql))
            elif ldict['func'] == '已收核销应收查询':
                l_clientid = str(ldict['ex_parm']['client_id'])
                ls_sql = "select  id,contract_id, fee_typ, fee_cod, client_id,amount,fee_tim,lock_flag, remark from pre_fee where client_id = %s" % l_clientid
                return (getJson4sql(request, ls_sql))
            elif ldict['func'] == '核销删除查询':
                l_rtn = auditDeleteQuery(request, ldict)
                return HttpResponse(json.dumps(l_rtn, ensure_ascii=False))
            elif ldict['func'] == '费用报表头查询':
                return (getrpt(request))
            elif ldict['func'] == '费用报表项目查询':
                return (getrptitem(request))
            elif ldict['func'] == '费用报表项目费用查询':
                return (getrptfee(request))
            elif ldict['func'] == '费用报表结构':
                return HttpResponse(json.dumps(getRptFeeStruct(request, ldict), ensure_ascii = False))
            elif ldict['func'] == '客户费用明细报表':
                return HttpResponse(json.dumps(queryRptFee(request, ldict), ensure_ascii = False))

            elif ldict['func'] == '核销删除':
                l_rtn = auditDelete(request, ldict)
                return HttpResponse(json.dumps(l_rtn, ensure_ascii=False))
            ##--------------------------------------------------
            elif ldict['func'] == '已收核销客户查询':
                ls_t = "select * from c_client where id > 0 "  #查询有未结费用的客户。
                return (getclientsEx(request, ls_t))
            elif ldict['func'] == '委托协议费用生成':
                l_rtn = contrProFeeGen(request, ldict)
                return HttpResponse(json.dumps(l_rtn, ensure_ascii=False))
            ########################################################## update
            elif ldict['func'] == '功能维护':
                return (updateRaw(request))
            elif ldict['func'] == '权限维护':
                return (updateRaw(request))
            elif ldict['func'] == '功能权限维护':
                return (updateRaw(request))
            elif ldict['func'] == '系统参数维护':
                return (updateRaw(request))
            elif ldict['func'] == '查询增加':
                return (HttpResponse(json.dumps(insert_filter(request, ldict), ensure_ascii=False)))
            elif ldict['func'] == '查询条件删除':
                return (updateRaw(request))
            elif ldict['func'] == '用户维护':
                return (HttpResponse(json.dumps(update_user(request, ldict), ensure_ascii=False)))
            elif ldict['func'] == '岗位维护':
                return (updateRaw(request))
            elif ldict['func'] == '岗位用户维护':
                return (updateRaw(request))
            elif ldict['func'] == '箱型维护':
                return (updateRaw(request))
            elif ldict['func'] == '发货地维护':
                return (updateRaw(request))
            elif ldict['func'] == '动态类型维护':
                return (updateRaw(request))
            elif ldict['func'] == '费用名称维护':
                return (updateRaw(request))
            elif ldict['func'] == '付款方式维护':
                return (updateRaw(request))
            elif ldict['func'] == '客户维护':
                return (updateRaw(request))
            elif ldict['func'] == '货物维护':
                return (updateRaw(request))
            elif ldict['func'] == '货物分类维护':
                return (updateRaw(request))
            elif ldict['func'] == '产地维护':
                return (updateRaw(request))
            elif ldict['func'] == '委托维护':
                return (updateRaw(request))
            elif ldict['func'] == '委托锁定':
                return (updateRaw(request))
            elif ldict['func'] == '委托解锁':
                return (updateRaw(request))
            elif ldict['func'] == '应收付费用维护':
                return (HttpResponse(json.dumps(update_oughtfee(request, ldict), ensure_ascii=False)))
            elif ldict['func'] == '应收付费用锁定':
                return (updateRaw(request))
            elif ldict['func'] == '应收付费用解锁':
                return (updateRaw(request))
            elif ldict['func'] == '已收付费用维护':
                return (HttpResponse(json.dumps(update_gotfee(request, ldict), ensure_ascii=False)))
            elif ldict['func'] == "menufuncpost" or ldict['func'] == "岗位权限维护":
                return (HttpResponse(json.dumps(setMenuPrivilege(request), ensure_ascii=False)))
            ########################################
            elif ldict['func'] == "取序列号":
                return (HttpResponse(json.dumps(getSequence(ldict), ensure_ascii=False)))
            ################################################  商务、核销     #######
            elif ldict['func'] == "核销":  # 导航
                return ( HttpResponse(json.dumps(dealAuditFee(request), ensure_ascii=False)))
            elif ldict['func'] == '实收付未核销查询':  # ajax 查询
                ls_sql = "select id,client_id,fee_typ,amount,invoice_no,check_no,pay_type,fee_tim,ex_feeid,remark " \
                         "from act_fee " \
                         "where COALESCE(audit_id,false) = false "
                return (getJson4sql(request, ls_sql))
            elif ldict['func'] == '应收付未核销查询':  # ajax 查询
                ls_sql = "select pre_fee.id,pre_fee.contract_id,contract.bill_no,pre_fee.fee_typ,pre_fee.fee_cod," \
                         "pre_fee.amount,pre_fee.fee_tim,pre_fee.ex_feeid,pre_fee.remark " \
                         "from pre_fee,contract " \
                         "where pre_fee.contract_id = contract.id and COALESCE(pre_fee.audit_id,false) = false "
                return (getJson4sql(request, ls_sql))
            elif ldict['func'] == '核销汇总查询':  # ajax 查询
                l_rtn = auditSumQuery(request, ldict)
                return HttpResponse(json.dumps(l_rtn, ensure_ascii=False))
            ##3---------------------------------------------------------------------
            elif ldict['func'] == '核销明细查询':  # ajax 查询
                l_rtn = auditDetailQuery(request, ldict)
                return HttpResponse(json.dumps(l_rtn, ensure_ascii=False))
            # elif ldict['func'] == '客户费用明细报表':
            #     l_rtn = clientFeeDetailReport(request, ldict)
            #     return HttpResponse(json.dumps(l_rtn, ensure_ascii=False))
            elif ldict['func'] == '费用报表头维护':
                return (updateRaw(request))
            elif ldict['func'] == '费用报表项目维护':
                return (updateRaw(request))
            elif ldict['func'] == '费用报表项目费用维护':
                return (updateRaw(request))
            ##-----------计费协议----------------------------------
            elif ldict['func'] == '协议维护':
                return (updateRaw(request))
            elif ldict['func'] == '协议要素维护':
                return (updateRaw(request))
            elif ldict['func'] == '协议要素内容维护':
                return (updateRaw(request))
            elif ldict['func'] == '协议要素内容初始化':
                l_rtn = initProtElemContent(request, ldict)
                return HttpResponse(json.dumps(l_rtn, ensure_ascii=False))
            elif ldict['func'] == '协议模式维护':
                return (updateRaw(request))
            elif ldict['func'] == '协议费用模式维护':
                return (updateRaw(request))
            elif ldict['func'] == '协议模式结构查询':
                l_rtn = queryProtStruct(request, ldict)
                return HttpResponse(json.dumps(l_rtn, ensure_ascii=False))
            elif ldict['func'] == '协议费率维护':
                return (updateRaw(request))

            #########################################################3
            elif ldict['func'] == '密码修改':  # ajax 查询
                # jpargs:{"func":"密码修改","ex_parm":{"oldpw":"ok","newpw":"123"}}
                l_rtn = changePassword(request, ldict)
                return HttpResponse(json.dumps(l_rtn, ensure_ascii=False))
            elif ldict['func'] == '业务汇总报表查询':
                return getBussSumary(request, ldict)
            elif ldict['func'] == '文件导出':
                return exportFile(request, ldict)
            elif ldict['func'] == 'excel导出':
                return exportExcelDirect(request, ldict)
            else:
                pass
    except Exception as e:
        logErr("ajaxResp.dealPAjax执行错误：%s" % str(e.args))
        ls_err = str(e.args)
    # 前面没有正确返回，这里返回一个错误。
    l_rtn = {
        "error": [ls_err],
        "msg": ldict['func'] + "执行失败",
        "stateCod": -1,
    }
    return ( HttpResponse(json.dumps(l_rtn, ensure_ascii=False)))
