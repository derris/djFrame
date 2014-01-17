__author__ = 'zhangtao'
from django.conf.urls import patterns, url
from yardApp import views
urlpatterns = patterns('',
    url(r'^client/$',views.client_index,name='clientindex'),
)