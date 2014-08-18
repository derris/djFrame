from yardApp.render import intfex

__author__ = 'zhangtao'
from django.conf.urls import patterns, url
from yardApp import ajaxResp


urlpatterns = patterns('',
    url(r'^$', intfex.index,name='index'),
    url(r'^logon/$',"yardApp.ajaxRespBase.logon",name='logon'),
    url(r'^logout/$',"yardApp.ajaxRespBase.logout",name='logout'),

    # 处理页面左边导航的功能。
    url('^dealmenureq/$', intfex.dealMenuReq,name='dealmenureq'),
    url('^dealPAjax/$', ajaxResp.dealPAjax,name='dealPAjax'),
    # 实验室
    url(r'^lab/$',"yardApp.lab.index", name='labindex'),
    url(r'^lab/getfunc/$',"yardApp.lab.getfunc", name='labgetfunc'),
    url(r'^lab/post/$',"yardApp.lab.getJsonPost", name='labpost'),
    url(r'^lab/test/$',"yardApp.lab.test", name='labtest'),
    # http://127.0.0.1:8000/yard/lab/getfunc/?func=getJson1&&args=%22aaa%22

)

#  yardurls.py --->  ajaxResp ---> function.