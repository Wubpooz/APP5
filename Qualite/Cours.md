Contrat = ce que le programme fait (description générale, préconditions, valeur de retour, postcondition)



**Exercice:**
1) $\{x=y\} x := x+y \{x=2*y\}$ 
D'après la règle d'affectation, $x=y \Rightarrow (x)[x \leftarrow x+y]$ (substitution de x+y dans x)
$(x = 2y)[x \leftarrow x+y] = x+y = 2y = x=y$

2) {True} if $x>y$ then $m=x$ else $m=y$ $\{m\geq x \wedge m\geq y \wedge(m=x \vee m=y)\}$
On doit prouver :
- $\{True \vee x>y\} \; m=x \; \{m\geq x \wedge m\geq y \wedge(m=x \vee m=y)\}$ : $
- $\{True \vee x\leq y\}\; m=y \;\{m\geq x \wedge m\geq y \wedge(m=x \vee m=y)\}$



**Exercice:**
Trouver les WP pour:
- $\{P\} \; x=x-2;\, z=x+1 \; \{z\neq0\}$ : 
$WP = WP(x=x-2, WP(z=x+1, z\neq 0)) = WP(x=x-2, x+1\neq 0) = (x-1\neq 0)$ 
$= (x \neq 1)$ 
- $\{P\} \; x=2*y;\, z=x+y \; \{z>0\}$: 
$WP = WP(x=2*y;\, WP(z=x+y, z>0)) = WP(x=2*y, x+y>0) = (3y > 0) = (y >0)$
- $\{P\} \; w=2*w; \, z=-w;\, y=v+1;\, x=min(y,z)\; \{x<0\}$: 
$WP(w=2*w, WP(z=-w, WP(y=v+1, WP(x=min(y,z), x<0))))$ 
$= WP(w=2*w, WP(z=-w, WP(y=v+1, min(y,z)<0))) = WP(w=2*w, WP(z=-w, min(v+1,z)<0))$
$= WP(w=2*w, min(v+1, -w)<0) = (min(v+1, -2*w)<0)$ 
$= ((min \leq -2*w) \wedge (min \leq v+1))\wedge(min=v+1 \vee min=-2*w))$



**Exercice:**
$\{P\}$ if $(x>0)$ then $y:= z$ else $y:=-z \; \{y>5\}$ : $WP = x>0 \Rightarrow WP(y:=z, y>5) \wedge x\leq 0 \Rightarrow WP(y:=-z, y>5)$
$= (x>0 \Rightarrow z>5 \wedge x\leq 0 \Rightarrow z<-5)$  ensuite **on utilise que $a \Rightarrow b = \neg a \vee b$ puis on développe**
$= (x\leq 0 \vee z>5) \wedge (x>0 \vee z<-5)$
$= ((x\leq 0 \wedge x>0) \vee (x\leq 0 \wedge z<-5)) \vee ((z>5 \wedge x>0) \vee (z>5 \wedge z<-5))$
$= (x\leq 0 \wedge z<-5) \vee (z>5 \wedge x>0)$



