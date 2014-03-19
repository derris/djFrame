__author__ = 'zhangtao'
from django.db import models


class EasyuiFieldUI:
    '''
    生成easyui datagrid的columns字段类 通过writeUI方法写出
    初始化参数：
    model:django.db.models.model类型 字段所属model 必填
    field:字符 model中字段名称
    title:字符 列标题
    width:数值 列显示宽度,
    rowspan:数值 列跨行数
    colspan:数值 列跨列数,
    align:字符('left','right','center') 列对齐
    halign:字符('left','right','center') 列标题对齐
    sortable:布尔 列可排序
    order:字符('asc','desc') 排序方式
    resizable:布尔 是否允许调整列尺寸
    fixed:布尔 冻结列是否冻结
    hidden:布尔 是否隐藏列
    checkbox:布尔 列是否为checkbox类型
    formatter:字符 javascript函数，格式化显示
    styler:字符 javascript函数，列style,
    sorter:字符 javascript函数，本地排序函数,
    editor:对象 列editor
    readonly：布尔 False设置editor为None
    autoforeign:布尔 True自动转换外键显示值，前台editor为combobox
    foreigndisplayfield:字符 关联外键的显示字段 combobox
    '''
    # def __init__(self,model=None,field=None,**kwargs):
    #     self.model = model
    #     self.field = field
    #     if (self.model is None or self.field is None):
    #         raise Exception("model和field参数不能为空")
    #     self.fObj = model._meta.get_field_by_name(field)[0]
    #     self.attributes = {
    #         'field' : self.field,
    #         'title' : None,
    #         'width' : None,
    #         'rowspan' : None,
    #         'colspan' : None,
    #         'align' : None,
    #         'halign' : None,
    #         'sortable' : None,
    #         'order' : None,
    #         'resizable' : None,
    #         'fixed' : None,
    #         'hidden' : None,
    #         'checkbox' : None,
    #         'formatter' : None,
    #         'styler' : None,
    #         'sorter' : None,
    #         'editor' : None,
    #         'foreigndisplayfield':None
    #     }
    #     self.defaultAttribute()
    #     self..update(kwargs)

    def __init__(self, model=None, field=None, title=None, width=None, rowspan=None, colspan=None,
                 align=None, halign=None, sortable=None, order=None, resizable=None,
                 fixed=None, hidden=None, checkbox=None, formatter=None, styler=None,
                 sorter=None, editor=None, readonly=False, autoforeign=None,foreigndisplayfield=None):
        self.model = model
        self.field = field
        if (self.model is None or self.field is None):
            raise Exception("model和field参数不能为空")
        self.fObj = model._meta.get_field_by_name(self.field)[0]
        self.autoforeign = autoforeign
        self.foreigndisplayfield = foreigndisplayfield
        self.defaultAttribute()

        if title is not None:
            self.title = title
        if width is not None:
            self.width = width
        if rowspan is not None:
            self.rowspan = rowspan
        if colspan is not None:
            self.colspan = colspan
        if align is not None:
            self.align = align
        if halign is not None:
            self.halign = halign
        if sortable is not None:
            self.sortable = sortable
        if order is not None:
            self.order = order
        if resizable is not None:
            self.resizable = resizable
        if fixed is not None:
            self.fixed = fixed
        if hidden is not None:
            self.hidden = hidden
        if checkbox is not None:
            self.checkbox = checkbox
        if formatter is not None:
            self.formatter = formatter
        if styler is not None:
            self.styler = styler
        if sorter is not None:
            self.sorter = sorter
        if editor is not None:
            self.editor = editor
        self.readonly = readonly

    def defaultAttribute(self):
        '''
        根据字段类型设置默认的editor 默认隐藏field='id'的字段
        '''
        self.align = 'right'
        self.halign = 'center'
        self.sortable = True
        self.title = self.fObj.verbose_name
        if (self.field.upper() == 'ID' or self.fObj.primary_key):
            self.hidden = True
            return
        if isinstance(self.fObj, models.AutoField):
            self.hidden = True
            return
        if isinstance(self.fObj, (models.IntegerField,
                                  models.BigIntegerField,
                                  models.SmallIntegerField,
                                  models.CommaSeparatedIntegerField)):
            self.width = 50
            self.editor = {
                'type': 'numberbox'
            }
        if isinstance(self.fObj, (models.PositiveSmallIntegerField,
                                  models.PositiveIntegerField)):
            self.width = 50
            self.editor = {
                'type': 'numberbox',
                'options': {
                    'min': 0
                }
            }
        if isinstance(self.fObj, (models.DecimalField, models.FloatField)):
            self.width = 100
            self.editor = {
                'type': 'numberbox',
                'options': {
                    'precision': 2
                }
            }
        if isinstance(self.fObj, (models.BooleanField,
                                  models.NullBooleanField)):
            self.align = 'center'
            self.halign = 'center'
            self.width = len(self.title) * 18
            self.editor = {
                'type': 'checkbox',
                'options': {
                    'on': 'true',
                    'off': 'false'
                }
            }
            self.formatter = '''function (value, rowData, rowIndex) {
                            if (value != null && String(value) == 'true') {
                                return '<input type="checkbox" disabled="true" value="true" checked="checked" />';
                            } else {
                                return '<input type="checkbox" disabled="true" value="false"/>';
                            }
                        }'''
        if isinstance(self.fObj, (models.DateField,)):
            self.width = 100
            self.editor = {
                'type': 'datebox'
            }
        if isinstance(self.fObj, (models.DateTimeField,)):
            self.width = 180
            self.editor = {
                'type': 'datetimebox'
            }
        if isinstance(self.fObj, (models.CharField,)):
            columnWidth = len(self.title)
            #self.width = self.fObj.max_length * 5
            #self.width = columnWidth
            if self.fObj.choices is not None and len(self.fObj.choices) > 0:
                dataList = []
                for item in self.fObj.choices:
                    columnWidth = max(len(item[1]),columnWidth)
                    dataList.append({
                        'value':item[0],
                        'text':item[1]
                    })
                self.editor = {
                    'type': 'combobox',
                    'options': {
                        'valueField': 'value',
                        'textField': 'text',
                        'data': dataList
                    }
                }
                self.formatter = ''' function(value,rowData,index){
                                     for (var i = 0,ilen = this.editor.options.data.length; i < ilen ; i++){
                                         if (this.editor.options.data[i].value == value){
                                            return this.editor.options.data[i].text;
                                         }
                                     }
                                     return value;
                                }'''
            else:
                self.editor = {
                    'type': 'text'
                }
            self.width = columnWidth * 18
        if isinstance(self.fObj, (models.ForeignKey,)):
            columnWidth = len(self.title)
            if self.autoforeign is not None and self.autoforeign:
                dataList = []
                displayField = self.foreigndisplayfield or 'id'
                getData = None
                if (len(self.fObj.rel.limit_choices_to) > 0):
                    getData = self.fObj.rel.to.objects.filter(**self.fObj.rel.limit_choices_to)
                else:
                    getData = self.fObj.rel.to.objects.all()
                for item in getData:
                    if columnWidth < len(eval('item.' + displayField)):
                        columnWidth = len(eval('item.' + displayField))
                    dataList.append({
                        'value': item.id,
                        'text': eval('item.' + displayField)
                    })

                self.editor = {
                    'type': 'combobox',
                    'options': {
                        'valueField': 'value',
                        'textField': 'text',
                        'data': dataList
                    }
                }
                self.formatter = ''' function(value,rowData,index){
                                     for (var i = 0,ilen = this.editor.options.data.length; i < ilen ; i++){
                                         if (this.editor.options.data[i].value == value){
                                            return this.editor.options.data[i].text;
                                         }
                                     }
                                     return value;
                                }'''
            else:
                self.editor = {
                    'type': 'text'
                }
            self.width = columnWidth * 18

        if (not (self.fObj.null and self.fObj.blank)):
            if (('editor' not in self.__dict__) or self.editor is None):
                self.editor = {
                    'type': 'validatebox',
                    'options': {
                        'required': 'true'
                    }
                }
            else:
                if (self.editor['type'] == 'text'):
                    self.editor['type'] = 'validatebox'
                # if (self.editor['type'] == 'combobox'):
                #      pass
                if ('options' in self.editor):
                    self.editor['options'].update({'required': 'true'})
                else:
                    self.editor.update({'options': {
                        'required': 'true'
                    }})

    def writeUI(self):
        strUI = "{field: '" + self.field + "',\n" + \
                "title: '" + self.title + "',\n"
        if ('align' in self.__dict__):
            strUI = strUI + "align: '" + str(self.align) + "',\n"
        if ('halign' in self.__dict__):
            strUI = strUI + "halign: '" + str(self.halign) + "',\n"
        if ('width' in self.__dict__):
            strUI = strUI + "width: " + str(self.width) + ",\n"
        if ('colspan' in self.__dict__):
            strUI = strUI + "colspan: " + str(self.colspan) + ",\n"
        if ('rowspan' in self.__dict__):
            strUI = strUI + "rowspan: " + str(self.rowspan) + ",\n"
        if ('sortable' in self.__dict__ and self.sortable):
            strUI = strUI + "sortable: true,\n"
        if ('order' in self.__dict__):
            strUI = strUI + "order: '" + self.order + "',\n"
        if ('resizable' in self.__dict__ and self.resizable):
            strUI = strUI + "resizable: true,\n"
        if ('fixed' in self.__dict__ and self.fixed):
            strUI = strUI + "fixed: true,\n"
        if ('hidden' in self.__dict__ and self.hidden):
            strUI = strUI + "hidden: true,\n"
        if ('checkbox' in self.__dict__ and self.checkbox):
            strUI = strUI + "checkbox: true,\n"
        if ('formatter' in self.__dict__):
            strUI = strUI + "formatter: " + self.formatter + ",\n"
        if ('styler' in self.__dict__):
            strUI = strUI + "styler: " + self.styler + ",\n"
        if ('sorter' in self.__dict__):
            strUI = strUI + "sorter: " + self.sorter + ",\n"
        if ('editor' in self.__dict__ and (not self.readonly)):
            strUI = strUI + "editor: " + str(self.editor) + ",\n"
        strUI = strUI.strip().rstrip(',') + "}"
        return strUI

    # def writeUI(self):
    #     for key,value in self.attributes.items():
    #         if value is None:
    #             del self.attributes[key]
    #     return str(self.attributes)
    def __str__(self):
        return self.writeUI()
