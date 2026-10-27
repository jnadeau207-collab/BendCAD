import math
A = 22.05
XM = A / 2
RC = 12.6825
B = 35.0
LB = 35.05
ZG = 0.025
TF = 28.0
TP = 6.35
TR = 25.0
ZR = LB
BX0, BX1, BY = -21.0, 43.05, 35.0
SCREWS = [(-13.0, 23.0), (35.05, 23.0), (-13.0, -23.0), (35.05, -23.0)]
DOWELS = [(-4.0, 28.0), (26.05, -28.0)]
RI, RO, GD = 14.75, 18.28, 1.95
YREL = 2.312
def f(v):
    s = ('%.12f' % v).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s
def circle(x, y, r):
    return '(circle %s %s %s)' % (f(x), f(y), f(r))
def rect(x0, y0, x1, y1):
    return '(path %s %s (line %s %s) (line %s %s) (line %s %s))' % tuple(map(f, (x0, y0, x1, y0, x1, y1, x0, y1)))
def rrect(x0, y0, x1, y1, r):
    p = (x0 + r, y0, x1 - r, y0, x1 - r, y0 + r, r, x1, y0 + r, x1, y1 - r, x1 - r, y1 - r, r, x1 - r, y1,
         x0 + r, y1, x0 + r, y1 - r, r, x0, y1 - r, x0, y0 + r, x0 + r, y0 + r, r, x0 + r, y0)
    return ('(path %s %s (line %s %s) (arc %s %s %s %s %s ccw) (line %s %s) (arc %s %s %s %s %s ccw) '
            '(line %s %s) (arc %s %s %s %s %s ccw) (line %s %s) (arc %s %s %s %s %s ccw))') % tuple(map(f, p))
def fig8():
    y = math.sqrt(RC * RC - XM * XM)
    return '(path %s %s (arc 0 0 %s %s %s ccw) (arc %s 0 %s %s %s ccw))' % (f(XM), repr(y), f(RC), f(XM), repr(-y), f(A), f(RC), f(XM), repr(y))
def stadium(r):
    return '(path 0 %s (line %s %s) (arc %s 0 %s %s %s ccw) (line 0 %s) (arc 0 0 %s 0 %s ccw))' % (
        f(-r), f(A), f(-r), f(A), f(r), f(A), f(r), f(r), f(r), f(-r))
def flange():
    return ('(path -44 -44 (line -13 -44) (line -13 -53.2) (arc 0 -53.2 13 13 -53.2 ccw) (line 13 -44) (line 44 -44) '
            '(line 44 44) (line 13 44) (line 13 53.2) (arc 0 53.2 13 -13 53.2 ccw) (line -13 44) (line -44 44))')
