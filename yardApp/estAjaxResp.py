__author__ = 'Administrator'

import unittest
from zdCommon.dbhelp import *

class MyTestCase(unittest.TestCase):
    def test_something(self):
        self.assertEqual(True, False)


if __name__ == '__main__':
    unittest.main()

class dataPack():
    '''
from yardApp.TestAjaxResp import dataPack
a = dataPack()
a.fillContr()
    '''
    def __init__(self):
        pass
    def fillContr(self):
        ls_ins = []
        ls_ins.append("insert into contract(id,bill_no,vslvoy,return_cntr_date,origin_place,custom_id,finish_time,booking_date,cargo_weight,port_id,cargo_name,ship_corp_id,cargo_volume,remark,cargo_piece,yard_id,in_port_date,finish_flag,client_id , rec_nam  , rec_tim ) values (9, 'bbbb','',null,'',null,null,null,null,null,'',null,null,'',null,null,null, false, '4', '1', '2014-04-17 17:23:21')" )
        ls_ins.append("insert into contract_action(action_id,remark,finish_flag,contract_id,finish_time , rec_nam  , rec_tim ) values ('1','','false','9','2014-04-17 17:31:44', '1', '2014-04-17 17:31:53') " )
        ls_ins.append("insert into contract_action(action_id,remark,finish_flag,contract_id,finish_time , rec_nam  , rec_tim ) values ('3','','false','9','2014-04-17 17:31:49', '1', '2014-04-17 17:31:53') ")
        ls_ins.append("insert into contract_cntr(remark,cntr_type,contract_id,cntr_num , rec_nam  , rec_tim ) values ('1','1','9','11', '1', '2014-04-17 17:40:50')" )
        ls_ins.append("insert into contract_cntr(remark,cntr_type,contract_id,cntr_num , rec_nam  , rec_tim ) values ('2','1','9','22', '1', '2014-04-17 17:40:50')")
        ls_ins.append("insert into contract_cntr(remark,cntr_type,contract_id,cntr_num , rec_nam  , rec_tim ) values ('11','2','9','11', '1', '2014-04-17 17:40:50')")
        ls_ins.append("insert into pre_fee(fee_financial_tim,amount,ex_feeid,client_id,fee_tim,fee_typ,fee_cod,remark,contract_id , rec_nam  , rec_tim ) values ('2014-04-17 00:00:00','22.00','O','4','2014-04-17 00:00:00','I','2','','9', '1', '2014-04-17 17:45:42')")
        ls_ins.append("insert into pre_fee(fee_financial_tim,amount,ex_feeid,client_id,fee_tim,fee_typ,fee_cod,remark,contract_id , rec_nam  , rec_tim ) values ('2014-04-17 00:00:00','44.00','O','4','2014-04-17 00:00:00','I','1','','9', '1', '2014-04-17 17:47:36')")
        try:
            with transaction.atomic():
                for i in ls_ins:
                    cursorExec(i)
        except Exception as e:
            raise e
