__author__ = 'dh'

from zdCommon.dbhelp import cursorSelect


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

def getMenuPrivilege():
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
                    l_menu3 = cursorSelect('select id, func_id from sys_menu_func where menu_id = %d' % i_m2[0])
                    ldict_3 = []
                    if len(l_menu3) > 0 :
                        for i_m3 in l_menu3:

                            ldict_3.append({ "id": "m" + str(i_m2[0]) + "f" + str(i_m3[0]), "text": l_func[ i_m3[1] ] , "checked": False })   #把菜单有的权限列出来
                            # cursorSelect('select count() from sys_postmenufunc where menu_id = %d and func_id = %d' % (i_m2[0], ixxx ) )
                            # 有则check \== true
                    else:
                        pass
                    ldict_2.append({"id": i_m2[0], "text": i_m2[2], "attributes": i_m2[1], "children": ldict_3 , "checked": False  }  )
            else:
                pass # no child
            ldict_1.append( { "id": i_m1[0], "text": i_m1[2], "attributes": i_m1[1], 'children': ldict_2, "checked": False  } )
    else:
        pass   # no top menu ... how that posible ....
    return(ldict_1)