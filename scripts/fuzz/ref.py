"""Independent reference model of the rules, used to fuzz the MIPS program."""
import copy, random

class G:
    def __init__(s, n=8, rows=3, flags=()):
        s.n=n; s.flags=set(flags); s.h=n//2
        s.b={}          # (r,c) -> 'b','r','B','R'
        s.ghost=set()
        s.turn='b'; s.chain=None
        s.sq={}; s.pos={}
        k=1
        for r in range(n):
            for c in range(n):
                if (r+c)%2:
                    s.sq[(r,c)]=k; s.pos[k]=(r,c); k+=1
        s.total=k-1
        m=rows*s.h
        for q in range(1,m+1):
            s.b[s.pos[q]]='r'; s.b[s.pos[s.total+1-q]]='b'
        s.quiet=0
    def on(s,p): return 0<=p[0]<s.n and 0<=p[1]<s.n
    def dirs(s,pc,capture):
        if pc.isupper(): return [(-1,-1),(-1,1),(1,-1),(1,1)]
        fwd=[(-1,-1),(-1,1)] if pc=='b' else [(1,-1),(1,1)]
        back=[(1,-1),(1,1)] if pc=='b' else [(-1,-1),(-1,1)]
        if capture and 'menback' in s.flags: return fwd+back if pc=='b' else back+fwd
        if not capture and 'menbackmove' in s.flags: return fwd+back if pc=='b' else back+fwd
        return fwd
    def enemy(s,p,pc):
        q=s.b.get(p)
        return q is not None and q.lower()!=pc.lower() and p not in s.ghost
    def captures(s,p):
        pc=s.b[p]; out=[]
        fly = pc.isupper() and 'flying' in s.flags
        for d in s.dirs(pc,True):
            if not fly:
                m=(p[0]+d[0],p[1]+d[1]); l=(m[0]+d[0],m[1]+d[1])
                if s.on(l) and s.enemy(m,pc) and l not in s.b: out.append((p,l,m))
            else:
                q=(p[0]+d[0],p[1]+d[1])
                while s.on(q) and q not in s.b: q=(q[0]+d[0],q[1]+d[1])
                if s.on(q) and s.enemy(q,pc):
                    l=(q[0]+d[0],q[1]+d[1])
                    while s.on(l) and l not in s.b:
                        out.append((p,l,q)); l=(l[0]+d[0],l[1]+d[1])
        return out
    def simples(s,p):
        pc=s.b[p]; out=[]
        fly = pc.isupper() and 'flying' in s.flags
        for d in s.dirs(pc,False):
            q=(p[0]+d[0],p[1]+d[1])
            while s.on(q) and q not in s.b:
                out.append((p,q,None))
                if not fly: break
                q=(q[0]+d[0],q[1]+d[1])
        return out
    def chainlen(s,st):
        g=copy.deepcopy(s); cont=g.apply(st)
        if not cont: return 1
        return 1+max(g.chainlen(x) for x in g.captures(g.chain))
    def cont_after(s,st):
        g=copy.deepcopy(s); return g.apply(st)
    def filt(s,caps):
        if not caps: return caps
        if 'max' in s.flags:
            v=[s.chainlen(c) for c in caps]; m=max(v)
            return [c for c,x in zip(caps,v) if x==m]
        if 'flying' in s.flags:
            out=[]
            for c in caps:
                grp=[x for x in caps if x[0]==c[0] and x[2]==c[2]]
                anyc=any(s.cont_after(x) for x in grp)
                if not anyc or s.cont_after(c): out.append(c)
            return out
        return caps
    def mine(s):
        return [p for p,pc in sorted(s.b.items(), key=lambda kv: s.sq[kv[0]]) if pc.lower()==s.turn and p not in s.ghost]
    def legal(s):
        if s.chain: return s.filt(s.captures(s.chain))
        caps=[]
        for p in s.mine(): caps+=s.captures(p)
        caps=s.filt(caps) if ('max' in s.flags or 'flying' in s.flags) else caps
        if caps and 'must' in s.flags: return caps
        out=list(caps)
        for p in s.mine(): out+=s.simples(p)
        return out
    def lastrow(s,p,pc): return p[0]==(0 if pc=='b' else s.n-1)
    def apply(s,st):
        f,t,c=st; pc=s.b.pop(f)
        if c is not None:
            if 'deferred' in s.flags: s.ghost.add(c)
            else: del s.b[c]
            s.quiet=0
        elif pc.islower(): s.quiet=0
        else: s.quiet+=1
        if pc.islower() and s.lastrow(t,pc) and (c is None or 'promomid' in s.flags): pc=pc.upper()
        s.b[t]=pc
        if c is not None and s.captures(t):
            s.chain=t; return True
        if pc.islower() and s.lastrow(t,pc): s.b[t]=pc.upper()
        for g in s.ghost: del s.b[g]
        s.ghost.clear(); s.chain=None
        s.turn='r' if s.turn=='b' else 'b'
        return False
    def count(s,col): return sum(1 for p,pc in s.b.items() if pc.lower()==col and p not in s.ghost)
    def plain(s, flip=False):
        rows=[]
        for r in range(s.n):
            cells=[]
            for c in range(s.n):
                rr,cc=(s.n-1-r,s.n-1-c) if flip else (r,c)
                if (rr+cc)%2==0: cells.append(' ')
                elif (rr,cc) in s.ghost: cells.append('x')
                else: cells.append(s.b.get((rr,cc),'0'))
            rows.append(' '.join(cells).rstrip())
        return rows
