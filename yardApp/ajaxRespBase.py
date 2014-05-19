__author__ = 'blaczom@163.com'

import json
from django.db import connection
from zdCommon.dbhelp import rawsql2json,rawsql4request
from zdCommon.utils import log, logErr
from zdCommon.dbhelp import  cursorExec2, json2upd
from django.http import HttpResponse, HttpResponseRedirect
from yard.settings import DOWNLOAD_PATH, DOWNLOAD_URL


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

def insert_filter(request,adict):
    l_rtn = { }
    for i_row in adict['rows']: #
        if i_row['op'] in ('insert'):
            i_row['cols'].update( { 'filter_owner': request.session['userid'] } )
    l_rtn.update( json2upd(adict) )
    return l_rtn
def getfilterhead(request):
    '''查询条件查询'''
    ls_sql = "select id,datagrid,filter_type,filter_name from s_filter_head " \
             "where (filter_type = 'G' or filter_owner = %s)" % (request.session['userid'])
    ldict = json.loads( request.POST['jpargs'] )
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))
def getfilterbody(request):
    '''查询体查询'''
    ldict = json.loads( request.POST['jpargs'] )
    ls_sql = "select " + ", ".join(ldict['cols']) + " from s_filter_body "
    return HttpResponse(json.dumps(rawsql2json(*rawsql4request(ls_sql, ldict)),ensure_ascii = False))


def exportExcel(request, adict):
    # 生成文件返回。
    l_rtn = {  "msg":"成功",  "stateCod": "004", "error": [""],
               "result": {"filepath":""}      #  成功返回文件下载路径，失败为空  stateCod -3
    }
    # 保存文件到static，然后返回url
    try:
        l_parm = adict['ex_parm']
        l_parm['title']  # : '文档标题', //如果非空，将第一行各列合并居中写入title
        l_parm['cols']   # :['列名1','列名2','列名3'], //列标题
        l_parm['rows']   # :[      ['行1列1','行1列2','行1列3'],       #         ['行2列1','行2列2','行2列3'],
        import uuid
        import xlsxwriter
        tt = uuid.uuid1().fields
        ls_fileName = str(tt[0]) + str(tt[3]) + str(tt[4]) + ".xlsx"
        ls_file = DOWNLOAD_PATH + ls_fileName
        workbook = xlsxwriter.Workbook(ls_file)
        worksheet = workbook.add_worksheet()
        # Widen the first column to make the text clearer.
        #worksheet.set_column('A:A', 20)
        # Add a bold format to use to highlight cells.
        #bold = workbook.add_format({'bold': True})
        # Write some simple text.
        worksheet.write('A1',l_parm['title'])
        # Text with formatting.              ..........  write( row, cols, content )
        for i in range(len(l_parm['cols'])):
            worksheet.write(1, i, l_parm['cols'][i])
        for i in range(len(l_parm['rows'] )):
            for j in range(len(l_parm['rows'][i])):
                worksheet.write(i + 2, j, l_parm['rows'][i][j])
        workbook.close()
        l_rtn.update({"result": DOWNLOAD_URL + ls_fileName} )
    except Exception as e:
        ls_err = str(e.args)
        l_rtn.update( {  "msg":"失败",  "stateCod": "-3", "error": [ls_err],
               "result": {"filepath":""}      #  成功返回文件下载路径，失败为空  stateCod -3
            } )

    return HttpResponse(json.dumps(l_rtn,ensure_ascii = False))

def exportExcelDirect(request, ldict):
    import io
    import xlsxwriter
    output = io.BytesIO()
    book = xlsxwriter.Workbook(output)
    sheet = book.add_worksheet('test')
    sheet.write(0, 0, 'Hello, world! aaa ')
    book.close()
    # construct response
    output.seek(0)
    #response = HttpResponse(output.read(), content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    response = HttpResponse(str(output.read()), content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    response['Content-Disposition'] = "attachment; filename=test.xlsx"
    return response