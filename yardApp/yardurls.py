__author__ = 'zhangtao'
from django.conf.urls import patterns, url
from yardApp import views
urlpatterns = patterns('',
    url(r'^logon/$',views.logon,name='logon'),
    url(r'^$',views.index,name='index'),
    url(r'^mainmenu/$',views.mainmenutreeview,name='mainmenu'),
    url(r'^clients/$',views.clients,name='clients'),
    url(r'^clients/getclients/$',views.getClients,name='getclients'),
    url(r'^clients/updateclients/$',views.updateClients,name='updateclients'),
    
    # 实验室
    url(r'^lab/$',"yardApp.lab.index", name='labindex'),
    url(r'^lab/getfunc/$',"yardApp.lab.getfunc", name='labgetfunc'),
    # http://127.0.0.1:8000/yard/lab/getfunc/?func=getJson1&&args=%22aaa%22
)
