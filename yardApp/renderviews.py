__author__ = 'zhangtao'
# render 前台界面
import json
from django.shortcuts import render
from yardApp import models
from zdCommon import easyuihelp
from django.http import HttpResponse
from zdCommon.sysjson import getMenuList,getMenuListByUser
from zdCommon.dbhelp import fetchSeq
def logonview(request):
    return render(request,"yard/logon.html")

def indexview(request):
    return render(request,"yard/index.html")

def maintabview(request):
    return render(request,"yard/MainTab.html")

def mainmenutreeview(request):    #
    l_userid = int(request.session['userid'])
    if l_userid == 1:
        menudata = getMenuList()
    else:
        menudata = getMenuListByUser(l_userid)
    return render(request,"yard/MainMenuTree.html",locals())

def getcommonsearchview(request):
    return render(request,"commonSearchTemplate.html")

def sysmenuview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='id')
    menuname = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='menuname')
    menushowname = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='menushowname')
    parent_id = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='parent_id',autoforeign=True,foreigndisplayfield='menushowname')
    sortno = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='sortno')
    sys_flag = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='sys_flag')
    remark = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='remark')
    return render(request,'yard/sysdata/sysmenu.html',locals())
def sysfuncview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.SysFunc,field='id')
    funcname = easyuihelp.EasyuiFieldUI(model=models.SysFunc,field='funcname',width=200)
    remark = easyuihelp.EasyuiFieldUI(model=models.SysFunc,field='remark',width=250)
    return render(request,'yard/sysdata/sysfunc.html',locals())
def sysmenufuncview(request):
    menuid = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='id')
    menuname = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='menuname',width=200)
    menu_parent_id = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='parent_id',autoforeign=True,foreigndisplayfield='menushowname',hidden=True)
    id = easyuihelp.EasyuiFieldUI(model=models.SysMenuFunc,field='id')
    menu_id = easyuihelp.EasyuiFieldUI(model=models.SysMenuFunc,field='menu_id',hidden=True)
    func_id = easyuihelp.EasyuiFieldUI(model=models.SysMenuFunc,field='func_id',autoforeign=True,foreigndisplayfield='funcname',width=200)
    remark = easyuihelp.EasyuiFieldUI(model=models.SysMenuFunc,field='remark',width=200)
    return render(request,'yard/sysdata/sysmenufunc.html',locals())
def syscodview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='id')
    fldEng = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='fld_eng')
    fldChi = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='fld_chi')
    codName = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='cod_name')
    fldExt1 = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='fld_ext1')
    fldExt2 = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='fld_ext2')
    seq = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='seq')
    remark = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='remark')
    return render(request,"yard/sysdata/syscod.html",locals())
def userview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.User,field='id')
    username = easyuihelp.EasyuiFieldUI(model=models.User,field='username',width=180)
    password = easyuihelp.EasyuiFieldUI(model=models.User,field='password',hidden=True)
    lock = easyuihelp.EasyuiFieldUI(model=models.User,field='lock')
    remark = easyuihelp.EasyuiFieldUI(model = models.User,field='remark',width=180)
    return render(request,"yard/basedata/user.html",locals())
def postview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.Post,field='id')
    postname = easyuihelp.EasyuiFieldUI(model=models.Post,field='postname')
    remark = easyuihelp.EasyuiFieldUI(model=models.Post,field='remark')
    return render(request,"yard/basedata/post.html",locals())
def postuserview(request):
    postid = easyuihelp.EasyuiFieldUI(model=models.Post,field='id')
    postname = easyuihelp.EasyuiFieldUI(model=models.Post,field='postname')
    id = easyuihelp.EasyuiFieldUI(model=models.PostUser,field='id')
    post_id = easyuihelp.EasyuiFieldUI(model=models.PostUser,field='post_id',hidden=True)
    user_id = easyuihelp.EasyuiFieldUI(model=models.PostUser,field='user_id',autoforeign=True,foreigndisplayfield='username')
    remark = easyuihelp.EasyuiFieldUI(model=models.PostUser,field='remark')
    return render(request,"yard/basedata/postuser.html",locals())
