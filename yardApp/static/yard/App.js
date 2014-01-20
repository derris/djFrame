/// <reference path="../jquery-easyui/jquery-1.8.0.min.js" />
/// <reference path="../jquery-easyui/jquery.easyui.min.js" />


//**************全局对象管理******************
// 声明一个全局对象Namespace，用来注册命名空间
Namespace = new Object();

// 全局对象仅仅存在register函数，参数为名称空间全路径，如"Grandsoft.GEA"
Namespace.register = function (fullNS) {
    // 将命名空间切成N部分, 比如Grandsoft、GEA等
    var nsArray = fullNS.split('.');
    var sEval = "";
    var sNS = "";
    for (var i = 0; i < nsArray.length; i++) {
        if (i != 0) sNS += ".";
        sNS += nsArray[i];
        // 依次创建构造命名空间对象（假如不存在的话）的语句
        // 比如先创建Grandsoft，然后创建Grandsoft.GEA，依次下去
        sEval += "if (typeof(" + sNS + ") == 'undefined') " + sNS + " = new Object();"
    }
    if (sEval != "") eval(sEval);
}
//**************全局对象管理******************
//注册sy对象 自定义工具 空间
Namespace.register('sy');



//***************全局用到的对象**********************
/*
    sy.logonPath 登录窗口路径
    sy.searchWindowData 向通用查询窗口传入的列信息
    sy.searchWindowReturnData 由通用查询窗口返回的过滤和排序信息
* */
sy.logonPath = '';
sy.onLoadError = function(mes) {
    var defaultMsg = '系统错误,重新登录？';

    $.messager.confirm('提示', mes || defaultMsg, function (r) {
        if (r) {
            window.location.href = sy.logonPath;
        }
    });
}
sy.searchWindowUrl = '';
sy.searchWindow = undefined;
//sy.searchWindowSourceData = undefined;
sy.searchWindowData = [];
sy.searchWindowReturnData = {
    refreshFlag:false,
    filters: [],
    sorts : []
};
sy.createSearchWindow = function (datagrid) {
    sy.searchWindowData.length = 0;
    sy.searchWindowReturnData.filters.length = 0;
    sy.searchWindowReturnData.sorts.length = 0;
    sy.searchWindowReturnData.refreshFlag = false;
//  sy.searchWindowSourceData = datagrid;
    if (sy.searchWindow != undefined) {
        //console.info('not undefined');
        sy.searchWindow.window('destroy');
        sy.searchWindow = null;
    } else {
        //console.info('undefined');
    }
    var columns = datagrid.datagrid('options').columns;
    for (var j = 0 ; j < columns.length; j++) {
        for (var i = 0 ; i < columns[j].length; i++) {
            if (columns[j][i].hidden != true) {
                sy.searchWindowData.push({ cod: columns[j][i].field, text: columns[j][i].title, editor: columns[j][i].editor });
            }
        }
    }
    var columns = datagrid.datagrid('options').fitColumns;
    for (var j = 0 ; j < columns.length; j++) {
        for (var i = 0 ; i < columns[j].length; i++) {
            if (columns[j][i].hidden != true) {
                sy.searchWindowData.push({ cod: columns[j][i].field, text: columns[j][i].title, editor: columns[j][i].editor });
            }
        }
    }
   sy.searchWindow = $('<div></div>').window({
        href: sy.searchWindowUrl,
        title: '查询',
        width: window.innerWidth * 0.8,
        height: window.innerHeight * 0.8,
        modal: true,
        collapsible: false,
        minimizable: false,
        maximizable: false,
        closable: true,
        onClose: function () {
            //console.info('onClose');                        
            home.createsearchform.filterdatagrid = null;
            home.createsearchform.sorterdatagrid = null;
            sy.searchWindow.window('destroy');
            sy.searchWindow = null;
            if (sy.searchWindowReturnData.refreshFlag) {
                datagrid.datagrid('load', {
                    filter: sy.searchWindowReturnData.filters,
                    sort: sy.searchWindowReturnData.sorts
                });
            }
            //console.info(sy.searchWindowReturnData);
        }
    });
}
sy.createPopWindow = function (w,wUrl,t) {
    w = $('<div></div>').window({
        href: wUrl,
        title: t,
        width: window.innerWidth * 0.8,
        height: window.innerHeight * 0.8,
        modal: true,
        collapsible: false,
        minimizable: false,
        maximizable: false,
        closable: true,
        onClose: function () {
            w.window('destroy');
            w = null;            
        }
    });
}
//***************全局用到的对象**********************//



