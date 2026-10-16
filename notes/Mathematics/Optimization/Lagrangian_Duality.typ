#import "/templates/lib.typ": RR, conf, definition, note, theorem

#set document(
  title: "Lagrangian Duality: Bounds, Certificates, and Recovery",
  author: "Abel Zhan",
)

#show: conf

= Why Constraints Need More Than Calculus

Constrained optimization asks for the best value of an objective while obeying
rules. The Lagrangian does not remove those rules by magic. Instead, it builds
certified bounds by charging for violations, then asks how tight a bound those
charges can provide. This note develops that idea from one small problem before
stating the general construction.

For a minimization problem, an *objective* is the quantity to make small and a
point is *feasible* when it satisfies every stated constraint and lies in its
declared domain. The *optimal value* is a number, conventionally $p^*$; an
*optimizer* is a feasible point $x^*$ that attains that value. These are not
interchangeable: a problem can have an infimum without an optimizer. The
infimum $inf A$ is the greatest lower bound of a set $A$; a minimum is an
infimum that belongs to $A$. Supremum and maximum are the corresponding upper
notions. Thus a value is *attained* only when a feasible variable realizes it.

== Running scalar problem <running-problem>

Consider

$ p^* = min_(x in RR) x^2 quad "subject to" quad 1-x <= 0. $

The constraint says $x >= 1$, so $x^*=1$ is feasible and $p^*=1$. Introduce a
nonnegative charge $lambda >= 0$ for the inequality and form

$ L(x, lambda) = x^2 + lambda(1-x). $

For feasible $x$, the residual $1-x$ is nonpositive. Consequently
$lambda(1-x) <= 0$, so $L(x,lambda) <= x^2$ *only on the feasible set*.
For a fixed charge, completing the square gives

$ L(x, lambda) = (x - lambda/2)^2 + lambda - lambda^2/4. $

Its unconstrained inner minimizer is $x_lambda=lambda/2$, and the resulting
dual function is

$ g(lambda) = inf_(x in RR) L(x,lambda) = lambda - lambda^2/4,
  quad lambda >= 0. $

Each allowed multiplier $lambda >= 0$ produces a lower bound $g(lambda)$ on
$p^*$. We now optimize over the multiplier to find the largest such bound.
Denote this *optimal dual value* by $d^* = sup_(lambda >= 0) g(lambda)$; a
*dual optimizer* $lambda^*$ is a multiplier that attains it.

Since $g(lambda)=1-(lambda-2)^2/4$, its maximum is attained at $lambda^*=2$,
and $d^*=g(lambda^*)=1$. Here the primal and dual values agree, but this is a
result to establish, not a license to exchange a minimization and a
maximization in arbitrary formulas.

#figure(
  image("/assets/diagrams/lagrangian_primal_dual_bounds.svg", width: 100%),
  caption: [The running problem. Left: Lagrangian curves may lie below the
  objective only where $x >= 1$ is feasible. Right: every dual value is a lower
  bound on $p^*=1$; the maximum at $lambda=2$ is tight.],
) <running-figure>

= General Construction and Weak Duality

Let $D subset RR^n$ be the common domain of the functions below. Let
$f_0:D -> RR$ be the primal objective; for indices $i=1,dots,m$, let
$f_i:D -> RR$ be inequality residuals; for indices $j=1,dots,p$, let
$h_j:D -> RR$ be equality residuals. The primal problem is

$ p^* = inf_(x in D) f_0(x) quad "subject to" quad
  f_i(x) <= 0 " for " i=1,dots,m, quad
  h_j(x) = 0 " for " j=1,dots,p. $

The set $D$ remains part of the inner problem. The Lagrangian relaxes the
displayed constraints, not the function domains:

$ L(x,lambda,nu) = f_0(x) + sum_(i=1)^m lambda_i f_i(x)
  + sum_(j=1)^p nu_j h_j(x), $

where $lambda=(lambda_1,dots,lambda_m) in RR^m$ has $lambda_i >= 0$, and
$nu=(nu_1,dots,nu_p) in RR^p$ is unrestricted. Its dual function is

$ g(lambda,nu) = inf_(x in D) L(x,lambda,nu). $

The infimum may be $-infinity$. It is still useful because every primal-feasible
$x$ obeys

$ g(lambda,nu) <= L(x,lambda,nu) <= f_0(x). $

