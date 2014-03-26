__author__ = 'zhangtao'
from django.conf.urls import patterns, url
from yardApp import views
from yardApp import renderviews, ajaxResp

urlpatterns = patterns('',
    url(r'^$',renderviews.indexview,name='index'),
    url(r'^logon/$',views.logon,name='logon'),
    url(r'^logout/$',views.logout,name='logout'),

    #url(r'^clients/getclients2/$',views.getclients2,name='getclients2'),
    #url(r'^clients/updateclients/$',views.updateClients,name='updateclients'),
    #url(r'^sysdata/getsysmenu/$',views.getsysmenu,name='getsysmenu'),
    # 处理页面左边导航的功能。
    url('^dealmenureq/$', renderviews.dealMenuReq,name='dealmenureq'),
    url('^dealPAjax/$', ajaxResp.dealPAjax,name='dealPAjax'),
    url('^dealPAjax/searchContractByBill/$', ajaxResp.searchContractByBill,name='searchContractByBill'),
    # 实验室
    url(r'^lab/$',"yardApp.lab.index", name='labindex'),
    url(r'^lab/getfunc/$',"yardApp.lab.getfunc", name='labgetfunc'),
    url(r'^lab/post/$',"yardApp.lab.getJsonPost", name='labpost'),
    # http://127.0.0.1:8000/yard/lab/getfunc/?func=getJson1&&args=%22aaa%22
)
