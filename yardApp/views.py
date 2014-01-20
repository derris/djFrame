from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader,RequestContext

from yardApp import models
# Create your views here.
def client_index(request):

    template = loader.get_template("yard/clientindex.html")
    context = RequestContext(request)
    return HttpResponse(template.render(context))
def clientquery(request):
    return HttpResponse("客户查询")
