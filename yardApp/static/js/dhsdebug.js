/**
 * Created by Administrator on 14-3-22.
 */
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
                    {  $.messager.alert("注意", "只能选则相同的客户进行审核。");
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
                    {  $.messager.alert("注意", "22只能选则相同的客户进行审核。");
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
                var p = new sy.UUID();
                 $.messager.confirm("操作提示", "您确定要执行操作吗？系统将处理选中的费用，生成新的费用单据。", function (data) {
                    if (data) {
                        alert("确定" + p.toString());




                    }
                    else {
                        alert("用户取消核销。");
                    }
                });
            }

        }