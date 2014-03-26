__author__ = 'dddh'

l_cacheUser = {}

def getCurUser():
    return("1")

class UserHelp:
    userName = "1"
    def __init__(self, aRequest):
        if aRequest:
            self.userName = ""
            self.loginTime = ""
        else:
            raise Exception("参数传递错误")
    def __str__(self):
        return(self.userName)
