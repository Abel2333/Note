#import "/templates/lib.typ": EE, LL, RR, conf, definition, note, theorem

// Set Metadata
#set document(
  title: "K-Nearest Neighbors",
  author: "Abel Zhan",
)

// Apply Template
#show: conf

= Preliminaries & Notation

Before diving into bounds, establish the mathematical setting.

#definition(title: "Dataset & Metric")[
  - *Dataset:*
    $ cal(D)_n = {(X_1, Y_1), ..., (X_n, Y_n)} $
    where $X in RR^d$ and $Y in {1, 2, ..., M}$ (Multi-class).

  - *Distance Metric:*
    Usually Euclidean distance $norm(x-x')$.
]

== The K-NN Algorithm

For a target point $x_t$, compute the distance to every point in the training set $cal(D)_n$. Identify the set of $k$ points that are nearest to $x_t$.

The predicted class $hat(y)$ is determined by a *majority vote*: it corresponds to the most frequent class among these chosen Neighbors.

#note[
  In the remainder of this article, we will focus on the theoretical analysis of the case where $k = 1$ (1-Nearest Neighbor).
]

= The Bayes Optimal Classifier

For the Multi-class classification problem ($M$ classes).

Let $eta_c (x) = P(Y=c | X=x)$. The Bayes optimal classifier $C^*$ minimizes the probability of error by choosing the most likely class:

$ C^*(x) = limits(arg max)_(c in {1, ..., M}) eta_c (x) $

And the conditional Bayes error (risk) at point $x$, denoted as  $r^* (x)$, is the probability of failing to predict the correct class:

$ r^* (x) = 1 - max_c eta_c (x) $ <bayesr>

The overall Bayes error rate $R^*$ is the expectation of this conditional error:

$ R^* = EE_x [1 - max_c eta_c (X)] $

= Asymptotic Error of 1-NN (Cover-Hart)

Let $(X', Y')$ be the nearest neighbor of the query point $X$ in the training set $cal(D)_n$. The 1-NN classifier predicts the label $Y'$ for the input $X$. An error occurs if $Y != Y'$.

Consider the conditional probability of error given the query point $x$ and its specific nearest neighbor $X'=x'$:

$
  P(Y != Y' | X=x, X'=x') & = 1 - P(Y = Y' | X=x, X'=x') \
                          & = 1 - sum_(c=1)^M P(Y=c | X=x) P(Y'=c | X'=x') \
                          & = 1 - sum_(c=1)^M eta_c (x) eta_c (x')
$

#note[
  *Convergence Condition:*
  As the sample size $n -> infinity$, the training data fills the space dense enough such that the nearest neighbor $X'$ converges to $X$ (i.e., $norm(X' - X) -> 0$).
  Assuming the posterior probability functions $eta_c (.)$ are continuous, this implies $eta_c (X') -> eta_c (X)$.
]

Therefore, the *asymptotic* conditional error rate $r_("1NN") (x)$ is obtained by taking the limit:

$
  r_("1NN") (x) & = lim_(n -> infinity) (1 - sum_(c=1)^M eta_c (x) eta_c (x')) \
                & = 1 - sum_(c=1)^M eta_c (x) eta_c (x) \
                & = 1 - sum_(c=1)^M eta_c^2 (x)
$<r1nn>

Finally, the global asymptotic error rate $R_("1NN")$ is the expectation over $X$:

$ R_("1NN") = EE_X [r_("1NN") (X)] = EE_X [1 - sum_(c=1)^M eta_c^2 (X)] $

// 修正：语法和拼写
Let the maximum conditional probability be $eta_max (x) = limits(max)_(c in {1,..., M}) {eta_c (x)}$.

// 修正：拼写 convenience
For convenience, we denote $eta_c = eta_c (x)$ and $eta_max = eta_max (x)$.

Thus, $sum_(c=1)^M eta_c = eta_max + sum_(j != max) eta_j ==> sum_(j != max) eta_j = 1 - eta_max$.

Recall the _Cauchy-Schwarz Inequality_. We have:

$
  (sum_(j != max) eta_j)^2 &<= (sum_(j != max) eta_j^2) dot sum_(i = 1)^(M-1) 1^2 \
  &=(sum_(j != max) eta_j^2) dot (M-1)
$

Thus, we can bound the sum of squares:
// 修正：这里之前的公式里 (1 - eta^2) 写错了，应该是 (1-eta)^2
$
  sum_(c=1)^M eta_c^2 & = eta_max^2 + limits(sum_(j != max) eta_j^2) \
                      & >= eta_max^2 + 1/(M-1) (1 - eta_max)^2
$

Substituting this into @r1nn,

$
  r_("1NN") & = 1 - sum_(c=1)^M eta_c^2 \
            & <= 1 - eta_max^2 - 1/(M-1) (1 - eta_max)^2
$

Recall the definition of Bayes error in @bayesr, where $r^* = 1 - eta_max$. By substitution:

$
  r_("1NN") & <= 1 - (1 - r^*)^2 - 1/(M-1) (r^*)^2 \
            & = 1 - (1 - 2r^* + (r^*)^2) - 1/(M-1) (r^*)^2 \
            & = 2r^* - (1 + 1/(M-1)) (r^*)^2 \
            & = 2r^* - M/(M-1) (r^*)^2
$

Similarly, taking the expectation over $X$:

$
  R_("1NN") = EE_X [r_("1NN")(X)] & <= EE_X [2r^*(X) - M/(M-1) (r^*(X))^2] \
  & = 2 EE_X [r^* (X)] - M/(M-1) EE_X [(r^* (X))^2]
$

Using the fact that $EE [Z^2] >= (EE [Z])^2$ (implied by variance being non-negative), we have $EE_X [(r^*(X))^2] >= (R^*)^2$.
Note that since the term has a negative sign, the inequality direction is preserved for the upper bound:

$
  R_("1NN") <= R^*(2 - M/(M-1) R^*)
$

#theorem(title: "Theorem: Cover-Hart Error Bound")[
  For the 1-Nearest Neighbor algorithm in an $M$-class classification problem, as $n -> infinity$, the asymptotic error rate $R_("1NN")$ is bounded by the Bayes error rate $R^*$:

  $ R^* <= R_("1NN") <= R^* (2 - M/(M-1) R^*) $

  *Special Cases:*
  - When $M=2$ (Binary Classification):
    $ R_("1NN") <= 2R^* (1 - R^*) $
  - When $M -> infinity$ (Large number of classes):
    $ R_("1NN") <= 2R^* $
]
