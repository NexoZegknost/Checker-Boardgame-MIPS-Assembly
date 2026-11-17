"""Random human (Black) against the MIPS computer player; every computer move
is checked for legality against the reference model.

    python3 scripts/fuzz/fuzz_ai.py <cfg> <level 1-3> <first seed> <last seed + 1>
"""
import sys, os, re, random, subprocess
from ref import G
from fuzz import SRC, MARS, CONFIGS

def game(seed, cfg, level, maxturns=60):
    cset,n,rows,flags=CONFIGS[cfg]
    rnd=random.Random(seed); g=G(n,rows,flags)
    p=subprocess.Popen(['java','-jar',MARS,'nc','sm','p','main.asm'],cwd=SRC,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
    buf=b''
    def send(x): p.stdin.write((x+'\n').encode()); p.stdin.flush()
    def until(pats):
        nonlocal buf
        while True:
            for pt in pats:
                if buf.endswith(pt.encode()):
                    out=buf.decode(); buf=b''; return out,pt
            ch=os.read(p.stdout.fileno(),4096)
            if not ch: raise RuntimeError('eof: '+buf.decode()[-300:])
            buf+=ch
    for x in ['2']+cset+['5']*level+['0','1']: send(x)
    P=["Enter starting square: ","Enter landing square: ","or press Enter to continue: "]
    result='unfinished'; turns=0
    def absorb(out):
        # apply the computer moves reported in this chunk of output
        for a,sep,b in re.findall(r'The computer plays (\d+)([-x])(\d+)\.',out):
            L=g.legal(); m=[x for x in L if g.sq[x[0]]==int(a) and g.sq[x[1]]==int(b)]
            if not m or (m[0][2] is not None)!=(sep=='x'):
                raise RuntimeError(f'illegal computer move {a}{sep}{b}; legal={[(g.sq[x[0]],g.sq[x[1]]) for x in L]}')
            assert g.turn=='r'
            g.apply(m[0])
    try:
        while turns<maxturns:
            out,pt=until(P); absorb(out)
            if pt==P[2]:
                result=[l for l in out.split('\n') if 'wins' in l or 'draw' in l][-1]; send(''); break
            L=g.legal()
            assert g.turn=='b' and L, (g.turn, out[-200:])
            st=rnd.choice(L)
            if pt==P[0]:
                assert g.chain is None
                send(str(g.sq[st[0]])); out,pt=until(P); assert pt==P[1], out[-200:]
            else: assert g.chain is not None, out[-300:]
            send(str(g.sq[st[1]])); g.apply(st); turns+=1
        else:
            out,pt=until(P); absorb(out); send('q')
        send('0'); p.stdin.close(); p.wait(timeout=60)
    finally:
        p.kill()
    return result,turns

if __name__=='__main__':
    cfg=sys.argv[1]; level=int(sys.argv[2]); a,b=int(sys.argv[3]),int(sys.argv[4])
    for seed in range(a,b):
        try: print(seed, game(seed,cfg,level))
        except Exception as e: print('FAIL',seed,repr(e)[:400])
