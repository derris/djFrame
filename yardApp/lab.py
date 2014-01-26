__author__ = 'Administrator'

import json

from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader,RequestContext
from django.views.decorators.http import require_http_methods

from django.core import serializers

def index(request):
    return render(request,"lab/index.html")