The first inequality is the definition of an infimum. The second follows from
nonnegative multipliers times nonpositive inequality residuals, while equality
terms vanish. Taking the best lower bound gives the dual problem and weak
duality:

$ d^* = sup_(lambda >= 0, nu in RR^p) g(lambda,nu) <= p^*. $

For each fixed $x$, $L(x,lambda,nu)$ is affine in $(lambda,nu)$. An infimum of
affine functions is concave, so $g$ is concave even if the primal problem is
nonconvex. That structural fact does not make evaluation of $g$ cheap, and it
does not make a nonconvex primal equivalent to its dual.

= Strong duality, gap, and Slater's condition <strong-duality>

When finite values satisfy $p^*=d^*$, *strong duality* holds; otherwise weak
duality only supplies a bound. The finite-valued quantity $p^*-d^* >= 0$ is the
*duality gap*. Attainment is separate: $d^*$ can equal $p^*$ without any finite
dual optimizer, and a dual theorem need not produce a primal optimizer.

For the following common sufficient condition, suppose $f_0,f_1,dots,f_m$ are
convex on their domain and each $h_j$ is affine. Slater's condition asks for a
point in the relative interior of $D$ that satisfies all equality constraints
and all nonlinear inequality constraints strictly. Relative interior means
interior within the smallest affine space containing $D$; affine inequalities
may be allowed to hold non-strictly in the refined statement. Under the usual
finite-value hypotheses, Slater's condition gives strong duality and dual
attainment. It is sufficient, not necessary, and does not by itself claim
primal attainment. The separating-hyperplane proof and its exact technical
hypotheses are given in @boyd2004, Section 5.3.2.

= KKT Certificates and Multiplier Meaning

Assume for this section that all data are differentiable on an open domain
$U subset RR^n$, so the stationarity statement does not silently ignore a
boundary normal cone. At a candidate $(x^*,lambda^*,nu^*)$, the
Karush-Kuhn-Tucker (KKT) conditions are

$
  f_i(x^*) <= 0, h_j(x^*) = 0; quad
  lambda_i^* >= 0; quad
  lambda_i^* f_i(x^*) = 0; quad
  partial L(x^*,lambda^*,nu^*) / partial x = 0.
$

They are respectively primal feasibility, dual feasibility, complementary
slackness, and stationarity. For a non-open domain, stationarity must include
the appropriate normal-cone condition rather than simply reuse this gradient
equation. An active inequality has $f_i(x^*)=0$, but it need not have a positive
multiplier; complementarity only forces a positive multiplier's constraint to
be active.

For a convex problem, if a primal-dual pair is feasible, complementary, and
$x^*$ globally minimizes $L(.,lambda^*,nu^*)$, then
$g(lambda^*,nu^*)=L(x^*,lambda^*,nu^*)=f_0(x^*)$. Weak duality makes this
common value optimal, which is the KKT sufficiency reasoning. KKT necessity
requires suitable regularity, such as an appropriate constraint qualification
and existence assumptions. In a nonconvex problem, KKT is not a global
optimality certificate.

== The running KKT certificate

For $f_0(x)=x^2$ and $f_1(x)=1-x$, the four conditions are

$ 1-x^* <= 0, quad lambda^* >= 0, quad
  lambda^*(1-x^*)=0, quad 2x^*-lambda^*=0. $

The pair $(x^*,lambda^*)=(1,2)$ satisfies them, reproducing $p^*=d^*=1$.
For an equality-only example,

$ min_(x_1,x_2 in RR) x_1^2+x_2^2 quad "subject to" quad x_1+x_2=1, $

the Lagrangian has stationarity equations $2x_1+nu=0$ and $2x_2+nu=0$.
Together with the equality, they give $x^*=(1/2,1/2)$, $nu^*=-1$, and
$p^*=d^*=1/2$.

Under conditions that make the value function well behaved, an optimal
multiplier can describe the local sensitivity of the optimal value to a
right-hand-side perturbation: it is often called a shadow price. The sign and
the exact derivative depend on the stated constraint convention and regularity.
A fixed regularization coefficient such as $alpha$ is not automatically a
dual variable or a price.

= Limits of the Bound and of Recovery

== Zero gap without a dual optimizer <dual-nonattainment>

