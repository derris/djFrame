__author__ = 'Administrator'

from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import HttpResponse
import json
from django.db import transaction, connection
from zdCommon.dbhelp import rawsql2json,rawsql4request,json2upd
from zdCommon.dbhelp import cursorSelect

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
    '''权限查询'''
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from sys_menu_func "
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


#############################################################    UPDATE    -----
@csrf_exempt
@transaction.atomic
def updateClients(request):
    ''' 客户维护  '''
    return HttpResponse(json.dumps(json2upd(ldict = json.loads( request.POST['jpargs'] )),ensure_ascii = False))

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
    elif ldict['func'] == '客户维护':
        return(updateClients(request))
    else:
        return("no data")

