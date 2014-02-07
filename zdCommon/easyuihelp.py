__author__ = 'zhangtao'
from django.db import models
class EasyuiFieldUI:
    '''
    生成easyui datagrid的columns字段类
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
    #         'editor' : None
    #     }
    #     self.defaultAttribute()
    #     self..update(kwargs)

    def __init__(self,model=None,field=None,title=None,width=None,rowspan=None,colspan=None,
                 align='right',halign='center',sortable=None,order=None,resizable=None,
                 fixed=None,hidden=None,checkbox=None,formatter=None,styler=None,
                 sorter=None,editor=None,readonly=False):
        self.model = model
        self.field = field
        if (self.model is None or self.field is None):
            raise Exception("model和field参数不能为空")
        self.fObj = model._meta.get_field_by_name(self.field)[0]

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
        self.title = self.fObj.verbose_name
        self.align = 'right'
        self.halign = 'center'
        if (self.field.upper() == 'ID' or self.fObj.primary_key):
            self.hidden = True
        if isinstance(self.fObj,models.AutoField):
            self.hidden = True
        if isinstance(self.fObj,(models.IntegerField,
                                 models.BigIntegerField,
                                 models.SmallIntegerField,
                                 models.CommaSeparatedIntegerField)):
            self.editor = {
                'type':'numberbox'
            }
        if isinstance(self.fObj,(models.PositiveSmallIntegerField,
                                 models.PositiveIntegerField)):
            self.editor = {
                'type':'numberbox',
                'options':{
                    'min':0
                }
            }
        if isinstance(self.fObj,(models.DecimalField,models.FloatField)):
            self.editor = {
                'type':'numberbox',
                'options':{
                    'precision':2
                }
            }
        if isinstance(self.fObj,(models.BooleanField,
                                 models.NullBooleanField)):
            self.editor = {
                'type':'checkbox',
                'options':{
                    'on':'true',
                    'off':'false'
                }
            }
            self.formatter = '''function (value, rowData, rowIndex) {
                            if (value != null && String(value) == 'true') {
                                return '<input type="checkbox" disabled="true" value="true" checked="checked" />';
                            } else {
                                return '<input type="checkbox" disabled="true" value="false"/>';
                            }
                        }'''
        if isinstance(self.fObj,(models.DateField,)):
            self.editor = {
                'type':'datebox'
            }
        if isinstance(self.fObj,(models.DateTimeField,)):
            self.editor = {
                'type':'datetimebox'
            }
        if isinstance(self.fObj,(models.CharField,)):
            self.editor = {
                'type':'validatebox'
            }
        if (not (self.fObj.null and self.fObj.blank)):
            if self.editor is None:
                self.editor = {
                    'type':'validatebox',
                    'options':{
                        'required':'true'
                    }
                }
            else:
                if ('options' in self.editor):
                    self.editor.options.update({'required':'true'})
                else:
                    self.editor.update({'options':{
                      'required':'true'
                    }})

    def writeUI(self):
        strUI = "{field: '" + self.field + "',\n" + \
                "title: '" + self.title + "',\n" + \
                "align: '" + self.align + "',\n" + \
                "halign: '" + self.halign + "',\n"
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