def postmenufuncview(request):
    postid = easyuihelp.EasyuiFieldUI(model=models.Post,field='id')
    postname = easyuihelp.EasyuiFieldUI(model=models.Post,field='postname')
    return render(request,"yard/basedata/postmenufunc.html",locals())
def clientview(request):
    idObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='id')
    clientNameObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='client_name',width=200)
    clientFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='client_flag')
    customFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='custom_flag')
    shipcorpFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='ship_corp_flag')
    yardFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='yard_flag')
    portFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='port_flag')
    financialFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='financial_flag')
    remarkObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='remark',width=200)
    return render(request,"yard/basedata/client.html",locals())
def cntrtypeview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.CntrType,field='id')
    cntrtype = easyuihelp.EasyuiFieldUI(model=models.CntrType,field='cntr_type',width=100)
    cntrtypename = easyuihelp.EasyuiFieldUI(model=models.CntrType,field='cntr_type_name')
    remark = easyuihelp.EasyuiFieldUI(model=models.CntrType,field='remark')
    return render(request,"yard/basedata/cntrtype.html",locals())
def actionview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.Action,field='id')
    action_name = easyuihelp.EasyuiFieldUI(model=models.Action,field='action_name')
    require_flag = easyuihelp.EasyuiFieldUI(model=models.Action,field='require_flag')
    sortno = easyuihelp.EasyuiFieldUI(model=models.Action,field='sortno')
    remark = easyuihelp.EasyuiFieldUI(model=models.Action,field='remark')
    return render(request,"yard/basedata/action.html",locals())
def feegroupview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.FeeGroup,field='id')
    group_name = easyuihelp.EasyuiFieldUI(model=models.FeeGroup,field='group_name',width=120)
    remark = easyuihelp.EasyuiFieldUI(model=models.FeeGroup,field='remark')
    return render(request,"yard/basedata/feegroup.html",locals())
def feecodview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.FeeCod,field='id')
    fee_name = easyuihelp.EasyuiFieldUI(model=models.FeeCod,field='fee_name')
    fee_group_id = easyuihelp.EasyuiFieldUI(model=models.FeeCod,field='fee_group_id',autoforeign=True,foreigndisplayfield='group_name')
    pair_flag = easyuihelp.EasyuiFieldUI(model=models.FeeCod,field='pair_flag')
    protocol_flag = easyuihelp.EasyuiFieldUI(model=models.FeeCod,field='protocol_flag')
    remark = easyuihelp.EasyuiFieldUI(model=models.FeeCod,field='remark')
    return render(request,"yard/basedata/feecod.html",locals())
def feeprotocolview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.FeeProtocol,field='id')
    client_id = easyuihelp.EasyuiFieldUI(model=models.FeeProtocol,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    fee_id = easyuihelp.EasyuiFieldUI(model=models.FeeProtocol,field='fee_id',autoforeign=True,foreigndisplayfield='fee_name')
    contract_type = easyuihelp.EasyuiFieldUI(model=models.FeeProtocol,field='contract_type',autoforeign=True,foreigndisplayfield='cod_name')
    fee_cal_type = easyuihelp.EasyuiFieldUI(model=models.FeeProtocol,field='fee_cal_type',autoforeign=True,foreigndisplayfield='cod_name')
    rate = easyuihelp.EasyuiFieldUI(model=models.FeeProtocol,field='rate')
    free_day = easyuihelp.EasyuiFieldUI(model=models.FeeProtocol,field='free_day')
    remark = easyuihelp.EasyuiFieldUI(model=models.FeeProtocol,field='remark')
    return render(request,"yard/basedata/feeprotocol.html",locals())
def paytypeview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.PayType,field='id')
    pay_name = easyuihelp.EasyuiFieldUI(model=models.PayType,field='pay_name')
    remark = easyuihelp.EasyuiFieldUI(model=models.PayType,field='remark')
    return render(request,"yard/basedata/paytype.html",locals())