//***************扩展datagrid editor ****************
//1.datetimebox 日期时间选择


$.extend($.fn.datagrid.defaults.editors, {
    datetimebox: {
        init: function (container, options) {
            var editor = $('<input />').appendTo(container);
            options.editable = false;
            editor.datetimebox(options);
            return editor;
        },
        getValue: function (target) {
            return $(target).datetimebox('getValue');
        },
        setValue: function (target, value) {
            $(target).datetimebox('setValue',value);
        },
        resize: function (target, width) {
            $(target).datetimebox('resize',width);
        },
        destroy: function (target) {
            $(target).datetimebox('destroy');
        }
    }
});

//***************扩展datagrid editor ****************//

//***************扩展datagrid ***********************
$.extend($.fn.datagrid.defaults, {
    editRow: undefined,
    loader: function (param,success,error) {
        var that = $(this);
        var opts = that.datagrid('options');
        if (!opts.url) {
            return false;
        }
        $.ajax({
            url: opts.url,
            type: 'POST',
            data: JSON.stringify(param),
            contentType: 'application/json',
            dataType: 'json',
            success: function (r, t, a) {
                //console.info('success');
                $.ajaxSettings.success(r, t, a);                
                success(r);
            },
            error: function () {
                //console.info('error');
                error.apply(this,arguments);
            }
        });
    }
});
function my_01(_569) {
    //console.info(_569);
    console.info($.data(_569, "datagrid").originalRows);
}
$.extend($.fn.datagrid.methods, {
    getOriginalRows: function (jq) {
        //console.info($.data(jq, "datagrid"));
        return jq.each(function () {
            //console.info(this);
            my_01(this);
        });
    },
    //param {要插入对象}}
    insertData : function(jq,param){
        //console.info(jq.editRow);        
        if (jq.editRow == undefined) {
            null;
        } else {
            if (jq.datagrid('validateRow', jq.editRow)) {
                jq.datagrid('endEdit', jq.editRow);
            } else {
                return;
            }
        }
        jq.datagrid('insertRow', {
            index : 0,
            row : param
        });
        jq.datagrid('selectRow', 0);
        jq.datagrid('beginEdit', 0);
        jq.editRow = 0;
    },
    //param null
    deleteData: function (jq, param) {
        var selectRow = jq.datagrid('getSelected');
        var index = undefined;
        if (selectRow != null) {
            index = jq.datagrid('getRowIndex', selectRow);
            if (jq.editRow != undefined) {
                if (jq.editRow > index) {
                    jq.editRow = jq.editRow - 1;
                } else {
                    if (jq.editRow == index) {
                        if (jq.datagrid('validateRow', jq.editRow)) {
                            jq.datagrid('endEdit', jq.editRow);
                            jq.editRow = undefined;
                        } else {
                            return;
                        }
                    }
                }
            }
            jq.datagrid('deleteRow', index);
            if (jq.editRow != undefined) {
                jq.datagrid('selectRow', jq.editRow);
            }
        }
    },
    //param 为null
    redo: function (jq, param) {
        jq.editRow = undefined;
        jq.datagrid('rejectChanges');
        jq.datagrid('unselectAll');
    },
    //双击事件调用 先调用执行动态editor代码 再调用此函数 param 为onDblClickRow事件rowIndex
    dbClick: function (jq, param) {
        if (jq.editRow == undefined) {
            null;
        } else {
            if (jq.datagrid('validateRow', jq.editRow)) {
                jq.datagrid('endEdit',jq.editRow);
            } else {
                return;
            }
        }
        jq.editRow = param;
        jq.datagrid('beginEdit', param);
    },
    //单击事件调用, param 为onClickRow事件rowIndex
    click: function (jq, param) {
        if (jq.editRow != undefined) {
            if (jq.datagrid('validateRow', jq.editRow)) {
                jq.datagrid('endEdit', jq.editRow);
                jq.editRow = undefined;
            } else {
                jq.datagrid('unselectRow', param);
                jq.datagrid('selectRow', jq.editRow);
                return;
            }
        }
    },
    //手动对datagrid进行编辑完成操作，一般在‘确定’按钮中进行调用 param无传入值
    manualEndEdit: function (jq, param) {
        if (jq.editRow != undefined) {
            if (jq.datagrid('validateRow', jq.editRow)) {
                jq.datagrid('endEdit', jq.editRow);
                jq.editRow = undefined;
            } else {
                jq.datagrid('unselectAll');
                jq.datagrid('selectRow', jq.editRow);
                return;
            }
        }
    },

    //ajax提交之前调用，param 为null
    preSave: function (jq, param) {        
        if (jq.editRow == undefined) {
            return 1;            
        } else {
            if (jq.datagrid('validateRow', jq.editRow)) {
                jq.datagrid('endEdit', jq.editRow);
                jq.editRow = undefined;
                return 1;
            } else {
                return 0;
            }
        }
    },
    //ajax提交保存成功之后调用，param 为null
    afterSave: function (jq, param) {
        //将所有row的insert_flag字段设为false
        var rows = jq.datagrid('getChanges', 'inserted')
        $.each(rows,function(index,item){
            item.insert_flag = false;
        });
        jq.datagrid('acceptChanges');
    },
    //调用方式 datagrid('addEditor',[{field : 'column名称',editor : {type : 'text'}}]) 可传数组
    addEditor: function (jq, param) {
        if (param instanceof Array) {
            $.each(param, function (index, item) {
                var e = $(jq).datagrid('getColumnOption', item.field);
                e.editor = item.editor;
            });
        } else {
            var e = $(jq).datagrid('getColumnOption', param.field);
            e.editor = param.editor;
        }
    },
    //调用方式 datagrid('removeEditor',['column名称'])  可传数组
    removeEditor: function (jq, param) {
        if (param instanceof Array) {
            $.each(param, function (index, item) {
                var e = $(jq).datagrid('getColumnOption', item);
                e.editor = {};
            });
        } else {
            var e = $(jq).datagrid('getColumnOption', param);
            e.editor = {};
        }
    }

});
//***************扩展datagrid ***********************//

