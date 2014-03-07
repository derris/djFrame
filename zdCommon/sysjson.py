__author__ = 'dh'

from zdCommon.dbhelp import cursorSelect
from django.db import connection

def getMenuList():
    '''导航菜单 返回除根节点外的所有节点对象数组'''
    l_menu1 = cursorSelect('select id, menuname, menushowname from sys_menu where parent_id = 0 and id <> 0 order by sortno;')
    ldict_1 = []
    if len(l_menu1) > 0:  # 有1级菜单，循环读出到dict中。
        for i_m1 in l_menu1:
            l_menu2 = cursorSelect('select id,menuname, menushowname from sys_menu where parent_id = %d order by sortno;' % i_m1[0])
            ldict_2 = []
            if len(l_menu2) > 0 :
                for i_m2 in l_menu2:
                    ldict_2.append({"id": i_m2[0], "text": i_m2[2], "attributes": i_m2[1]})
            else:
                pass # no child
            ldict_1.append( { "id": i_m1[0], "text": i_m1[2], "attributes": i_m1[1], 'children': ldict_2  } )
    else:
        pass   # no top menu ... how that posible ....
    return(ldict_1)

def getMenuPrivilege(aPostid):
    l_postid = int(aPostid)
    l_func = dict(cursorSelect('select id, funcname from sys_func'))
    #l_funcid = [i[0] for i in l_func]       # 得到功能id 的list
    #l_funcname = [i[1] for i in l_func]       # 得到功能名称 的list

    l_menu1 = cursorSelect('select id, menuname, menushowname from sys_menu where parent_id = 0 and id <> 0 order by sortno;')
    ldict_1 = []
    if len(l_menu1) > 0:  # 有1级菜单，循环读出到dict中。
        for i_m1 in l_menu1:
            l_menu2 = cursorSelect('select id,menuname, menushowname from sys_menu where parent_id = %d order by sortno;' % i_m1[0])
            ldict_2 = []
            if len(l_menu2) > 0 :
                for i_m2 in l_menu2:
                    l_menu3 = cursorSelect('select id, func_id from sys_menu_func where menu_id = %d' % i_m2[0])  # menu下的func功能。
                    ldict_3 = []
                    if len(l_menu3) > 0 :
                        for i_m3 in l_menu3:   # 列出menu下的func权限，看看当前post有没有这个权限。
                            l_oldval = "false"
                            l_countfunc = cursorSelect('select count(1) from s_postmenufunc where post_id=%d and menu_id=%d and func_id=%d' % (l_postid, i_m2[0], i_m3[0]))  # menu下的func功能。
                            if l_countfunc[0][0] > 0 :
                                l_oldval = "true"
                            l_attr = { "type": "func", "id": str(i_m3[0]), "oldval": l_oldval }
                            l_id = "m" + str(i_m2[0]) + "f" + str(i_m3[0])
                            ldict_3.append( { "id": l_id, "text": l_func[i_m3[1]], "checked": False, "attributes": l_attr } )   #把菜单有的权限列出来
                    else:
                        pass

                    l_oldval = "false"
                    l_countmenu2 = cursorSelect('select count(1) from s_postmenu where post_id=%d and menu_id=%d' % (l_postid, i_m2[0]))  # menu下的func功能。
                    if l_countmenu2[0][0] > 0 :
                        l_oldval = "true"
                    l_attr = { "type": "menu", "id": str(i_m2[0]), "oldval": l_oldval }
                    ldict_2.append({"id": i_m2[0], "text": i_m2[2], "attributes": l_attr, "children": ldict_3 , "checked": l_oldval  }  )
            else:
                pass # no child
            l_oldval = "false"
            l_countmenu1 = cursorSelect('select count(1) from s_postmenu where post_id=%d and menu_id=%d' % (l_postid, i_m2[0]))  # menu下的func功能。
            if l_countmenu1[0][0] > 0 :
                l_oldval = "true"
            l_attr = { "type": "menu", "id": str(i_m1[0]), "oldval": l_oldval }
            ldict_1.append( { "id": i_m1[0], "text": i_m1[2], "attributes": l_attr, 'children': ldict_2, "checked": l_oldval  } )
    else:
        pass   # no top menu ... how that posible ....
    return(ldict_1)

def setMenuPrivilege(aJson):
    '''
    这样传有没有问题？
    jpargs: {  'reqtype':'update'      ----- insert 功能发起。
       'rows': [ {
                'op': 'insert',   / "delete"      // 添加 或者 取消授权。   显示 或者 隐藏 菜单。
                'table': 'menu',   /  'func'
                'menuid' : mid
                "funcid' : fid
                "postid", : pid
            },]
        ｝
    #-----------------------------或者这样。------------------
    jpargs: {  'reqtype':'sysfunc'      ----- insert 功能发起。
       'rows': [ {
                'op': 'change',
                'func': 'menufuncpost',   /  'func'
                "newval" :  "true" / "false"
                "oldval" : "true" / "false"
                'menuid' : mid
                "funcid' : fid
                "postid", : pid            },]             ｝
    '''
    l_rtn = {   "error": [""],
                "msg":"",
                "stateCod":  0 ,
                "effectnum": 0 ,
                "changeid" : {'uuid1':'id1'} }
    l_JsonRows = aJson['rows']
    lb_err  = False
    li_count = 0
    try:
        l_cur = connection.cursor()
        for i_row in  l_JsonRows:
            ls_sql = ""
            if i_row['newval'] == True:      # insert
                pass
                ls_sql = "insert into sys_postmenufunc()"
            else:
                ls_sql = "delete from sys_postmenufunc where"
                l_cur.execute(ls_sql)
                li_count += l_cur.cursor.rowcount
    except Exception as e:
        l_rtn["error"].append("注意：" + str(e.args))
        lb_ok = False
    finally:
        l_cur.close()
    if lb_err :
        l_rtn["msg"] = "执行失败。"
        l_rtn["stateCod"] = -1
    else:
        l_rtn["msg"] = "执行成功。"
        l_rtn["stateCod"] = 202
    l_rtn["effectnum"] = str(li_count)
    return(l_rtn)

