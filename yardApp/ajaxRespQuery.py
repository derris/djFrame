__author__ = 'blaczom@163.com'

import json
from django.db import transaction, connection
from zdCommon.dbhelp import rawsql2json,rawsql4request,json2upd, rawSql2JsonDict
from zdCommon.utils import log, logErr
from zdCommon.dbhelp import cursorSelect, cursorExec, cursorExec2, json2upd
from datetime import datetime
from django.http import HttpResponse

def getContractDetail(request, ldict):
    ls_sql = "select id,bill_no,vslvoy,cargo_name,origin_place,client_id,cargo_piece,cargo_weight," \
             "cargo_volume,booking_date,in_port_date,return_cntr_date,custom_id,ship_corp_id,port_id," \
             "yard_id,finish_flag,finish_time,remark,contract_no,dispatch_place,custom_title1," \
             "custom_title2,landtrans_id,check_yard_id,unbox_yard_id,credit_id,cargo_type,cntr_freedays from contract"

    #ldict = json.loads(request.POST['jpargs'])
    lrtn = rawsql2json(*rawsql4request(ls_sql, ldict))
    if lrtn["total"] > 0 :
        pass
    else:
        return HttpResponse(json.dumps(lrtn,ensure_ascii = False))

    # lrtn 包含提单号、用于统计后续箱量。所有的提单号，用于统计所有箱量。
    ls_sqlsum = ''' select b.cntr_type  || ' X ' ||  sum(cntr_num) as showsum,  b.cntr_type  || ' X ' ||  sum(check_num) as checksum  from contract_cntr as A , c_cntr_type as B
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
            ls2 = ";".join([x["checksum"] for x in l_sumCntr])
            i.update({ "check_num": ls2  })
        else:
            i.update({ "cntr_sum": "None"  })
            i.update({ "check_num": "None"  })
        # get the last cntr action , as to say, have the biggest sortno of the c_cntr_action
        l_lastAction = rawSql2JsonDict(ls_sql4action % str(i["id"]) )
        if len(l_lastAction) > 0:
            ls = ";".join([x["action_name"] for x in l_lastAction])
            i.update({ "current_action": ls  })
        else:
            i.update({ "current_action": "None"  })



    # get all the cntr for all the sum bill .
    ldict_sum = rawSql2JsonDict(ls_sqlsum % ( ",".join(list_contrId) ) )
    ls_sumCheck = "None"
    if len(ldict_sum) > 0 :
        ls_sumCheck = ";".join([x["checksum"] for x in ldict_sum])
        ls_sumall = ";".join([x["showsum"] for x in ldict_sum])
        lrtn.update( { "footer" : [{"cntr_sum":ls_sumall , "bill_no": "合计", "check_num": ls_sumCheck } ] } )
    else:
        lrtn.update( { "footer" : [{"cntr_sum":"None" , "bill_no": "合计", "check_num": "None" } ] } )
    # get all the cntr for check  from the contract.

    return HttpResponse(json.dumps(lrtn, ensure_ascii = False))

    '''   test:
    from zdCommon.dbhelp import rawSql2JsonDict
    a = rawSql2JsonDict(ls_sqlsum,[ "563178209" ])
   '''


def getBussSumary(request, aDict):
    ls_time1 = str(aDict["ex_parm"]["begindate"])
    ls_time2 = str(aDict["ex_parm"]["enddate"])
    ls_clientid = str(aDict["ex_parm"]["client_id"]).strip(" ")
    ls_sqlclient = ""
    if len(ls_clientid) > 0:
        ls_sqlclient = " client_id = %s and "  % ls_clientid

    ls_sql = "select client_id, cargo_type, cargo_name,  origin_place,  sum(cargo_volume)" \
             " from contract where " + ls_sqlclient + \
            " return_cntr_date between '%s' and '%s' group by client_id, cargo_type, cargo_name, origin_place" % ( ls_time1, ls_time2)

    lrtn = rawsql2json(*rawsql4request(ls_sql, aDict))
    if lrtn["total"] > 0 :
        pass
    else:
        return HttpResponse(json.dumps(lrtn,ensure_ascii = False))

    ls_sqlsum = ''' select b.cntr_type  || ' X ' ||  sum(cntr_num) as showsum, b.cntr_type  || ' X ' ||  sum(check_num) as checksum   from contract_cntr as A , c_cntr_type as B
                    where A.contract_id in (select id from contract where client_id = %s and cargo_type  = %s and cargo_name = %s and origin_place = %s)
                    and A.cntr_type = B.id
                    group by b.cntr_type
                '''

    for i in lrtn["rows"]:
        #get all the cntr in the bill
        ls_cargoType = "0"
        ls_cargoName = "0"
        ls_originPlace = "0"
        if len(str(i["cargo_type"])) > 0:
            ls_cargoType = str(i["cargo_type"])
        if len(str(i["cargo_type"])) > 0:
            ls_cargoType = str(i["cargo_name"])
        if len(str(i["cargo_type"])) > 0:
            ls_cargoType = str(i["origin_place"])
        #l_sumCntr = rawSql2JsonDict(ls_sqlsum % (str(i["client_id"]),str(i["cargo_type"]),str(i["cargo_name"]),str(i["origin_place"])) )
        l_sumCntr = rawSql2JsonDict(ls_sqlsum % (str(i["client_id"]),ls_cargoType,ls_cargoName,ls_originPlace ))
        if len(l_sumCntr) > 0:
            ls = ";".join([x["showsum"] for x in l_sumCntr])
            ls2 = ";".join([x["checksum"] for x in l_sumCntr])
            i.update({  "cntr_sum": ls  , "check_num": ls2  })
        else:
            i.update({ "cntr_sum": "None",  "check_num": "None"   })

    # get all the cntr for all the sum bill .
    ls_sumcntr4footer =  ''' select b.cntr_type  || ' X ' ||  sum(cntr_num) as showsum,  b.cntr_type  || ' X ' ||  sum(check_num) as checksum  from contract_cntr as A , c_cntr_type as B
                        where  A.contract_id in  (select id from contract where %s  return_cntr_date between '%s' and '%s')
                        and A.cntr_type = B.id group by b.cntr_type  '''  % ( ls_sqlclient, ls_time1, ls_time2)
    ldict_sum = rawSql2JsonDict(ls_sumcntr4footer )
    ls_sumCheck = "None"
    if len(ldict_sum) > 0 :
        ls_sumCheck = ";".join([x["checksum"] for x in ldict_sum])
        ls_sumall = ";".join([x["showsum"] for x in ldict_sum])
        lrtn.update( { "footer" : [{"cntr_sum":ls_sumall , "client_id": "合计", "check_num": ls_sumCheck } ] } )
    else:
        lrtn.update( { "footer" : [{"cntr_sum":"None" , "client_id": "合计", "check_num": "None" } ] } )
    # get all the cntr for check  from the contract.
    return HttpResponse(json.dumps(lrtn, ensure_ascii = False))

