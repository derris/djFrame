__author__ = 'Administrator'

import json

from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader,RequestContext
from django.views.decorators.http import require_http_methods

from django.core import serializers
from django.views.decorators.csrf import csrf_exempt

def index(request):
    return render(request,"lab/index.html")

@csrf_exempt
def getJson1(request):
    ls_rtn = '''
         [
            {"productid":"FI-SW-01","unitcost":10.00,"status":"P","listprice":16.50,"attr1":"Large","itemid":"EST-1"},
            {"productid":"K9-DL-01","unitcost":12.00,"status":"P","listprice":18.50,"attr1":"Spotted Adult Female","itemid":"EST-2"},
            {"productid":"RP-SN-01","unitcost":12.00,"status":"P","listprice":18.50,"attr1":"Venomless","itemid":"EST-3"},
            {"productid":"RP-LI-02","unitcost":12.00,"status":"P","listprice":18.50,"attr1":"Green Adult","itemid":"EST-5"},
            {"productid":"FL-DSH-01","unitcost":12.00,"status":"P","listprice":58.50,"attr1":"Tailless","itemid":"EST-6"},
            {"productid":"FL-DSH-01","unitcost":12.00,"status":"P","listprice":23.50,"attr1":"With tail","itemid":"EST-7"},
            {"productid":"FL-DLH-02","unitcost":12.00,"status":"P","listprice":93.50,"attr1":"Adult Female","itemid":"EST-8"},
            {"productid":"FL-DLH-02","unitcost":12.00,"status":"P","listprice":93.50,"attr1":"Adult Male","itemid":"EST-9"},
            {"productid":"RP-SN-01","unitcost":12.00,"status":"P","listprice":18.50,"attr1":"Rattleless","itemid":"EST-4"},
            {"productid":"AV-CB-01","unitcost":92.00,"status":"P","listprice":193.50,"attr1":"Adult Male","itemid":"EST-10"}
        ]
         '''
    return HttpResponse(ls_rtn)

def getfunc(request):
    ls_func = request.GET.get('func')
    ls_args = request.GET.get('args')
    ls_t = ls_func + '(request,' + ls_args + ')'
    print(ls_t)
    return eval(ls_t)