Consider $min_x x$ subject to $x^2 <= 0$. The only feasible point is $x=0$,
so $p^*=0$. For $lambda>0$,

$ g(lambda) = inf_x (x + lambda x^2) = -1/(4lambda), $

and $g(0)=-infinity$. Thus $d^*=0$, but it is approached only as
$lambda -> infinity$. There is no finite dual optimizer. Slater's strict
feasibility condition fails, so this example does not contradict the theorem.

As a small positive-gap example, use the nonconvex domain $D={-1,1}$ and
$min_(x in D) x$ subject to $-x <= 0$. Feasibility leaves $x=1$, so $p^*=1$.
Directly minimizing the two Lagrangian values gives

$ g(lambda) = -abs(1-lambda), quad lambda >= 0, $

and $d^*=0$ at $lambda=1$. This is a bound, not a convex-duality failure.

== Inner minimizers need recovery checks <recovery>

For $min_x x$ subject to $-x <= 0$, the primal solution is $x^*=0$ and
$lambda^*=1$. Yet $L(x,1)=x-x=0$ for every $x$: an arbitrary inner minimizer
need not be primal feasible. Primal feasibility plus complementary slackness
select $x=0$. A dual solution therefore need not recover a primal solution
without additional information or a recovery procedure.

= From Idealized Updates to MoE Biases

The dual definition uses exact inner minimization. Practical algorithms often
alternate approximate primal and dual steps instead. If $x(lambda,nu)$ exactly
minimizes the Lagrangian, its constraint residual is a supergradient of the
concave dual function: a projected dual-ascent step for an inequality has the
form

$ lambda_i^+ = max(0, lambda_i + eta f_i(x(lambda,nu))), quad eta>0. $

It is an ordinary gradient only under additional uniqueness and smoothness
conditions. Approximate inner solves, changing data, and fixed step sizes need
their own convergence analysis.

== Fixed-score balanced assignment <moe-connection>

The companion #link("../../Machine_Learning/Deep_Learning/Mixture_of_Experts.pdf")[Mixture
of Experts] note develops a fixed-score balanced-routing maximization. Fix
$T$ token indices $t=1,dots,T$, $N$ routed-expert indices $i=1,dots,N$, and
fixed affinities $s_(t i)$. Each token makes $K$ requests, so
$q=T K/N$ is the common target load per expert; $q$ must be integral when it is
connected to an exact binary assignment. Let $X_(t i) in {0,1}$ indicate whether
token $t$ is hard-assigned to expert $i$, with row-feasible domain

$ cal(X)_("row") = {X: X_(t i) in {0,1},
  sum_(i=1)^N X_(t i) = K " for " t=1,dots,T}. $

Its bounded row relaxation instead permits $X_(t i) in [0,1]$ with the same row
sums. Define

$ F(X) = sum_(t=1)^T sum_(i=1)^N s_(t i) X_(t i), quad
  R_i(X) = sum_(t=1)^T X_(t i). $

The balanced primal value is

$ F^* = max_(X in cal(X)_("row"), R_i(X)=q " for " i=1,dots,N) F(X). $

For a bias $b in RR^N$, define

$ Lambda(X,b) = F(X) + sum_i b_i(R_i(X)-q), quad
  D(b) = max_(X in cal(X)_("row")) Lambda(X,b). $

Choose an inner maximizer $X(b)$ in the definition of $D(b)$ and write
$R_i(b)=R_i(X(b))$; ties may admit multiple such choices. This is the
max-primal counterpart of the minimization convention above: $D(b) >= F^*$ for
every $b$, and the dual minimizes the convex upper bound $D(b)$. Its
$i$th subgradient component is $R_i(b)-q$; where the selection is unique it is
the ordinary gradient. Thus descent uses
$b_i^+ = b_i - eta(R_i(b)-q)$: overloaded experts receive a smaller selection
bias and underloaded experts a larger one. Kimi's threshold notation uses
$b=-beta$, which reverses the displayed sign in that variable.

The connection is conditional. Integral targets, ties, and coordinated primal
recovery matter even when the LP bound is tight. Real routing has changing
scores, batches, capacity rules, delayed measurements, and finite updates, so
the static dual does not promise online controller convergence or immediate
balance. The MoE note keeps the full assignment derivation and model-specific
details; this chapter supplies the shared duality vocabulary.

= References

#bibliography("references.bib", title: none)