def contractview(request):
    #seq = str(fetchSeq('seq_html'))
    actionid = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='id')
    actioncontractid = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='contract_id',hidden=True)
    action_id = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='action_id',autoforeign=True,foreigndisplayfield='action_name')
    finish_flag = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='finish_flag')
    finish_time = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='finish_time')
    actionremark = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='remark',width=200)
    cntrid = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='id')
    cntrcontractid = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='contract_id',hidden=True)
    cntr_type = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='cntr_type',autoforeign=True,foreigndisplayfield='cntr_type')
    cntr_num = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='cntr_num')
    cntrremark = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='remark',width=200)
    clientdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='client_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    customdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='custom_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    shipcorpdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='ship_corp_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    portdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='port_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    yarddata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='yard_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    display_toolbar = True
    return render(request,"yard/contract/contractview.html",locals())

def contractqueryview(request):
    seq = str(fetchSeq('seq_html'))
    id = easyuihelp.EasyuiFieldUI(model=models.Contract,field='id')
    bill_no = easyuihelp.EasyuiFieldUI(model=models.Contract,field='bill_no',width=180)
    vslvoy = easyuihelp.EasyuiFieldUI(model=models.Contract,field='vslvoy',width=180)
    cargo_name = easyuihelp.EasyuiFieldUI(model=models.Contract,field='cargo_name')
    origin_place = easyuihelp.EasyuiFieldUI(model=models.Contract,field='origin_place',width=150)
    client_id = easyuihelp.EasyuiFieldUI(model=models.Contract,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    cargo_piece = easyuihelp.EasyuiFieldUI(model=models.Contract,field='cargo_piece')
    cargo_weight = easyuihelp.EasyuiFieldUI(model=models.Contract,field='cargo_weight')
    cargo_volume = easyuihelp.EasyuiFieldUI(model=models.Contract,field='cargo_volume')
    booking_date = easyuihelp.EasyuiFieldUI(model=models.Contract,field='booking_date')
    in_port_date = easyuihelp.EasyuiFieldUI(model=models.Contract,field='in_port_date')
    return_cntr_date = easyuihelp.EasyuiFieldUI(model=models.Contract,field='return_cntr_date')
    custom_id = easyuihelp.EasyuiFieldUI(model=models.Contract,field='custom_id',autoforeign=True,foreigndisplayfield='client_name')
    ship_corp_id = easyuihelp.EasyuiFieldUI(model=models.Contract,field='ship_corp_id',autoforeign=True,foreigndisplayfield='client_name')
    port_id = easyuihelp.EasyuiFieldUI(model=models.Contract,field='port_id',autoforeign=True,foreigndisplayfield='client_name')
    yard_id = easyuihelp.EasyuiFieldUI(model=models.Contract,field='yard_id',autoforeign=True,foreigndisplayfield='client_name')
    finish_time = easyuihelp.EasyuiFieldUI(model=models.Contract,field='finish_time')
    finish_flag = easyuihelp.EasyuiFieldUI(model=models.Contract,field='finish_flag')
    remark = easyuihelp.EasyuiFieldUI(model=models.Contract,field='remark')
    actionid = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='id')
    actioncontractid = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='contract_id',hidden=True)
    action_id = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='action_id',autoforeign=True,foreigndisplayfield='action_name')
    finish_flag = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='finish_flag')
    finish_time = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='finish_time')
    actionremark = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='remark',width=200)
    cntrid = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='id')
    cntrcontractid = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='contract_id',hidden=True)
    cntr_type = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='cntr_type',autoforeign=True,foreigndisplayfield='cntr_type')
    cntr_num = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='cntr_num')
    cntrremark = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='remark',width=200)
    prefee_id = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='id')
    prefee_contractid = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='contract_id',hidden=True)
    prefee_feetyp = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_typ',hidden=True)
    prefee_feecod = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_cod',autoforeign=True,foreigndisplayfield='fee_name')
    prefee_client = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    prefee_amount = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='amount')
    prefee_feetim = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_tim')
    prefee_financialtim = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_financial_tim')
    prefee_lock_flag = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='lock_flag',readonly=True)
    prefee_audit_id = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='audit_id',readonly=True)
    prefee_remark = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='remark',width=200)
    display_toolbar = False
    return render(request,"yard/contract/contractqueryview.html",locals())