//***************扩展JQuery包装集函数************************
//将form表单值转换成Json格式
(function ($) {
    $.fn.serializeJson = function () {
        var serializeObj = {};
        var array = this.serializeArray();
        var str = this.serialize();
        $(array).each(function () {
            if (serializeObj[this.name]) {
                if ($.isArray(serializeObj[this.name])) {
                    serializeObj[this.name].push(this.value);
                } else {
                    serializeObj[this.name] = [serializeObj[this.name], this.value];
                }
            } else {
                serializeObj[this.name] = this.value;
            }
        });
        return serializeObj;
    };
})(jQuery);

(function ($) {

    /**
	 * Displays loading mask over selected element(s). Accepts both single and multiple selectors.
	 *
	 * @param label Text message that will be displayed on top of the mask besides a spinner (optional). 
	 * 				If not provided only mask will be displayed without a label or a spinner.  	
	 * @param delay Delay in milliseconds before element is masked (optional). If unmask() is called 
	 *              before the delay times out, no mask is displayed. This can be used to prevent unnecessary 
	 *              mask display for quick processes.   	
	 */
    $.fn.mask = function (label, delay) {
        $(this).each(function () {
            if (delay !== undefined && delay > 0) {
                var element = $(this);
                element.data("_mask_timeout", setTimeout(function () { $.maskElement(element, label) }, delay));
            } else {
                $.maskElement($(this), label);
            }
        });
    };

    /**
	 * Removes mask from the element(s). Accepts both single and multiple selectors.
	 */
    $.fn.unmask = function () {
        $(this).each(function () {
            $.unmaskElement($(this));
        });
    };

    /**
	 * Checks if a single element is masked. Returns false if mask is delayed or not displayed. 
	 */
    $.fn.isMasked = function () {
        return this.hasClass("masked");
    };

    $.maskElement = function (element, label) {

        //if this element has delayed mask scheduled then remove it and display the new one
        if (element.data("_mask_timeout") !== undefined) {
            clearTimeout(element.data("_mask_timeout"));
            element.removeData("_mask_timeout");
        }

        if (element.isMasked()) {
            $.unmaskElement(element);
        }

        if (element.css("position") == "static") {
            element.addClass("masked-relative");
        }

        element.addClass("masked");

        var maskDiv = $('<div class="loadmask"></div>');

        //auto height fix for IE
        if (navigator.userAgent.toLowerCase().indexOf("msie") > -1) {
            maskDiv.height(element.height() + parseInt(element.css("padding-top")) + parseInt(element.css("padding-bottom")));
            maskDiv.width(element.width() + parseInt(element.css("padding-left")) + parseInt(element.css("padding-right")));
        }

        //fix for z-index bug with selects in IE6
        if (navigator.userAgent.toLowerCase().indexOf("msie 6") > -1) {
            element.find("select").addClass("masked-hidden");
        }

        element.append(maskDiv);

        if (label !== undefined) {
            var maskMsgDiv = $('<div class="loadmask-msg" style="display:none;"></div>');
            maskMsgDiv.append('<div>' + label + '</div>');
            element.append(maskMsgDiv);

            //calculate center position
            maskMsgDiv.css("top", Math.round(element.height() / 2 - (maskMsgDiv.height() - parseInt(maskMsgDiv.css("padding-top")) - parseInt(maskMsgDiv.css("padding-bottom"))) / 2) + "px");
            maskMsgDiv.css("left", Math.round(element.width() / 2 - (maskMsgDiv.width() - parseInt(maskMsgDiv.css("padding-left")) - parseInt(maskMsgDiv.css("padding-right"))) / 2) + "px");

            maskMsgDiv.show();
        }

    };

    $.unmaskElement = function (element) {
        //if this element has delayed mask scheduled then remove it
        if (element.data("_mask_timeout") !== undefined) {
            clearTimeout(element.data("_mask_timeout"));
            element.removeData("_mask_timeout");
        }

        element.find(".loadmask-msg,.loadmask").remove();
        element.removeClass("masked");
        element.removeClass("masked-relative");
        element.find("select").removeClass("masked-hidden");
    };

})(jQuery);




