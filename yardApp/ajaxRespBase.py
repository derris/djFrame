__author__ = 'blaczom@163.com'

import json
from django.db import transaction, connection
from zdCommon.dbhelp import rawSql2JsonDict
from zdCommon.utils import log, logErr
from zdCommon.dbhelp import cursorSelect, cursorExec, cursorExec2, json2upd
from datetime import datetime
from django.http import HttpResponse

def update_user(request, adict):
    '''  change pass 密码  '''
    l_rtn = { }
    for i_row in adict['rows']: #
        if i_row['op'] in ('update', 'updatedirty'):
            i_row['cols'].pop("password")
        elif i_row['op'] in ('insert'):
            i_row['cols'].update( { 'password': 'ok' } )
    l_rtn.update( json2upd(adict) )
    return l_rtn

def logon(request):
    l_get = json.loads( request.POST['jpargs'] )
    ls_user = l_get["name"]
    ls_pass = l_get["password"]
    l_cur = connection.cursor()
    l_cur.execute("select id from s_user where username = %s and password = %s ", [ls_user, ls_pass ])
    l_rtn = {}
    if l_cur.cursor.rowcount > 0 :
        l_userid = l_cur.fetchone()[0]
        request.session['userid'] = l_userid
        request.session['logon'] = True
        l_rtn = { "stateCod" : 2, "msg": "登录成功。"}
    else:
        request.session['userid'] = ''
        request.session['logon'] = False
        l_rtn = { "stateCod": -2 , "msg": "登录失败，用户名不存在或者密码错误。"}
    return HttpResponse(json.dumps(l_rtn,ensure_ascii = False))


def logout(request):
    request.session['userid'] = ''
    request.session['logon'] = False
    return HttpResponse(json.dumps({ "stateCod": 3 },ensure_ascii = False))

# jpargs:{"func":"密码修改","ex_parm":{"oldpw":"ok","newpw":"123"}}
def changePassword(request,ldict):
    l_rtn = { "stateCod" : -2, "msg": "密码更改失败。"}
    l_userid =  request.session['userid']
    if l_userid > 0 :
        ls_newpass = ldict["ex_parm"]["newpw"]
        ls_oldpass = ldict["ex_parm"]["oldpw"]
        l_cur = connection.cursor()
        lrtn = cursorExec2("update s_user set password = %s where id = %s and password = %s ", [ls_newpass,l_userid, ls_oldpass])
        if lrtn > 0 :
            l_rtn = { "stateCod" : 202, "msg": "密码更改成功。"}
            return l_rtn
    return l_rtn
