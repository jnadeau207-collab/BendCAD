from size import geo
for x in (0.30,0.32,0.35,0.38,0.40):
  for ha in (0.85,0.875,0.9,0.925,0.95):
    g=geo(12,1.75,x,35.0,ha)
    print(x,ha,'V=%.4f a=%.4f ra=%.4f rf=%.4f c=%.3f eps=%.3f sa=%.3f aw=%.3f xmin=%.3f'%(g['V']/1000,g['a'],g['ra'],g['rf'],g['c'],g['eps'],g['sa'],g['aw'],g['xmin']))
