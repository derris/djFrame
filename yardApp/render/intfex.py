__author__ = 'gw'
__doc__ ='''
    render的交换接口。
'''
from django.http import HttpResponse
from yardApp.render.renderviews import *


def index(request):
    '''主界面访问'''
    return indexview(request)


def dealMenuReq(request):
    '''
        浏览器端点击菜单访问的Get模式处理。参数｛menutext｝
        问题：ie ajax 不能包含中文中文需用encodeURI("./dealmenureq/?menutext=登录窗口")    处理一下
    '''
    ls_args = request.GET['menutext']
    if ls_args == '主窗口':
        return(maintabview(request))
    elif ls_args == '登录窗口':
        return(logonview(request))
    elif ls_args == '导航菜单':
        return(mainmenutreeview(request))
    elif ls_args == '通用查询':
        return(getcommonsearchview(request))
    elif ls_args == '查询保存':
        return(filteroptionview(request))
    elif ls_args == '查询选择':
        return(filterview(request))
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
    elif ls_args == '密码修改':
        return(pwupdateview(request))
    elif ls_args == '岗位维护':
        return(postview(request))
    elif ls_args == '岗位用户维护':
        return(postuserview(request))
    elif ls_args == '岗位权限维护':
        return(postmenufuncview(request))
    elif ls_args == '箱型维护':
        return(cntrtypeview(request))
    elif ls_args == '发货地维护':
        return(dispatchview(request))
    elif ls_args == '委托动态类型维护':
        return(actionview(request))
    elif ls_args == '费用名称维护':
        return(feecodview(request))
    elif ls_args == '付款方式维护':
        return(paytypeview(request))
    elif ls_args == '客户维护':
        return(clientview(request))
    elif ls_args == '货物维护':
        return(cargoview(request))
    elif ls_args == '货物分类维护':
        return(cargotypeview(request))
    elif ls_args == '产地维护':
        return(placeview(request))
    elif ls_args == '委托维护':
        return(contractview(request))
    elif ls_args == '提单查询':
        return(billsearchview(request))
    elif ls_args == '委托费用维护':
        return(prefeeview(request))
    elif ls_args == '委托查询':
        return(contractqueryview(request))
    elif ls_args == '业务明细报表':
        return(contractreportview(request))
    elif ls_args == '业务汇总报表':
        return(contractgroupreportview(request))
    elif ls_args == '账单':
        return(feesheetview(request))
    #######  费用 #############(func='已收费用维护')
    elif ls_args == "收款/付款":
        return(actfeeview(request))
    elif ls_args == "核销":
        return(auditview(request))
    elif ls_args == "取消核销":
        return(unauditview(request))
    elif ls_args == "核销查询":
        return(auditqueryview(request))
    elif ls_args == "费用报表定义":
        return(rptview(request))
    elif ls_args == "协议费用生成":
        return(protocolfeecreateview(request))

    ######## 协议 ##############
    elif ls_args == '协议维护':
        return(protocolview(request))
    elif ls_args == '协议要素维护':
        return(protocolfeeeleview(request))
    elif ls_args == '协议要素内容维护':
        return(protocolfeeelelovview(request))
    elif ls_args == '协议模式定义':
        return(protocolmodview(request))
    elif ls_args == '协议费用模式维护':
        return(protocolfeemodview(request))
    elif ls_args == '协议费率维护':
        return(protocolratview(request))
    elif ls_args == '协议费率复制':
        return(protocolratcopyview(request))

    else:
        return HttpResponse("找不到功能名，请联系管理员")