//***************扩展JQuery**************************//

//***************设置Ajax默认参数********************

$.ajaxSetup({    
    async : false,
    success: function (r, t, a) {
        if (r.error_rows == undefined) {
            return;
        }
        var i = 0;
        var msg = '';
        var error_msg = '';
        for (i = 0; i < r.error_rows.length; i++) {
            error_msg = error_msg + r.error_rows[i] + '</br>';
        }
        for (i = 0; i < r.msg_rows.length; i++) {
            msg = msg + r.msg_rows[i] + '</br>';
        }
        if (msg.length == 0) {
            msg = r.msg;
        }
        if (error_msg.length == 0) {
            error_msg = r.msg;
        }
        if (r && r.success) {
            //小于10 系统级错误
            if (r.status < 10) {
                sy.onLoadError();
                return;
            }
            if (r.status > 30) { //正确
                $.messager.show({
                    title: '提示',
                    msg: msg,
                    timeout: 4000,
                    showType: 'slide'
                });
                return;
            }
            if (r.status > 10 && r.status < 20){
                //$.messager.alert('提示', error_msg);
                //sy.onLoadError();
            }
        } else {
            if (r && r.status < 10) {
                sy.onLoadError(error_msg);
                return;
            }
            $.messager.alert('提示',error_msg);
        }
    }   
});

//***************设置Ajax默认参数********************//

$.fn.datagrid.defaults.onLoadError = sy.onLoadError;
$.ajaxSettings.error = sy.onLoadError;

$(document).bind('ajaxStart', function (event) {    
    $('body').mask('加载数据......');
});

$(document).bind('ajaxStop', function () {    
    $('body').unmask();
});
