__author__ = 'zhangtao'
from django.db import models
from yardApp.models import BaseModel

class Protocol(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    protocol_name = models.CharField('协议名称',max_length=50,unique=True)
    write_date = models.DateField('签订日期',blank=True,null=True)
    validate_date = models.DateField('有效日期',blank=True,null=True)
    def __str__(self):
        return self.protocol_name
    class Meta:
        db_table = 'p_protocol'
class FeeEle(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    ele_name = models.CharField('要素名称',max_length=30)
    init_data_sql = models.CharField('要素初始化sql语句',max_length=100,blank=True,null=True)
    def __str__(self):
        return self.ele_name
    class Meta:
        db_table = 'p_fee_ele'
class FeeEleLov(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    ele_id = models.ForeignKey('FeeEle',verbose_name='要素',related_name='ele_elelov',db_column='ele_id')
    lov_cod = models.CharField('要素内容代码',max_length=10)
    lov_name = models.CharField('要素内容名称',max_length=20)
    def __str__(self):
        return self.lov_name
    class Meta:
        db_table = 'p_fee_ele_lov'
