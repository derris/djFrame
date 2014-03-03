__author__ = 'Administrator'

from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import HttpResponse
import json
from django.db import transaction, connection
from zdCommon.dbhelp import rawsql2json,rawsql4request,json2upd
from zdCommon.dbhelp import cursorSelect

##########################################################        GET    ----
# 查询参数 json string。
#    jpargs:  '''
#               { 'reqtype':'query'    #  类型。
#               'rows':10,          #  -1 表示不分页。返回全部的数据。
#               'page':1,           #  当前页码数。
#               'cols':['colname1','colname2','colname3'],    # 查询栏目。
#               'filter':[{                       # 前台传递的查询条件参数。
#                          'cod':'client_name',
#                          'operatorTyp':'等于',
#                          'value':'值'
#                       },...],
#               'sort':[{                        # 前台传递过来的排序参数。
#                       'cod':'client_name',     # 排序字段，
#                       'order_typ':'升序'       # 排序升降
#                       }, ... ]'
#               }   '''
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
    ''''''
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_user "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getpost(request):
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_post "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getpostuser(request):
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_postuser "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
@csrf_exempt
def getclients(request):
    '''客户查询'''
    ls_sql = "select id,client_name,client_flag,custom_flag, ship_corp_flag, yard_flag,port_flag,financial_flag,remark,rec_tim from c_client"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps( rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
@csrf_exempt
def getsyscod(request):
    '''系统参数查询'''
    ls_sql = "select id,fld_eng,fld_chi,cod_name,fld_ext1,fld_ext2,seq,remark from sys_code"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, request.POST)),ensure_ascii = False))
def getAuth(request):
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_menu where parent_id <> 0 "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getcntrtype(request):
    '''箱型查询'''
    ls_sql = "select id,cntr_type,cntr_type_name,remark from c_cntr_type"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, request.POST)),ensure_ascii = False))
def getaction(request):
    '''动态类型查询'''
    ls_sql = "select id,action_name,require_flag,sortno,remark from c_contract_action"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, request.POST)),ensure_ascii = False))
def getfeegroup(request):
    '''费用分组类型查询'''
    ls_sql = "select id,group_name,remark from c_fee_group"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, request.POST)),ensure_ascii = False))
def getfeecod(request):
    '''费用名称查询'''
    ls_sql = "select id,fee_name,fee_group_id,pair_flag,protocol_flag,remark from c_fee"
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, request.POST)),ensure_ascii = False))


#############################################################    UPDATE    -----
@csrf_exempt
@transaction.atomic
def updateClients(request):
    ''' 客户维护  '''
    return HttpResponse(json.dumps(json2upd(json.loads( request.POST['jpargs'] )),ensure_ascii = False))

#####################################################  common interface ----------
def dealPAjax(request):
    ldict = json.loads( request.POST['jpargs'] )
    # check and valid here ...
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

    elif ldict['func'] == '客户查询':
        return(getclients(request))

    ################################################## update
    elif ldict['func'] == '功能维护':
        return(updateClients(request))
    elif ldict['func'] == '权限维护':
        return(updateClients(request))
    elif ldict['func'] == '功能权限维护':
        return(updateClients(request))
    elif ldict['func'] == '系统参数维护':
        return(updateClients(request))
    elif ldict['func'] == '用户维护':
        return(updateClients(request))
    elif ldict['func'] == '岗位维护':
        return(updateClients(request))
    elif ldict['func'] == '岗位用户维护':
        return(updateClients(request))
    elif ldict['func'] == '箱型维护':
        return(updateClients(request))
    elif ldict['func'] == '动态类型维护':
        return(updateClients(request))
    elif ldict['func'] == '费用分组类型维护':
        return(updateClients(request))
    elif ldict['func'] == '费用名称维护':
        return(updateClients(request))

    elif ldict['func'] == '客户维护':
        return(updateClients(request))
    else:
        return("no data")

