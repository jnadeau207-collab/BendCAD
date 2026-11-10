#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <stdint.h>
typedef struct { double lo, hi; } I;
static inline double up(double x){ return nextafter(x, INFINITY); }
static inline double dn(double x){ return nextafter(x, -INFINITY); }
static inline I iadd(I a, I b){ return (I){dn(a.lo+b.lo), up(a.hi+b.hi)}; }
static inline I isub(I a, I b){ return (I){dn(a.lo-b.hi), up(a.hi-b.lo)}; }
static inline I imul(I a, I b){
  double p1=a.lo*b.lo,p2=a.lo*b.hi,p3=a.hi*b.lo,p4=a.hi*b.hi;
  return (I){dn(fmin(fmin(p1,p2),fmin(p3,p4))), up(fmax(fmax(p1,p2),fmax(p3,p4)))};
}
static inline I comb(I a, I b, I t){ return iadd(a, imul(t, isub(b, a))); }
static inline double fc(double a,double b,double t){ return a+t*(b-a); }
typedef struct L { I v; struct L *n; } L;
static L *cons(I v, L *n){ L *c=malloc(sizeof(L)); c->v=v; c->n=n; return c; }
static void drop(L *l){ while(l){ L *n=l->n; free(l); l=n; } }
static L *lvl(L *cs, I t){ if(!cs||!cs->n) return NULL; return cons(comb(cs->v, cs->n->v, t), lvl(cs->n, t)); }
int main(int argc, char **argv){
  int mode=argc-1; long n=4000000; double acc=0, t=0;
  if(mode==0){ double a=1,b=2.5,c=0.5,d=3; for(long i=0;i<n;i++){ double p=fc(a,b,t),q=fc(b,c,t),r=fc(c,d,t); acc+=fc(fc(p,q,t),fc(q,r,t),t); t+=1e-8; } }
  else if(mode==1){ I a={1,1},b={2.5,2.5},c={0.5,0.5},d={3,3}; for(long i=0;i<n;i++){ I T={t,t}; I p=comb(a,b,T),q=comb(b,c,T),r=comb(c,d,T); acc+=comb(comb(p,q,T),comb(q,r,T),T).lo; t+=1e-8; } }
  else { L *cs=cons((I){1,1},cons((I){2.5,2.5},cons((I){0.5,0.5},cons((I){3,3},NULL)))); for(long i=0;i<n;i++){ I T={t,t}; L *a=lvl(cs,T),*b=lvl(a,T),*c=lvl(b,T); acc+=c->v.lo; drop(a);drop(b);drop(c); t+=1e-8; } }
  printf("%.17g\n", acc); return 0;
}
