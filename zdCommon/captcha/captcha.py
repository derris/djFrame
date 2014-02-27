import os
from PIL import Image
import sys

codePath = os.path.split(__file__)[0]
if codePath[-1] != os.sep:
    codePath += os.sep
tmpPath = codePath + r'tmp' + os.sep
samPath = codePath + r'sam' + os.sep


class Captcha():  
    g_sam = []
    def __init__(self):
        if len(self.g_sam) < 5:
            for i in range(10):
                self.g_sam.append(Image.open(samPath + "%d.bmp" % i))
    
    def shortImage(self, aImage):    #afile 全路径，把图片搞到贴边。    
        im = aImage
        l_break = False
        l_x = l_y = 0
        for i in range(20):            
            for j in range(25):
                if im.getpixel((i,j)) > 100:  
                    pass
                else:
                    l_x = i
                    l_break = True
                    break
            if l_break: 
                break
        
        l_break = False
        for j in range(25):
            for i in range(20):
                if im.getpixel((i,j)) > 100:  
                    pass
                else:
                    l_y = j
                    l_break = True
                    break
            if l_break: 
                break    
        return(im.crop((l_x, l_y, 20, 25)))
        
    def compare(self, aImage):   # 对比模版，取出数据。
        im = aImage 
        l_sam = self.g_sam    
        for i in range(10):        
            l_sam.append(Image.open(samPath + "%d.bmp" % i))  # l_sam[0] ~ [9]      
            
        l_mark = dict( zip( [str(x) for x in range(10) ] , [0]*10 ))
        for i in range(10):        
            l_x = min( im.size[0], l_sam[i].size[0] )
            l_y = min( im.size[1], l_sam[i].size[1] )        
            l_mark[i] = 0
            for i_x in range(l_x):
                for i_y in range(l_y):
                    if l_sam[i].getpixel((i_x, i_y)) == im.getpixel((i_x, i_y)):
                        if l_sam[i].getpixel((i_x, i_y)) < 100:
                            l_mark[str(i)] += 1   # 对比评分
        l_rtn = sorted(l_mark.items(), key = lambda x: x[1], reverse = True ) # 分最高的那个。
        return(l_rtn[0][0])
        
    def getQdport(self, aFile):
        img = Image.open(aFile)
        ls = ""
        list_file = []
        for i in range(4): # 处理成4个
            l_img_tmp1 = shortImg(img.crop((i*20, 0, i*20+20, 25)).convert("L").point(lambda i: 255 if i > 120 else 1))        
            ls += str(compare( l_img_tmp1 ))        
        return(ls)
       
        