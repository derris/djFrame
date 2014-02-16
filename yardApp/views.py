from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader,RequestContext
from django.views.decorators.http import require_http_methods

from django.core import serializers
import json

from zdCommon.jsonhelp import ServerToClientJsonEncoder
from zdCommon import easyuihelp
from zdCommon.dbhelp import rawsql2json, rawsql4request, json2insert


from yardApp import models

# Create your views here.
def logon(request):
    return render(request,"yard/logon.html")
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

#@require_http_methods(["GET", "POST"])
@csrf_exempt
def getClients(request):
    #return HttpResponse(serializers.serialize('json',models.Client.objects.all(),ensure_ascii = False))
    d = json.loads(serializers.serialize('json',
        models.Client.objects.raw("select id,client_name,"
                                  "case client_flag when true then 'true' else 'false' end client_flag,"
                                  "case custom_flag when true then 'true' else 'false' end custom_flag,"
                                  "case ship_corp_flag when true then 'true' else 'false' end ship_corp_flag,"
                                  "case yard_flag when true then 'true' else 'false' end yard_flag,"
                                  "case port_flag when true then 'true' else 'false' end port_flag,"
                                  "case financial_flag when true then 'true' else 'false' end financial_flag,"
                                  "remark from c_client"),ensure_ascii = False))
    t = []
    for item in d:
        item['fields']['id'] = item['pk']
        t.append(item['fields'])
    return HttpResponse(json.dumps({'total':2,'rows':t},ensure_ascii = False))
    #return HttpResponse('321')
def updateClients(request):
    s=json2insert(request.POST)
    print(s)
    return HttpResponse(str(s).replace("'", '"')) # js 不认识单引号。


def getCommonSearchTemplate(request):
    return render(request,"commonSearchTemplate.html")



#@csrf_exempt
def getclients2(request):
    ls_sql = "select id,client_name,client_flag,custom_flag, ship_corp_flag, yard_flag,port_flag,financial_flag,remark,rec_tim from c_client"
    #得到post的参数
    if request.method == 'GET':
        pass
    else:
        print('得到post参数', request.POST)
        if 'page' in dict(request.POST).keys():
            pass
        else:
            raise Exception('there is no page keys')

    jsonData = rawsql2json(*rawsql4request(ls_sql, request.POST))

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
        if 'page' in dict(request.POST).keys():
            pass
        else:
            raise Exception('there is no page keys')

    jsonData = rawsql2json(*rawsql4request(ls_sql, request.POST))

    # jsonData.update({ "msg": "", "stateCod":"" }) 可以在这里更新
    return HttpResponse(str(jsonData).replace("'", '"')) # js 不认识单引号。

def contract(request):
    return render(request,'yard/contract/contract.html')