__author__ = 'zhangtao'
# render 前台界面
import json
from django.shortcuts import render
from yardApp import models,views
from zdCommon import easyuihelp
from django.http import HttpResponse
from zdCommon.sysjson import getMenuList

def logonview(request):
    return render(request,"yard/logon.html")

def indexview(request):
    return render(request,"yard/index.html")

def maintabview(request):
    return render(request,"yard/MainTab.html")

def mainmenutreeview(request):
    menudata = getMenuList()
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
    funcname = easyuihelp.EasyuiFieldUI(model=models.SysFunc,field='funcname')
    remark = easyuihelp.EasyuiFieldUI(model=models.SysFunc,field='remark')
    return render(request,'yard/sysdata/sysfunc.html',locals())
def sysmenufuncview(request):
    menuid = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='id')
    menuname = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='menuname')
    menu_parent_id = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='parent_id',autoforeign=True,foreigndisplayfield='menushowname',hidden=True)
    id = easyuihelp.EasyuiFieldUI(model=models.SysMenuFunc,field='id')
    menu_id = easyuihelp.EasyuiFieldUI(model=models.SysMenuFunc,field='menu_id',hidden=True)
    func_id = easyuihelp.EasyuiFieldUI(model=models.SysMenuFunc,field='func_id',autoforeign=True,foreigndisplayfield='funcname')
    remark = easyuihelp.EasyuiFieldUI(model=models.SysMenuFunc,field='remark')
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
    username = easyuihelp.EasyuiFieldUI(model=models.User,field='username')
    password = easyuihelp.EasyuiFieldUI(model=models.User,field='password',hidden=True)
    lock = easyuihelp.EasyuiFieldUI(model=models.User,field='lock')
    remark = easyuihelp.EasyuiFieldUI(model = models.User,field='remark')
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
    clientNameObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='client_name')
    clientFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='client_flag')
    customFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='custom_flag')
    shipcorpFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='ship_corp_flag')
    yardFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='yard_flag')
    portFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='port_flag')
    financialFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='financial_flag')
    remarkObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='remark')
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
    actionid = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='id')
    actioncontractid = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='contract_id',hidden=True)
    actionid = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='action_id',autoforeign=True,foreigndisplayfield='action_name')
    finish_flag = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='finish_flag')
    finish_time = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='finish_time')
    actionremark = easyuihelp.EasyuiFieldUI(model=models.ContractAction,field='remark')
    cntrid = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='id')
    cntrcontractid = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='contract_id',hidden=True)
    cntr_type = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='cntr_type',autoforeign=True,foreigndisplayfield='cntr_type')
    cntr_num = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='cntr_num')
    cntrremark = easyuihelp.EasyuiFieldUI(model=models.ContractCntr,field='remark')
    clientdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='client_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    customdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='custom_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    shipcorpdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='ship_corp_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    portdata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='port_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    yarddata = json.dumps(easyuihelp.EasyuiFieldUI(model=models.Contract,field='yard_id',autoforeign=True,foreigndisplayfield='client_name').editor['options']['data'],ensure_ascii = False)
    return render(request,"yard/contract/contractview.html",locals())
def contractform(request):
    return render(request,"yard/contract/contractform.html")
def contractgrid(request):
    id = easyuihelp.EasyuiFieldUI(model=models.Contract,field='id')
    bill_no = easyuihelp.EasyuiFieldUI(model=models.Contract,field='bill_no')
    vslvoy = easyuihelp.EasyuiFieldUI(model=models.Contract,field='vslvoy')
    cargo_name = easyuihelp.EasyuiFieldUI(model=models.Contract,field='cargo_name')
    origin_place = easyuihelp.EasyuiFieldUI(model=models.Contract,field='origin_place')
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
    finish_tim = easyuihelp.EasyuiFieldUI(model=models.Contract,field='finish_tim')
    finish_flag = easyuihelp.EasyuiFieldUI(model=models.Contract,field='finish_flag')
    remark = easyuihelp.EasyuiFieldUI(model=models.Contract,field='remark')
    return render(request,"yard/contract/contractgrid.html",locals())

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
    offFlagObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='off_flag',readonly=True)
    return render(request,"yard/fee/actfee.html",locals())
def prefeeauditview(request):
    idObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='id')
    clientIdObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    feeTypObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_typ')
    amountObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='amount')
    invoiceNoObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='invoice_no',width=100)
    checkNoObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='check_no',width=100)
    payTypeObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='pay_type',autoforeign=True,foreigndisplayfield='pay_name')
    feeTimObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='fee_tim')
    exfeeidObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='ex_feeid')
    offFlagObj = easyuihelp.EasyuiFieldUI(model=models.ActFee,field='off_flag',readonly=True)

    idObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='id')
    contracIdObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='contract_id')
    feeTypObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_typ')
    feeCodObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_cod')
    clientIdObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='client_id',autoforeign=True,foreigndisplayfield='client_name')
    amountObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='amount')
    feeTimObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='fee_tim')
    lockFlagObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='lock_flag')
    exfeeidObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='ex_feeid')
    remarkObj2 = easyuihelp.EasyuiFieldUI(model=models.PreFee,field='remark',readonly=True)
    return render(request,"yard/fee/prefeeaudit.html",locals())

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
    elif ls_args == "委托头表单":
        return(contractform(request))
    #######  费用 #############
    elif ls_args == "已收费用":
        return(actfeeview(request))
    elif ls_args == "已收核销":
        return(prefeeauditview(request))
    else:
        return HttpResponse("找不到功能名，请联系管理员")