def billsearchview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.Contract,field='id')
    bill_no = easyuihelp.EasyuiFieldUI(model=models.Contract,field='bill_no',width=150)
    client_id = easyuihelp.EasyuiFieldUI(model=models.Contract,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    vslvoy = easyuihelp.EasyuiFieldUI(model=models.Contract,field='vslvoy')
    cargo_name = easyuihelp.EasyuiFieldUI(model=models.Contract,field='cargo_name')
    in_port_date = easyuihelp.EasyuiFieldUI(model=models.Contract,field='in_port_date',width=150)
    remark = easyuihelp.EasyuiFieldUI(model=models.Contract,field='remark')
    return render(request,"yard/contract/billsearchcombogrid.html",locals())
def prefeeview(request):
    seq = str(fetchSeq('seq_html'))
    prefee_id = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='id')
    prefee_contractid = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='contract_id',hidden=True)
    prefee_feetyp = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_typ',hidden=True)
    prefee_feecod = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_cod',autoforeign=True,foreigndisplayfield='fee_name')
    prefee_client = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    prefee_amount = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='amount')
    prefee_feetim = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_tim')
    prefee_financialtim = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_financial_tim')
    prefee_lock_flag = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='lock_flag',readonly=True)
    prefee_audit_id = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='audit_id',readonly=True)
    prefee_remark = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='remark',width=200)
    clientdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='client_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    customdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='custom_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    shipcorpdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='ship_corp_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    portdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='port_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    yarddata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='yard_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    display_toolbar = True
    return render(request,"yard/contract/contractprefeeview.html",locals())
########################### 收费 、 核销 #########
def actfeeview(request):

    idObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='id')
    clientIdObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    feeTypObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_typ')
    amountObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='amount')
    invoiceNoObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='invoice_no',width=100)
    checkNoObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='check_no',width=100)
    payTypeObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='pay_type',autoforeign=True,foreigndisplayfield='pay_name')
    feeTimObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_tim')
    audit_id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='audit_id',hidden=True)
    return render(request,"yard/fee/actfee.html",locals())
def auditview(request):    # 已收费用核销
    seq = str(fetchSeq('seq_html'))
    funcname = '核销'
    actfee_id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='id')
    actfee_client_Id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    actfee_fee_typ = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_typ')
    actfee_amount = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='amount')
    actfee_invoice_no = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='invoice_no',width=100)
    actfee_check_no = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='check_no',width=100)
    actfee_pay_type = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='pay_type',autoforeign=True,foreigndisplayfield='pay_name')
    actfee_fee_tim = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_tim')
    actfee_ex_feeid = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='ex_feeid',hidden=True)
    actfee_audit_id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='audit_id',hidden=True)
    actfee_remark = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='remark',width=200)
    prefee_id = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='id')
    prefee_contractid = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='contract_id',hidden=True)
    prefee_feetyp = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_typ')
    prefee_feecod = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_cod',autoforeign=True,foreigndisplayfield='fee_name')
    prefee_client = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name',hidden=True)
    prefee_amount = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='amount')
    #prefee_feetim = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_tim')
    #prefee_financialtim = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_financial_tim')
    #prefee_lock_flag = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='lock_flag',readonly=True)
    #prefee_audit_id = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='audit_id',readonly=True)
    prefee_remark = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='remark',width=200)
    clientdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.PreFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    feetypdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_typ').editor['options']['data'],ensure_ascii = False)
    return render(request,"yard/fee/auditview.html",locals())
