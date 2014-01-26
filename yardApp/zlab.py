__author__ = 'Administrator'
#用来测试实现方法的东东。。

import json

from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader,RequestContext
from django.views.decorators.http import require_http_methods

from django.core import serializers

def lab(request):
    return render(request,"lab/lab.html")