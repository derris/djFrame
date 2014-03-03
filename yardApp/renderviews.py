__author__ = 'zhangtao'
# render 前台界面
from django.shortcuts import render
from yardApp import models,views
from zdCommon import easyuihelp
from django.http import HttpResponse

def logonview(request):
    return render(request,"yard/logon.html")

def indexview(request):
    return render(request,"yard/index.html")

def maintabview(request):
    return render(request,"yard/MainTab.html")

def mainmenutreeview(request):
    menudata = views.getMenuList()
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
    recTimObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='rec_tim')
    remarkObj = easyuihelp.EasyuiFieldUI(model=models.Client,field='remark')
    return render(request,"yard/basedata/clients.html",locals())

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
    elif ls_args == '客户维护':
        return(clientview(request))
    else:
        return HttpResponse("找不到功能名，请联系管理员")