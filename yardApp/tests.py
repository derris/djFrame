from django.test import TestCase
import unittest
from django.test import Client
class MyTestCase(unittest.TestCase):
    def test_something(self):
        self.assertEqual(True, True)

class MyTest2(unittest.TestCase):
    def test_something(self):
        response = Client().get('/')
        print(response.content)
        self.failUnlessEqual('abc', response.content)

if __name__ == '__main__':
    unittest.main()
