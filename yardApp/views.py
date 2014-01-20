from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader,RequestContext

from yardApp import models
# Create your views here.
def index(request):
    #template = loader.get_template("yard/index.html")
    #context = RequestContext(request)
    return render(request,"yard/index.html")

def clientquery(request):
    return HttpResponse("客户查询")
