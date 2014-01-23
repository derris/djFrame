import json

from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader,RequestContext
from django.views.decorators.http import require_http_methods

from django.core import serializers


from zdCommon.jsonhelp import ServerToClientJsonEncoder
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

def mainmenutreeview(request):
    return render(request,"yard/MainMenuTree.html")


def clients(request):
    return render(request,"yard/basedata/clients.html",{'r':request})

#@require_http_methods(["GET", "POST"])
def getClients(request):
    #return HttpResponse(serializers.serialize('json',models.Client.objects.all(),ensure_ascii = False))
    d = json.loads(serializers.serialize('json',models.Client.objects.all(),ensure_ascii = False))
    t = []
    for item in d:
        item['fields']['id'] = item['pk']
        t.append(item['fields'])
    return HttpResponse(json.dumps({'total':2,'rows':t},ensure_ascii = False))
    #return HttpResponse('321')
def insertclients(request):
    return None