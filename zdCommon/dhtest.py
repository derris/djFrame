__author__ = 'dh'

import unittest
import json

class autotest(unittest.TestCase):
    jpargs =""" {   "reqtype":"query",
            "rows":20,
            "page":2,
            "cols":["col1","col2","col3"],
            "filter": [ {"cod": "colnam1", "operatorTyp": "等于","value": "CLI1"},
                        {"cod": "colnam2", "operatorTyp": "不等于","value": "CLI2"}
                      ] ,
            "sort": [ { "cod":"colsort1", "order_typ":"升序"},
                      { "cod":"colsort2", "order_typ":"降序"}
                    ]
        }
    """
    l_query1 = json.loads( jpargs)
    l_query2 =   { 'reqtype':'query', 'page':10, 'rows':-1   }
    l_query3 =   { 'reqtype':'query', 'page':100, 'rows':12   }
    l_query = []
    l_query.append(l_query1)
    l_query.append(l_query2)
    l_query.append(l_query3)

    l_sql = []
    l_sql.append('select * from table1')
    l_sql.append('select * from table1 where c1 = a ')
    l_sql.append('select * from table1 where c1 = a group by cc')
    l_sql.append('select * from table1 where c1 = a order by c2 asc ')
    l_sql.append('select * from table1 where c1 = a and  c2 <> 1')
    l_sql.append('select * from table1 where c1 = a and  c2 <> 1 order by c3 desc')
    l_sql.append('select * from table1 where c1 = a and  c2 <> 1 group by c3 having c2 > 0')
    l_sql.append('select * from table1 group by c3 having c2 > 0')
    l_sql.append('select * from table1 order by c2')
    l_sql.append('select * from table1 where c1 = a  group by cc, dd order by dd desc, c asc ')

    def test_rawsql4request(self):
        '''test dbhelp.py / rawsql4request'''
        import zdCommon.dbhelp
        import os
        for i_query in self.l_query:
            for i_sql in self.l_sql:
                print(zdCommon.dbhelp.rawsql4request(i_sql, i_query))
                print(os.linesep)
            #self.assertEqual(a, a)

    def test_insert(self):
        dict_test =   { 'reqtype':'update', #      -----增加一个新字段。
           'rows': [{
                    'op': 'insert',
                    'table': 'c_client',
                    'cols': {'client_name':"", 'client_flag':"True", 'rec_nam':'1', 'rec_tim':"now()"},
                    'uuid': '234546',
                    'id': -1,
                    'subs': {}
                    }]
        }
        import zdCommon.dbhelp
        print(zdCommon.dbhelp.json2insert(dict_test))

if __name__ == '__main__':
    unittest.main()