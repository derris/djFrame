from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader,RequestContext
from django.views.decorators.http import require_http_methods
from collections import OrderedDict

from django.db import transaction, connection

from django.core import serializers
import json

from zdCommon.dbhelp import rawsql2json,rawsql4request,json2upd
from zdCommon.dbhelp import cursorSelect

from yardApp import models
#from yardApp import renderviews
# Create your views here.
#################################################################### 基本成品功能。



def logon(request):
    l_get = json.loads( request.POST['jpargs'] )
    ls_user = l_get["name"]
    ls_pass = l_get["password"]
    l_cur = connection.cursor()
    l_cur.execute("select id from s_user where username = %s and password = %s ", [ls_user, ls_pass ])
    l_rtn = {}
    if l_cur.cursor.rowcount > 0 :
        l_userid = l_cur.fetchone()[0]
        request.session['userid'] = l_userid
        request.session['logon'] = True
        l_rtn = { "stateCod" : 2}
    else:
        request.session['userid'] = ''
        request.session['logon'] = False
        l_rtn = { "stateCod": -2 }
    return HttpResponse(json.dumps(l_rtn,ensure_ascii = False))


def logout(request):
    request.session['userid'] = ''
    request.session['logon'] = False
    return HttpResponse(json.dumps({ "stateCod": 3 },ensure_ascii = False))




@csrf_exempt
@transaction.atomic
def updateClients(request):
    ldict = json.loads( request.POST['jpargs'] )
    ''' # 测试delete。
    ldict = { 'reqtype':'update',
        'rows': [ {  'op': 'delete',    'table': 'c_client',  'id': 11 , 'subs': {}},
                  {  'op': 'delete',    'table': 'c_client',  'id': 12 , 'subs': {}}
                  ]
        }
    '''
    if ldict['reqtype'] in ('insert', 'update'):
        pass
    else:
        raise Exception("不认识的标识")
    ls_rtn = json2upd(ldict)

    return HttpResponse(json.dumps(ls_rtn,ensure_ascii = False))



@csrf_exempt
def getclients2(request):
    ls_sql = "select id,client_name,client_flag,custom_flag, ship_corp_flag, yard_flag,port_flag,financial_flag,remark,rec_tim from c_client"
    #得到post的参数
    if request.method == 'GET':
        pass
    else:
        ldict = json.loads( request.POST['jpargs'] )
        print('得到post参数', ldict)
        if 'page' in ldict.keys():
            pass
        else:
            raise Exception('there is no page keys')
    jsonData = rawsql2json(*rawsql4request(ls_sql, ldict))
    # jsonData.update({ "msg": "", "stateCod":"" }) 可以在这里更新
    return HttpResponse(str(jsonData).replace("'", '"')) # js 不认识单引号。


@csrf_exempt
def getsyscod(request):
    ls_sql = "select id,fld_eng,fld_chi,cod_name,fld_ext1,fld_ext2,seq,remark from sys_code"
    #得到post的参数
    if request.method == 'GET':
        pass
    else:
        ldict = json.loads( request.POST['jpargs'] )
        if 'page' in ldict.keys():
            pass
        else:
            raise Exception('there is no page keys')
    jsonData = rawsql2json(*rawsql4request(ls_sql, request.POST))
    # jsonData.update({ "msg": "", "stateCod":"" }) 可以在这里更新
    return HttpResponse(str(jsonData).replace("'", '"')) # js 不认识单引号。


def getsysmenu(request):
    ls_sql = "select id,menuname,menushowname,parent_id,sortno,sys_flag,remark from sys_menu "
    #得到post的参数
    if request.method == 'GET':
        pass
    else:
        ldict = json.loads( request.POST['jpargs'] )
        if 'page' in ldict.keys():
            pass
        else:
            raise Exception('there is no page keys')
    jsonData = rawsql2json(*rawsql4request(ls_sql, request.POST))
    # jsonData.update({ "msg": "", "stateCod":"" }) 可以在这里更新
    return HttpResponse(str(jsonData).replace("'", '"')) # js 不认识单引号。

def getMenuList():
    l_menu1 = cursorSelect('select id, menuname, menushowname from sys_menu where parent_id = 0 and id <> 0 order by sortno;')
    ldict_1 = []
    if len(l_menu1) > 0:  # 有1级菜单，循环读出到dict中。
        for i_m1 in l_menu1:
            l_menu2 = cursorSelect('select id,menuname, menushowname from sys_menu where parent_id = %d order by sortno;' % i_m1[0])
            ldict_2 = []
            if len(l_menu2) > 0 :
                for i_m2 in l_menu2:
                    ldict_2.append({"id": i_m2[0], "text": i_m2[2], "attributes": i_m2[1]})
            else:
                pass # no child
            ldict_1.append( { "id": i_m1[0], "text": i_m1[2], "attributes": i_m1[1], 'children': ldict_2  } )
    else:
        pass   # no top menu ... how that posible ....
    return(ldict_1)




def dealPAjax(request):
    ldict = json.loads( request.POST['jpargs'] )
    if ldict['func'] == '功能查询':
        return(getsysmenu(request))
    elif ldict['func'] == '功能维护':
        return(updateClients(request))
    elif ldict['func'] == '客户查询':
        return(getclients2(request))
    elif ldict['func'] == '客户维护':
        return(updateClients(request))
    else:
        pass

