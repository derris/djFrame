from django.shortcuts import render
from django.http import HttpResponse
# Create your views here.
def client_index(request):
    return HttpResponse("Hello, world. You're at the poll index.")