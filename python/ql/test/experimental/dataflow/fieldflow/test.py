import sys
import os

sys.path.append(os.path.dirname(os.path.dirname((__file__)))) # $ unresolved_call=os.path.dirname(..) unresolved_call=sys.path.append(..)
from testlib import *

# These are defined so that we can evaluate the test code.
NONSOURCE = "not a source"
SOURCE = "source"


def is_source(x):
    return x == "source" or x == b"source" or x == 42 or x == 42.0 or x == 42j


def SINK(x):
    if is_source(x):
        print("OK")
    else:
        print("Unexpected flow", x)


def SINK_F(x):
    if is_source(x):
        print("Unexpected flow", x)
    else:
        print("OK")


# ------------------------------------------------------------------------------
# Actual tests
# ------------------------------------------------------------------------------

class MyObj(object):
    def __init__(self, foo):
        self.foo = foo

    def setFoo(self, foo):
        self.foo = foo

def setFoo(obj, x):
    SINK_F(obj.foo)
    obj.foo = x

@expects(2) # $ unresolved_call=expects(..) unresolved_call=expects(..)(..)
def test_indirect_assign():
    myobj = MyObj("OK")

    setFoo(myobj, SOURCE)
    SINK(myobj.foo) # $ flow="SOURCE, l:-1 -> myobj.foo"


def test_indirect_assign_method():
    myobj = MyObj("OK")

    myobj.setFoo(SOURCE) # $ unresolved_call=myobj.setFoo(..)
    SINK(myobj.foo) # $ MISSING: flow


def test_direct_assign():
    myobj = MyObj(NONSOURCE)
    myobj.foo = SOURCE
    SINK(myobj.foo) # $ flow="SOURCE, l:-1 -> myobj.foo"


def test_direct_assign_overwrite():
    myobj = MyObj(NONSOURCE)
    myobj.foo = SOURCE
    myobj.foo = NONSOURCE
    SINK_F(myobj.foo)


def test_direct_if_assign(cond = False):
    myobj = MyObj(NONSOURCE)
    myobj.foo = SOURCE
    if cond:
        myobj.foo = NONSOURCE
        SINK_F(myobj.foo)
    SINK(myobj.foo) # $ flow="SOURCE, l:-4 -> myobj.foo"


@expects(2) # $ unresolved_call=expects(..) unresolved_call=expects(..)(..)
def test_direct_if_always_assign(cond = True):
    myobj = MyObj(NONSOURCE)
    myobj.foo = SOURCE
    if cond:
        myobj.foo = NONSOURCE
        SINK_F(myobj.foo)
    else:
        myobj.foo = NONSOURCE
        SINK_F(myobj.foo)
    SINK_F(myobj.foo)


def test_getattr():
    myobj = MyObj(NONSOURCE)
    myobj.foo = SOURCE
    SINK(getattr(myobj, "foo")) # $ flow="SOURCE, l:-1 -> getattr(..)"


def test_setattr():
    myobj = MyObj(NONSOURCE)
    setattr(myobj, "foo", SOURCE)
    SINK(myobj.foo) # $ flow="SOURCE, l:-1 -> myobj.foo"


def test_setattr_getattr():
    myobj = MyObj(NONSOURCE)
    setattr(myobj, "foo", SOURCE)
    SINK(getattr(myobj, "foo")) # $ flow="SOURCE, l:-1 -> getattr(..)"


def test_setattr_getattr_overwrite():
    myobj = MyObj(NONSOURCE)
    setattr(myobj, "foo", SOURCE)
    setattr(myobj, "foo", NONSOURCE)
    SINK_F(getattr(myobj, "foo"))


def test_constructor_assign():
    obj = MyObj(SOURCE)
    SINK(obj.foo) # $ flow="SOURCE, l:-1 -> obj.foo"


def test_constructor_assign_kw():
    obj = MyObj(foo=SOURCE)
    SINK(obj.foo) # $ flow="SOURCE, l:-1 -> obj.foo"


def fields_with_local_flow(x):
    obj = MyObj(x)
    a = obj.foo
    return a

