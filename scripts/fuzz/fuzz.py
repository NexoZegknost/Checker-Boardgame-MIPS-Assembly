"""Random games checked against the reference model in ref.py.

The model plays a random game (with some illegal attempts mixed in), the same
keystrokes are piped into the MIPS program, and every board the program prints
must match the model's board.

    python3 scripts/fuzz/fuzz.py 0 20                    # seeds 0..19, base rules
    python3 scripts/fuzz/fuzz.py 0 20 --cfg russian --list --persp 2

--cfg picks a rule set from CONFIGS, --list uses the pick-from-list entry mode,
--persp is the point-of-view setting (0, 1 or 2). Needs tools/Mars.jar.
"""
import sys, random, subprocess, re, os
from ref import G
ROOT=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC=os.path.join(ROOT,'src')
MARS=os.environ.get('MARS_JAR', os.path.join(ROOT,'tools','Mars.jar'))
PROMPTS=["Enter starting square: ","Enter landing square: ","> ","Choose a piece: ","Your choice: "]

def play(seed, maxplies=120, bad=0.15, prefix=('1',), n=8, rows=3, flags=('promomid',), quit_cmd='q', persp=0, listmode=False):
    rnd=random.Random(seed); g=G(n,rows,flags)
    inp=list(prefix); boards=[g.plain()]; over=False
    U=lambda p: (g.total+1-g.sq[p]) if (persp==2 and g.turn=='r') else g.sq[p]
    for _ in range(maxplies):
        L=g.legal()
        if not L: over=True; break
        if g.quiet>=80: over=True; break
        if not listmode and g.chain is None and rnd.random()<bad:
            a=rnd.randint(0,g.total+2); b=rnd.randint(0,g.total+2)
            ok=any(U(x[0])==a and U(x[1])==b for x in L)
            if not ok: inp+= [str(a),str(b)] if any(U(x[0])==a for x in L) else [str(a)]
        if not listmode and g.chain is not None and rnd.random()<bad:
            b=rnd.randint(0,g.total+2)
            if not any(U(x[1])==b for x in L): inp.append(str(b))
        st=rnd.choice(L)
        if g.chain is None: inp.append(str(U(st[0])))
        if listmode:
            if rnd.random()<bad: inp.append(str(len([x for x in L if x[0]==st[0]])+1))
            inp.append(str([x for x in L if x[0]==st[0]].index(st)+1))
        else: inp.append(str(U(st[1])))
        g.apply(st); boards.append(g.plain(persp>=1 and g.turn=='r'))
    if not over: inp.append(quit_cmd)
    if over: inp.append('')
    inp.append('0')
    return g,inp,boards,over

def run(inp):
    r=subprocess.run(['java','-jar',MARS,'nc','sm','p','main.asm'],cwd=SRC,input='\n'.join(inp)+'\n',capture_output=True,text=True,timeout=600)
    return r.stdout

def boards_of(out,n):
    for p in PROMPTS: out=out.replace(p,'')
    lines=[l for l in out.split('\n') if re.fullmatch(r'[ 0brBRx]+',l) and l.strip()]
    return [lines[i:i+n] for i in range(0,len(lines),n)]

# name: (keys typed in the settings menu, board size, rows of men, model flags)
INTL=('must','max','flying','menback','deferred')
CONFIGS={
 'base':    ([], 8,3,('promomid',)),
 'english': (['4'], 8,3,('promomid','must')),
 'intl':    (['4','4'], 10,4,INTL),
 'brazil':  (['4','4','4'], 8,3,INTL),
 'russian': (['4','4','4','4'], 8,3,('must','flying','menback','deferred','promomid')),
 'big15':   (['6','1','0'], 10,3,('promomid',)),
 'big20must': (['6','1','1','2','0'], 10,4,('promomid','must')),
 # custom mixes: optional capture with flying kings, men moving backwards, ...
 'flyopt':  (['6','4','0'], 8,3,('promomid','flying')),
 'backmove':(['6','2','5','6','0'], 8,3,('promomid','must','menback','menbackmove')),
 'crownlate':(['6','2','7','0'], 8,3,('must',)),
 'late':    (['6','8','4','5','0'], 8,3,('promomid','deferred','flying','menback')),
 'longonly':(['6','3','0'], 8,3,('promomid','must','max')),
}
if __name__=='__main__':
    import argparse
    ap=argparse.ArgumentParser(); ap.add_argument('a',type=int); ap.add_argument('b',type=int)
    ap.add_argument('--persp',type=int,default=0); ap.add_argument('--list',action='store_true')
    ap.add_argument('--cfg',default='base'); ap.add_argument('--plies',type=int,default=120)
    A=ap.parse_args(); fails=0
    cset,n,rows,flags=CONFIGS[A.cfg]
    pre=['2']+['2']*A.persp+(['3'] if A.list else [])+cset+['0','1']
    for seed in range(A.a,A.b):
        g,inp,boards,over=play(seed,maxplies=A.plies,prefix=pre,persp=A.persp,listmode=A.list,n=n,rows=rows,flags=flags)
        out=run(inp); got=boards_of(out,g.n)
        if got!=boards:
            fails+=1; print('MISMATCH seed',seed,len(got),len(boards))
            for i,(x,y) in enumerate(zip(got,boards)):
                if x!=y: print('first diff at board',i); print('\n'.join(x)); print('--want'); print('\n'.join(y)); break
            open(os.path.join(os.path.dirname(__file__),f'fail_{seed}.in'),'w').write('\n'.join(inp)+'\n')
        else: print('ok',seed,'plies',len(boards)-1,'over',over, out.strip().split('\n')[-1][:60])
    sys.exit(1 if fails else 0)
