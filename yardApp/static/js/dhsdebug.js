/**
 * Created by Administrator on 14-3-22.
 */

function getSeqNo(aSeqNam)
{
    var l_rtn;
    $.post( "dealPAjax/",
            { jpargs:
                JSON.stringify({"func" : "取序列号", "ex_parm": {"seqnam":aSeqNam }})
            }  ,
            function(data,status){  l_rtn = data; }
    );
   if (l_rtn["stateCod"] < 0)
        return -1;
    else
        return l_rtn["result"]["seqno"]
}

 function checkRule(){
            var rows1 = $('#fee-prefeeaudit-actfee-datagrid').datagrid('getChecked');
			var l_client = ""
            var l_okActfee = true;
            var l_sumact = 0;
            for(var i=0; i<rows1.length; i++){
				var row = rows1[i];
                if (l_client.length < 1 ) {
                    l_client = row.client_id;
                }
                else {
                    if (row.client_id != l_client)
                    {  $.messager.alert("注意", "已收费用：只能选则相同的客户进行审核。");
                        l_okActfee = false;
                        return false;
                        break;
                    }
                }
                l_sumact = l_sumact + parseInt(row.amount);
			}
            $('#stat1').text( "已付费用：" +  l_sumact.toString() );
            var l_sumpre = 0;
            var l_okPreefee = true;
            var rows2 = $('#fee-prefeeaudit-prefee-datagrid').datagrid('getChecked');
			var l_client = ""
            var l_okActfee = true;
            for(var i=0; i<rows2.length; i++){
				var row = rows2[i];
                if (l_client.length < 1 )
                {
                    l_client = row.client_id;
                }
                else {
                    if (row.client_id != l_client)
                    {  $.messager.alert("注意", "应收费用：只能选则相同的客户进行审核。");
                        l_okPreefee = false;
                        return false;
                        break;
                    }
                }
                l_sumpre = l_sumpre + parseInt(row.amount);
			}
            $('#stat2').text( "应付费用：" +  l_sumpre.toString() );
            if (l_sumact > l_sumpre)
                $('#stat3').text( " 已付结余：" + (l_sumact - l_sumpre).toString() );
            else
                $('#stat3').text( " 还应付费用：" + (l_sumpre - l_sumact).toString() );

            // ajax 把费用都提交到后台。
            if ((rows1.length > 0 ) && (rows2.length > 0))
                return true;
            else
                return false;
        }
        function dealAudit()
        {
            //if (checkRule())
            {
                //var p = new sy.UUID();
                 $.messager.confirm("操作提示", "您确定要执行操作吗？系统将处理选中的费用，生成新的费用单据。", function (data) {
                    if (data) {

                 /*  考虑到安全问题，决定把这个整体的事物还是放到后台处理，前台不应该进行通用的update控制。
                        var l_seqNo = getSeqNo("seq_4_auditfee").toString();
                        var aj =  {'reqtype':'update'};
                        aj.rows = []
                        var rows1 = $('#fee-prefeeaudit-actfee-datagrid').datagrid('getChecked');
                        var l_sumpre = 0;
                        var l_sumact = 0;
                        for(var i=0; i<rows1.length; i++){
                            var row = rows1[i];
                            var l_aRow = {};
                            l_aRow.op = 'update';
                            l_aRow.table = "actfee";
                            l_aRow.cols = {'ex_over': [l_seqNo, 'old'] } ;
                            l_aRow.id = row.id;
                            aj.rows.push(l_aRow);
                        }
                        var rows2 = $('#fee-prefeeaudit-prefee-datagrid').datagrid('getChecked');
                        for(var i=0; i<rows2.length; i++){
                            var row = rows2[i];
                            var l_aRow = {};
                            l_aRow.op = 'update';
                            l_aRow.table = "prefee";
                            l_aRow.cols = {'ex_over': [l_seqNo, 'old'] } ;
                            l_aRow.id = row.id;
                            aj.rows.push(l_aRow);
                        }
                        var l_aInsRow = {};
                  */
                        var rows1 = $('#fee-prefeeaudit-actfee-datagrid').datagrid('getChecked');
                        var l_actId = [];
                        for(var i=0; i<rows1.length; i++)
                            l_actId.push(rows1[i].id);

                        var rows2 = $('#fee-prefeeaudit-prefee-datagrid').datagrid('getChecked');
                        var l_preId = [];
                        for(var i=0; i<rows2.length; i++)
                            l_preId.push(rows2[i].id);


                        var l_rtn;
                        $.post( "dealPAjax/",
                                { jpargs:
                                    JSON.stringify(
                                        {
                                            "func" : "处理已收费用核销",
                                            "ex_parm": {"actfeeid": l_actId , "prefeeid":l_preId}
                                        }
                                    )
                                }  ,
                                function(data,status){  l_rtn = data; }
                        );
                       if (l_rtn["stateCod"] < 0)
                            alert("处理失败：" + l_rtn["error"]);
                        else
                            alert("处理成功。" + l_rtn["msg"]);
                    }
                    else {
                        alert("用户取消核销。");
                    }
                });
            }

        }