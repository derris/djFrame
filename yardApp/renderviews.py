__author__ = 'zhangtao'
# render 前台界面
from django.shortcuts import render

from yardApp import models
from zdCommon import easyuihelp

def sysmenuview(request):
    id = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='id')
    menuname = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='menuname')
    menushowname = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='menushowname')
    parent_id = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='parent_id',foreigndisplayfield='menushowname')
    sortno = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='sortno')
    sys_flag = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='sys_flag')
    remark = easyuihelp.EasyuiFieldUI(model=models.SysMenu,field='remark')
    return render(request,'yard/sysdata/sysmenu.html',locals())
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
def clientview(request):
    idObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='id')
    clientNameObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='client_name')
    clientFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='client_flag')
    customFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='custom_flag')
    shipcorpFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='ship_corp_flag')
    yardFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='yard_flag')
    portFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='port_flag')
    financialFlagObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='financial_flag')
    recTimObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='rec_tim')
    remarkObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='remark')
    return render(request,"yard/basedata/clients.html",locals())