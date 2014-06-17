__author__ = 'zhangtao'
from django.db import models
from yardApp.models import BaseModel,FeeCod
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

class FeeMod(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    mod_name = models.CharField('计费模式名称',max_length=20)
    col_1 = models.ForeignKey('FeeEle',verbose_name='要素1',related_name='ele_modcol1',db_column='col_1',blank=True,null=True)
    col_2 = models.ForeignKey('FeeEle',verbose_name='要素2',related_name='ele_modcol2',db_column='col_2',blank=True,null=True)
    col_3 = models.ForeignKey('FeeEle',verbose_name='要素3',related_name='ele_modcol3',db_column='col_3',blank=True,null=True)
    col_4 = models.ForeignKey('FeeEle',verbose_name='要素4',related_name='ele_modcol4',db_column='col_4',blank=True,null=True)
    col_5 = models.ForeignKey('FeeEle',verbose_name='要素5',related_name='ele_modcol5',db_column='col_5',blank=True,null=True)
    col_6 = models.ForeignKey('FeeEle',verbose_name='要素6',related_name='ele_modcol6',db_column='col_6',blank=True,null=True)
    col_7 = models.ForeignKey('FeeEle',verbose_name='要素7',related_name='ele_modcol7',db_column='col_7',blank=True,null=True)
    col_8 = models.ForeignKey('FeeEle',verbose_name='要素8',related_name='ele_modcol8',db_column='col_8',blank=True,null=True)
    col_9 = models.ForeignKey('FeeEle',verbose_name='要素9',related_name='ele_modcol9',db_column='col_9',blank=True,null=True)
    col_10 = models.ForeignKey('FeeEle',verbose_name='要素10',related_name='ele_modcol10',db_column='col_10',blank=True,null=True)
    mod_descript = models.CharField('模式自解析描述',max_length=500,blank=True,null=True)
    def __str__(self):
        return self.mod_name
    class Meta:
        db_table = 'p_fee_mod'
class ProtocolMod(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    protocol_id = models.ForeignKey('Protocol',verbose_name='协议',related_name='protocol_protocolmod',db_column='protocol_id')
    fee_id = models.ForeignKey('FeeCod',verbose_name='费用名称',related_name='fee_protocolmod',db_column='fee_id')
    mod_id = models.ForeignKey('FeeMod',verbose_name='模式',related_name='mod_protocolmod',db_column='mod_id')
    sort_no = models.IntegerField('序号',blank=True,null=True)
    class Meta:
        db_table = 'p_protocol_fee_mod'