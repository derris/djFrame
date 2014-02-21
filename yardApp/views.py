from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader,RequestContext
from django.views.decorators.http import require_http_methods

from django.core import serializers
import json

from zdCommon.jsonhelp import ServerToClientJsonEncoder
from zdCommon import easyuihelp
from zdCommon.dbhelp import rawsql2json,rawsql4request,json2upd
#json2insert, json2update, json2upd
from django.db import transaction

from yardApp import models

# Create your views here.

def logonview(request):
    return render(request,"yard/logon.html")
def logon(request):
    return HttpResponse("321");
def logout(request):
    return HttpResponse("321");

def index(request):
    #template = loader.get_template("yard/index.html")
    #context = RequestContext(request)
    return render(request,"yard/index.html")

def mainmenudata(request):
    return HttpResponse("主菜单")

def maintab(request):
    return render(request,"yard/MainTab.html")
def mainmenutreeview(request):
    return render(request,"yard/MainMenuTree.html")


def clients(request):
    #return render(request,"yard/basedata/clients.html",{'r':request})
    #增加 根据权限 判断是否有查询功能 设置datagrid.url
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


    #print(cObj.writeUI())
    return render(request,"yard/basedata/clients.html",{'r':request,
                                                'id':idObj,
                                                'clientName':clientNameObj,
                                                'clientFlag':clientFlagObj,
                                                'customFlag':customFlagObj,
                                                'shipcorpFlag':shipcorpFlagObj,
                                                'yardFlag':yardFlagObj,
                                                'portFlag':portFlagObj,
                                                'financialFlag':financialFlagObj,
                                                'recTim':recTimObj,
                                                'remark':remarkObj})


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


def getCommonSearchTemplate(request):
    return render(request,"commonSearchTemplate.html")



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
def getclients3(request):
    ls_rtn = '''
        {"total": 2, "rows": [{"ship_corp_flag": "true", "financial_flag": "false", "port_flag": "false", "yard_flag": "false", "remark": "beizhu", "client_name": "外代", "id": 2, "client_flag": "true", "custom_flag": "true"}, {"ship_corp_flag": "true", "financial_flag": "false", "port_flag": "false", "yard_flag": "false", "remark": "beizhu", "client_name": "港湾", "id": 1, "client_flag": "false", "custom_flag": "true"}]}
    '''
    return HttpResponse(ls_rtn)

def syscod(request):
    id = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='id')
    fldEng = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='fld_eng')
    fldChi = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='fld_chi')
    codName = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='cod_name')
    fldExt1 = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='fld_ext1')
    fldExt2 = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='fld_ext2')
    seq = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='seq')
    remark = easyuihelp.EasyuiFieldUI(model=models.SysCode,field='remark')
    return render(request,"yard/sysdata/syscod.html",{'r':request,
                                                      'id':id,
                                                      'fldEng':fldEng,
                                                      'fldChi':fldChi,
                                                      'codName':codName,
                                                      'fldExt1':fldExt1,
                                                      'fldExt2':fldExt2,
                                                      'seq':seq,
                                                      'remark':remark
                                                      })
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

def contract(request):
    return render(request,'yard/contract/contract.html')