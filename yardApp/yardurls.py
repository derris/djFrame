__author__ = 'zhangtao'
from django.conf.urls import patterns, url
from yardApp import views
urlpatterns = patterns('',
    url(r'^logon/$',views.logon,name='logon'),
    url(r'^$',views.index,name='index'),
    url(r'^mainmenu/$',views.mainmenutreeview,name='mainmenu'),
    url(r'^commonsearch/$',views.getCommonSearchTemplate,name='commonsearchtemplate'),
    url(r'^clients/$',views.clients,name='clients'),
    url(r'^clients/getclients/$',views.getClients,name='getclients'),
    url(r'^clients/updateclients/$',views.updateClients,name='updateclients')
)