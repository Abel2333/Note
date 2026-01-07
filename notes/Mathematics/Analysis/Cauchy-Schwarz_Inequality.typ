#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2.5cm),
)
#set text(font: "Liberation Serif", size: 11pt)
#set heading(numbering: "1. ")
#set math.equation(numbering: "(1)")

= Cauchy-Schwarz Inequality

== Theorem

For any real numbers $a_1, a_2, ..., a_n$, and $b_1, b_2, ..., b_n$, the following inequality holds:

$ (sum_(i=1)^n a_i b_i)^2 <= (sum_(i=1)^n a_i^2) (sum_(i=1)^n b_i^2) $

== Proof

The Cauchy-Schwarz inequality can be proven using the method of Lagrange multipliers or by considering the properties of inner products in vector spaces. Here, we provide a simple proof using the concept of non-negative quadratic forms.

Consider the expression:

$ f(t) = sum_(i=1)^n (a_i t + b_i)^2 $

Obviously, $f(t) >= 0$ for every real number $t$.

Let's expand this function:

$
  f(t) &= sum_(i=1)^n (a_i^2 t^2 + 2 a_i b_i t + b_i^2) \
  &= (sum_(i=1)^n a_i^2) t^2 + 2 (sum_(i=1)^n a_i b_i) t + sum_(i=1)^n b_i^2 \
  &>= 0
$

First, consider the term $A = sum_(i=1)^n a_i^2$.

If $A = 0$, then it implies $a_i = 0$ for all $i$, so the inequality holds trivially ($0 <= 0$).

If $A > 0$, then $f(t)$ is a quadratic funuction. Since $f(t) >= 0$ for all real numbers $t$, its discriminant $Delta$ must be non-postive ($Delta <= 0$).

Thus:

$
  Delta & = (2 sum_(i=1)^n a_i b_i)^2 - 4 (sum_(i=1)^n a_i^2) (sum_(i=1)^n b_i^2) <= 0 \
  &<=> 4 (sum_(i=1)^n a_i b_i)^2 <= 4 (sum_(i=1)^n a_i^2) (sum_(i=1)^n b_i^2) \
  &<=> (sum_(i=1)^n a_i b_i)^2 <= (sum_(i=1)^n a_i^2) (sum_(i=1)^n b_i^2)
$

=== Condition for Equality

The equality holds if and only if $Delta = 0$. This corresponds to the case where the equation $f(t) = 0$ has a real root.

This implies that there exists a scalar $t$ such that:
$ a_i + b_i = 0, quad forall i = 1, ..., n $

Geometrically, this means that the vectors $bold(a) = (a_1, ..., a_n)$ and $bold(b) = (b_1, ..., b_n)$ are *linearly dependent* (i.e., parallel).
