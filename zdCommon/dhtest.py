__author__ = 'dh'

import unittest

class autotest(unittest.TestCase):

    l_query1 =   {
                'page':1,
                'rows':12,
                'filter':"[{ 'cod':'client_name', 'operatorTyp':'等于', 'value':'值' }]",
                'sort':"[{ 'cod':'client_name', 'order_typ':'升序' }]"
            }
    l_query2 =   {
                'page':22,
                'rows':22,
                'filter':"[{ 'cod':'client_name', 'operatorTyp':'等于', 'value':'值' }, { 'cod':'client_name2', 'operatorTyp':'等于', 'value':'值2'}]",
                'sort':"[{ 'cod':'client1', 'order_typ':'升序' }, { 'cod':'client2', 'order_typ':'降序' }]"
            }

    l_query3 =   {
                'page':22,
                'rows':12
            }
    l_query = []
    l_query.append(l_query1)
    l_query.append(l_query2)
    l_query.append(l_query3)

    l_sql = []
    l_sql.append('select * from table1')
    l_sql.append('select * from table1 where c1 = a ')
    l_sql.append('select * from table1 where c1 = a and c2 = b order by id desc ')
    l_sql.append('select * from table1 where c1 = a  group by cc')
    l_sql.append('select * from table1 where c1 = a  group by cc, dd order by dd desc, c asc ')

    def test_rawsql4request(self):
        '''test dbhelp.py / rawsql4request'''
        import dbhelp
        import os
        for i_query in self.l_query:
            for i_sql in self.l_sql:
                print(dbhelp.rawsql4request(i_sql, i_query))
                print(os.linesep)
            #self.assertEqual(a, a)

    def test_insert(self):
        dict_test =   { 'reqtype':'insert', #      -----增加一个新字段。
           'rows': [{
                    'op': 'insert',
                    'table': 'c_client',
                    'cols': {'client_name':"", 'client_flag':"True", 'rec_nam':'1', 'rec_tim':"now()"},
                    'uuid': '234546',
                    'id': -1,
                    'subs': {}
                    }]
        }
        import dbhelp
        print(dbhelp.json2insert(dict_test))

insert into c_client(id, , , ,)
values(8, '外6', TRUE , '1', now());


if __name__ == '__main__':
    unittest.main()