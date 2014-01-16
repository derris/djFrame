from django.db import models

# Create your models here.
class BaseModel(models.Model):
    ''''''
    remark = models.CharField('备注',blank=True,max_length=50,null=True)
    rec_nam = models.IntegerField('创建人员')
    rec_tim = models.DateTimeField('创建时间')
    upd_nam = models.IntegerField('修改人员',blank=True,null=True)
    upd_tim = models.DateTimeField('修改时间',blank=True,null=True)
    class Meta:
        abstract = True
class Client(BaseModel):
    id = models.IntegerField('pk',primary_key=True)
    client_name = models.CharField('客户名称',max_length=50,unique=True)
    client_flag = models.NullBooleanField('委托方标识')
    custom_flag = models.NullBooleanField('报关行标识')
    ship_corp_flag = models.NullBooleanField('船公司标识')
    yard_flag = models.NullBooleanField('场站标识')
    port_flag = models.NullBooleanField('码头标识')
    financial_flag = models.NullBooleanField('财务往来单位标识')
    def __str__(self):
        return self.client_name
    class Meta:
        db_table = 'c_client'
class Contract(BaseModel):
    id = models.IntegerField('pk',primary_key=True)
    bill_no = models.CharField('提单号',max_length=25,unique=True)
    cargo_name = models.CharField('货物名称',blank=True,max_length=30,null=True)
    origin_place = models.CharField('产地',blank=True,max_length=30,null=True)
    client_id = models.ForeignKey('Client',verbose_name='客户id')
    contract_type = models.ForeignKey('SysCode',verbose_name='委托类型')
    cargo_fee_type = models.ForeignKey('SysCode',verbose_name='货物费用计费类型')
    cargo_piece = models.IntegerField('货物件数',blank=True,null=True)
    cargo_weight = models.FloatField('货物重量',blank=True,null=True)
    cargo_volume = models.FloatField('货物体积',blank=True,null=True)
    booking_date = models.DateField('接单日期',blank=True,null=True)
    in_port_date = models.DateField('到港日期',blank=True,null=True)
    return_cntr_date = models.DateField('')
class ContractActionCod(BaseModel):
    id = models.IntegerField('pk',primary_key=True)
    action_name = models.CharField('委托计划名称',max_length=20,unique=True)
    def __str__(self):
        return self.action_name
    class Meta:
        db_table = 'c_contract_action'
class FeeCod(BaseModel):
    id = models.IntegerField('pk',primary_key=True)
    fee_name = models.CharField('费用名称',max_length=20,unique=True)
    protocol_flag = models.NullBooleanField('协议费用标识')
    def __str__(self):
        return self.fee_name
    class Meta:
        db_table = 'c_fee'
class FeeProtocol(BaseModel):
    id = models.IntegerField('pk',primary_key=True)
    client_id = models.ForeignKey('Client',verbose_name='客户ID')
    fee_id = models.ForeignKey('FeeCod',verbose_name='费用代码')
    contract_type = models.ForeignKey('SysCode',verbose_name='业务类型')
    fee_cal_type = models.ForeignKey('SysCode',verbose_name='计费方式')
    rate = models.FloatField('费率')
    free_day = models.SmallIntegerField('免费天数',blank=True,null=True)
    class Meta:
        db_table = 'c_fee_protocol'
class SysCode(BaseModel):
    id = models.IntegerField('pk',primary_key=True)
    fld_eng = models.CharField('英文字段名',max_length=20)
    fld_chi = models.CharField('中文字段名',max_length=30)
    cod_name = models.CharField('值名称',max_length=20)
    fld_ext1 = models.CharField('字段扩展值1',blank=True,max_length=20,null=True)
    fld_ext2 = models.CharField('字段扩展值2',blank=True,max_length=20,null=True)
    seq = models.SmallIntegerField('序号')
    def __str__(self):
        return self.fld_chi + ':' + self.cod_name
    class Meta:
        db_table = 'sys_code'