def unauditview(request):    # 取消核销
    seq = str(fetchSeq('seq_html'))
    funcname = '取消核销'
    actfee_id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='id')
    actfee_client_Id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    actfee_fee_typ = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_typ')
    actfee_amount = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='amount')
    actfee_invoice_no = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='invoice_no',width=100)
    actfee_check_no = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='check_no',width=100)
    actfee_pay_type = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='pay_type',autoforeign=True,foreigndisplayfield='pay_name')
    actfee_fee_tim = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_tim',hidden=True)
    actfee_ex_feeid = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='ex_feeid',hidden=True)
    actfee_audit_id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='audit_id',hidden=True)
    actfee_audit_tim = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='audit_tim')
    actfee_remark = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='remark',width=200)
    prefee_id = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='id')
    prefee_contractid = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='contract_id',hidden=True)
    prefee_feetyp = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_typ')
    prefee_feecod = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_cod',autoforeign=True,foreigndisplayfield='fee_name')
    prefee_client = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name',hidden=True)
    prefee_amount = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='amount')
    prefee_remark = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='remark',width=200)
    clientdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.PreFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    feetypdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_typ').editor['options']['data'],ensure_ascii = False)
    return render(request,"yard/fee/unauditview.html",locals())
def auditqueryview(request):    # 核销查询
    seq = str(fetchSeq('seq_html'))
    clientdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.PreFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    feetypdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_typ').editor['options']['data'],ensure_ascii = False)
    audit_amount = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='amount')
    audit_ex_over = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='ex_over',hidden=True)
    audit_tim = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_tim',title='核销时间')
    actfee_id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='id')
    actfee_client_Id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    actfee_fee_typ = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_typ')
    actfee_amount = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='amount')
    actfee_invoice_no = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='invoice_no',width=100)
    actfee_check_no = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='check_no',width=100)
    actfee_pay_type = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='pay_type',autoforeign=True,foreigndisplayfield='pay_name')
    actfee_fee_tim = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_tim',hidden=True)
    actfee_ex_feeid = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='ex_feeid',hidden=True)
    actfee_audit_id = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='audit_id',hidden=True)
    actfee_audit_tim = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='audit_tim',hidden=True)
    actfee_remark = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='remark',width=200)
    prefee_id = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='id')
    prefee_contractid = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='contract_id',hidden=True)
    prefee_feetyp = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_typ')
    prefee_feecod = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_cod',autoforeign=True,foreigndisplayfield='fee_name')
    prefee_client = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name',hidden=True)
    prefee_amount = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='amount')
    prefee_remark = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='remark',width=200)

    return render(request,"yard/fee/auditqueryview.html",locals())

def dealMenuReq(request):
    ls_args = request.GET['menutext']
    if ls_args == '主窗口':
        return(maintabview(request))
    elif ls_args == '登录窗口':
        return(logonview(request))
    elif ls_args == '导航菜单':
        return(mainmenutreeview(request))
    elif ls_args == '通用查询':
        return(getcommonsearchview(request))
    elif ls_args == '功能维护':
        return(sysmenuview(request))
    elif ls_args == '权限维护':
        return(sysfuncview(request))
    elif ls_args == '功能权限维护':
        return(sysmenufuncview(request))
    elif ls_args == '系统参数维护':
        return(syscodview(request))
    elif ls_args == '用户维护':
        return(userview(request))
    elif ls_args == '岗位维护':
        return(postview(request))
    elif ls_args == '岗位用户维护':
        return(postuserview(request))
    elif ls_args == '岗位权限维护':
        return(postmenufuncview(request))
    elif ls_args == '箱型维护':
        return(cntrtypeview(request))
    elif ls_args == '委托动态类型维护':
        return(actionview(request))
    elif ls_args == '费用分组类型维护':
        return(feegroupview(request))
    elif ls_args == '费用名称维护':
        return(feecodview(request))
    elif ls_args == '协议费率维护':
        return(feeprotocolview(request))
    elif ls_args == '付款方式维护':
        return(paytypeview(request))
    elif ls_args == '客户维护':
        return(clientview(request))
    elif ls_args == '委托维护':
        return(contractview(request))
    elif ls_args == '提单查询':
        return(billsearchview(request))
    elif ls_args == '委托费用维护':
        return(prefeeview(request))
    elif ls_args == '委托查询':
        return(contractqueryview(request))

    #######  费用 #############(func='已收费用维护')
    elif ls_args == "收款/付款":
        return(actfeeview(request))
    elif ls_args == "核销":
        return(auditview(request))
    elif ls_args == "取消核销":
        return(unauditview(request))
    elif ls_args == "核销查询":
        return(auditqueryview(request))

    else:
        return HttpResponse("找不到功能名，请联系管理员")