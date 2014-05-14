__author__ = 'blaczom@163.com'

import json
from django.db import transaction, connection
from zdCommon.dbhelp import rawsql2json,rawsql4request,json2upd, rawSql2JsonDict
from zdCommon.utils import log, logErr
from zdCommon.dbhelp import cursorSelect, cursorExec, cursorExec2, json2upd
from datetime import datetime
from django.http import HttpResponse

def getContractDetail(request):
    ls_sql = "select id,bill_no,vslvoy,cargo_name,origin_place,client_id,cargo_piece,cargo_weight," \
             "cargo_volume,booking_date,in_port_date,return_cntr_date,custom_id,ship_corp_id,port_id," \
             "yard_id,finish_flag,finish_time,remark,contract_no,dispatch_place,custom_title1," \
             "custom_title2,landtrans_id,check_yard_id,unbox_yard_id,credit_id,cargo_type,cntr_freedays from contract"

    ldict = json.loads(request.POST['jpargs'])
    lrtn = rawsql2json(*rawsql4request(ls_sql, ldict))
    # lrtn 包含提单号、用于统计后续箱量。所有的提单号，用于统计所有箱量。
    ls_sqlsum = ''' select b.cntr_type  || ' X ' ||  sum(cntr_num) as showsum  from contract_cntr as A , c_cntr_type as B
                    where A.contract_id in ( %s )
                    and A.cntr_type = B.id
                    group by b.cntr_type
                '''
    ls_sumCheckCntr = ''' select b.cntr_type  || ' X ' ||  sum(check_num) as checksum  from contract_cntr as A , c_cntr_type as B
                where A.contract_id in ( %s )
                and A.cntr_type = B.id
                group by b.cntr_type
            '''
    ls_sql4action = ''' select action_name from  contract_action as A, c_contract_action as B
                        where  contract_id = %s and A.action_id = B.id order by B.sortno desc limit 1;
                    '''
    list_contrId = []
    for i in lrtn["rows"]:
        #get all the cntr in the bill
        l_sumCntr = rawSql2JsonDict(ls_sqlsum % str(i["id"])  )
        list_contrId.append(str(i["id"]))
        if len(l_sumCntr) > 0:
            ls = ";".join([x["showsum"] for x in l_sumCntr])
            i.update({ "cntr_sum": ls  })
        else:
            i.update({ "cntr_sum": "None"  })
        # get the last cntr action , as to say, have the biggest sortno of the c_cntr_action
        l_lastAction = rawSql2JsonDict(ls_sql4action % str(i["id"]) )
        if len(l_lastAction) > 0:
            ls = ";".join([x["action_name"] for x in l_lastAction])
            i.update({ "current_action": ls  })
        else:
            i.update({ "current_action": "None"  })
        # get the check cntr num from contract
        l_checkCntr = rawSql2JsonDict(ls_sumCheckCntr % str(i["id"]) )
        if len(l_checkCntr) > 0:
            ls = ";".join([x["checksum"] for x in l_checkCntr])
            i.update({ "check_num": ls  })
        else:
            i.update({ "check_num": "None"  })

    # get all the cntr for all the sum bill .
    ldict_sum = rawSql2JsonDict(ls_sqlsum % ( ",".join(list_contrId) ) )
    ldict_sumCheckCntr = rawSql2JsonDict(ls_sumCheckCntr % ( ",".join(list_contrId) ) )
    ls_sumCheck = "None"
    if len(ldict_sumCheckCntr) > 0 :
        ls_sumCheck = ";".join([x["checksum"] for x in ldict_sumCheckCntr])
    if len(ldict_sum) > 0 :
        ls_sumall = ";".join([x["showsum"] for x in ldict_sum])
        lrtn.update( { "footer" : [{"cntr_sum":ls_sumall , "bill_no": "合计", "check_num": ls_sumCheck } ] } )
    else:
        lrtn.update( { "footer" : [{"cntr_sum":"None" , "bill_no": "合计", "check_num": ls_sumCheck } ] } )
    # get all the cntr for check  from the contract.

    return HttpResponse(json.dumps(lrtn,ensure_ascii = False))

    '''   test:
    from zdCommon.dbhelp import rawSql2JsonDict
    a = rawSql2JsonDict(ls_sqlsum,[ "563178209" ])
   '''


def getBussSumary(request):
    '''
        业务汇总报表查询

    接收参数接口：
{
    func: '业务汇总报表查询',
    ex_parm: {
        client_id: '客户ID', //int型 客户id
        begindate: '还箱开始日期', //date型
        enddate: '还箱截止日期'} //date型
}
     func: '业务汇总报表查询'
查询条件：客户，还箱日期段。客户为空，查询全部客户，日期段不能空
查询内容：体积、箱量、查验箱量
分组：客户+货物分类+货名+产地
接收参数接口：

   select client_id, cargo_type, cargo_name  origin_place  cargo_volume   cntr_num   check_num
   from

     "rows": [
    {
        "client_id": 53, //客户ID
        "cargo_type": 2   //货物分类
        "cargo_name": 2 //货物名称,
        "origin_place": 1 //产地,
        "cargo_volume": "409.508" //体积,
        "cntr_num": "20GPX5,40GPX10",
        "check_num": "20GPX3,40GPX6"
    }
    ],
   "total": 1,
   "error": [],
   "msg": "查询完毕",
   "footer":[
        {"cntr_num":"20GPX5,40GPX10",
         "client_id":"合计",
         "check_num":"20GPX3,40GPX6"
        }]


        '''