def test_fields():
    SINK(fields_with_local_flow(SOURCE)) # $ flow="SOURCE -> fields_with_local_flow(..)"

# ------------------------------------------------------------------------------
# Nested Object
# ------------------------------------------------------------------------------

class NestedObj(object):
    def __init__(self):
        self.obj = MyObj("OK")

    def getObj(self):
        return self.obj


def test_nested_obj():
    x = SOURCE
    a = NestedObj()
    a.obj.foo = x
    SINK(a.obj.foo) # $ flow="SOURCE, l:-3 -> a.obj.foo"


def test_nested_obj_method():
    x = SOURCE
    a = NestedObj()
    a.getObj().foo = x # $ unresolved_call=a.getObj()
    SINK(a.obj.foo) # $ MISSING: flow

# ------------------------------------------------------------------------------
# Global scope
# ------------------------------------------------------------------------------

# since these are defined on global scope, and we still want to run them with
# `validTest.py`, we have them defined in a different file, and have hardcoded this
# number that reflects how many OK we expect to see ...  Not an ideal solution, but at
# least we know that the tests are actually valid.
#
# Notice that since the tests are run in a random order, we cannot split the global
# scope tests into multiple functions, since we wouldn't know which one did the initial
# import that does all the printing :|

@expects(18 + 2) # $ unresolved_call=expects(..) unresolved_call=expects(..)(..)
def test_global_scope():
    import fieldflow.test_global

    fieldflow.test_global.func_defined_before() # $ unresolved_call=fieldflow.test_global.func_defined_before()
    fieldflow.test_global.func_defined_after() # $ unresolved_call=fieldflow.test_global.func_defined_after()

# ------------------------------------------------------------------------------
# Global flow cases that doesn't work in this file, but works in test_global.py
# ------------------------------------------------------------------------------

# --------------------------------------
# using constructor
# --------------------------------------

# def test_constructor_assign():
obj2 = MyObj(SOURCE)
SINK(obj2.foo) # $ flow="SOURCE, l:-1 -> obj2.foo"

# apparently these if statements below makes a difference :O
# but one is not enough
cond = os.urandom(1)[0] > 128 # $ unresolved_call=os.urandom(..)

if cond:
    pass

# def test_constructor_assign():
obj2 = MyObj(SOURCE) # $ unresolved_call=MyObj(..)
SINK(obj2.foo) # $ unresolved_call=SINK(..) MISSING: flow="SOURCE, l:-1 -> obj2.foo"

if cond:
    pass

# def test_constructor_assign():
obj2 = MyObj(SOURCE) # $ unresolved_call=MyObj(..)
SINK(obj2.foo) # $ unresolved_call=SINK(..) MISSING: flow="SOURCE, l:-1 -> obj2.foo"

# def test_constructor_assign_kw():
obj3 = MyObj(foo=SOURCE) # $ unresolved_call=MyObj(..)
SINK(obj3.foo) # $ unresolved_call=SINK(..) MISSING: flow="SOURCE, l:-1 -> obj3.foo"

# def test_fields():
SINK(fields_with_local_flow(SOURCE)) # $ unresolved_call=fields_with_local_flow(..) unresolved_call=SINK(..) MISSING: flow="SOURCE -> fields_with_local_flow(..)"

# --------------------------------------
# method calls
# --------------------------------------

# def test_indirect_assign_method():
myobj2 = MyObj("OK") # $ unresolved_call=MyObj(..)
myobj2.setFoo(SOURCE) # $ unresolved_call=myobj2.setFoo(..)
SINK(myobj2.foo) # $ unresolved_call=SINK(..) MISSING: flow="SOURCE, l:-1 -> myobj2.foo"

# def test_nested_obj_method():
x2 = SOURCE
a2 = NestedObj() # $ unresolved_call=NestedObj()
a2.getObj().foo = x2 # $ unresolved_call=a2.getObj()
SINK(a2.obj.foo) # $ unresolved_call=SINK(..) MISSING: flow="SOURCE, l:-3 -> a2.obj.foo"
