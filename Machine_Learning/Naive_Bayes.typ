#import "/lib.typ": EE, LL, RR, conf, definition, note, theorem

// Set Metadata
#set document(
  title: "Naive Bayes",
  author: "Abel Zhan",
)

// Apply Template
#show: conf

= Preliminaries & Notation

Before the beginning, we need to establish some consensus.

#definition(title: "Dataset")[
  Assume that the input space $cal(X) subset.eq RR^n$ is an $n$-dimensional space,
  and the output space is a discrete set of class labels $cal(Y) = {c_1, c_2, ..., c_K}$.
  Each input is represented by a feature vector $x in cal(X)$, and its corresponding label is $y in cal(Y)$.

  Let $X$ be a random vector taking values in $cal(X)$, and $Y$ be a random variable taking values in $cal(Y)$.
  We denote their joint probability distribution as $P(X, Y)$.

  The training dataset
  $ T = {(x_1, y_1), (x_2, y_2), ..., (x_N, y_N)} $
  is composed of $N$ samples drawn independently and identically distributed (i.i.d.) from $P(X, Y)$.
]

= Bayes Decision Theory

To justify why we choose the class with the maximum posterior probability,
we start from the perspective of *Expected Risk Minimization*.

#definition(title: "0-1 Loss Function")[
  For a classifier $f(x)$, the 0-1 loss function is defined as:
  $ L(Y, f(x)) = cases(1 "if" Y != f(x), 0 "if" Y = f(x)) $
]

The goal of learning is to find a decision rule $f: cal(X) -> cal(Y)$ that minimizes the *Expected Risk*.
$ R(f) = EE_(X,Y) [L(Y, f(X))] $

By the law of total expectation, the risk can be decomposed as:
$ R(f) = EE_X [ EE_(Y|X) [L(Y, f(X)) | X=x] ] $

#note[
  The importance of this decomposition lies in *pointwise optimization*:
  it allows us to transform a global functional minimization problem into a series of local minimization problems.
  For each specific $x$, we can determine the optimal label $f^*(x)$ by considering only the conditional distribution $P(Y|X=x)$, without worrying about the values of $f$ at other points in the input space.
]

To minimize $R(f)$, it is sufficient to minimize the *conditional risk* for each $x$:
$
  f^*(x) & = limits(arg min)_(y in cal(Y)) EE_(Y|X) [L(Y, y) | X=x] \
         & = limits(arg min)_(y in cal(Y)) sum_(k=1)^K L(c_k, y) P(Y=c_k | X=x)
$

Substitute the 0-1 loss into the equation:
$
  f^*(x) & = limits(arg min)_(y in cal(Y)) sum_(c_k != y) 1 dot P(Y=c_k | X=x) \
         & = limits(arg min)_(y in cal(Y)) (1 - P(Y=y | X=x)) \
         & = limits(arg max)_(y in cal(Y)) P(Y=y | X=x)
$

#note[
  This derivation shows that *minimizing the expected 0-1 loss is equivalent to the Maximum A Posteriori (MAP) decision rule*.
]

= Naive Bayes Model

The Naive Bayes algorithm is based on *Bayes' Theorem*:

#theorem(title: "Bayes' Theorem")[
  $ P(Y=c | X=x) = frac(P(X=x | Y=c)P(Y=c), P(X=x)) $<bayesformula>
]

where:
- $P(Y=c)$ is the _prior probability_, representing the probability of a class without observing any features.
- $P(X=x | Y=c)$ is the _conditional probability_ (likelihood), representing the probability of observing the features given a class.

The algorithm makes a *naive assumption*: all features are *conditionally independent* given the class label. Specifically, for a class $c_k$ ($k=1,2,...,K$):

$
  P(X=x | Y=c_k) & = P(X^((1))=x^((1)), X^((2))=x^((2)), dots.c, X^((n))=x^((n)) | Y=c_k) \
  & = product_(j=1)^n P(X^((j))=x^((j)) | Y=c_k)
$<assumption>

= Calculation

Now, we can calculate the _posterior probability_ by combining @bayesformula and @assumption. For each class $c_k$:

$
  P(Y=c_k | X=x) = frac(P(Y=c_k) limits(product)_(j=1)^n P(X^((j))=x^((j)) | Y=c_k), limits(sum)_(i=1)^K P(X=x | Y=c_i)P(Y=c_i))
$

Considering that the denominator $P(X=x)$ is the same for all classes, the classifier $C(x)$ simplifies to finding the class that maximizes the numerator:

$
  C^*(x) = limits(op("arg max"))_(c_k in cal(Y)) { P(Y=c_k) limits(product)_(j=1)^n P(X^((j))=x^((j)) | Y=c_k) }
$

= Parameter Estimation

To implement the classifier, we need to estimate the probabilities from the training set $T$.

#note[
  By maximizing the log-likelihood function $ell(phi) = sum N_k ln phi_k$ under the constraint $sum phi_k = 1$, we can prove that the MLE for these probabilities corresponds to the empirical frequencies.
]


== Derivation of MLE for Class Priors

To estimate the parameters $phi_k = P(Y=c_k)$ for $k=1, dots, K$, we use the Maximum Likelihood Estimation.

=== Likelihood Function
Assume the training labels $y_1, dots, y_N$ are independent and identically distributed (i.i.d.). The likelihood function $L(phi)$ is the joint probability of the observed labels:

$
  L(phi_1, dots, phi_K) = P(y_1, dots, y_N | phi) = product_(i=1)^N P(y_i | phi)
$

Let $N_k = sum_(i=1)^N I(y_i = c_k)$ be the count of samples belonging to class $c_k$. We can rewrite the likelihood by grouping terms of the same class:

$ L(phi) = product_(k=1)^K phi_k^(N_k) $

=== Log-Likelihood
To simplify the maximization, we take the natural logarithm, which transforms the product into a sum:

$ ell(phi) = ln L(phi) = sum_(k=1)^K N_k ln phi_k $

=== Lagrange Multiplier
We need to maximize $ell(phi)$ subject to the constraint that all probabilities sum to one: $sum_(k=1)^K phi_k = 1$. We define the Lagrange function:

$
  cal(L)(phi, lambda) = sum_(k=1)^K N_k ln phi_k + lambda (1 - sum_(k=1)^K phi_k)
$

=== Solving for Parameters
Taking the partial derivative with respect to each $phi_k$ and setting it to zero:

$
  frac(partial cal(L), partial phi_k) = frac(N_k, phi_k) - lambda = 0 quad ==> quad N_k = lambda phi_k
$ <mle_step>

To find $lambda$, we sum both sides of @mle_step over all $k$:

$ sum_(k=1)^K N_k = lambda sum_(k=1)^K phi_k $

Since $sum N_k = N$ (total samples) and $sum phi_k = 1$ (probability constraint), we have:

$ N = lambda dot 1 quad ==> quad lambda = N $

=== Final Result
Substituting $lambda = N$ back into @mle_step, we obtain the MLE for the class prior:

$ hat(phi)_k = frac(N_k, N) = frac(sum_(i=1)^N I(y_i = c_k), N) $

#note[
  This result proves that the Maximum Likelihood Estimate of a multinomial distribution's parameters is simply the *empirical frequency* of each class in the dataset.
]

== Maximum Likelihood Estimation (MLE)
The most intuitive way is to use the relative frequency of events:

1. *Prior Probability:*
  $ P(Y=c_k) = frac(sum_(i=1)^N I(y_i = c_k), N) $

2. *Conditional Probability (for discrete features):*
  $
    P(X^((j)) = a | Y=c_k) = frac(sum_(i=1)^N I(x_i^((j)) = a, y_i = c_k), sum_(i=1)^N I(y_i = c_k))
  $

== Bayesian Smoothing
To avoid the *zero-probability problem*, we use _Laplace Smoothing_ (by setting $lambda = 1$):

1. *Smoothed Prior Probability:*
  $ P_lambda (Y=c_k) = frac(sum_(i=1)^N I(y_i = c_k) + lambda, N + K lambda) $

2. *Smoothed Conditional Probability:*
  $
    P_(lambda)(X^((j)) = a | Y=c_k) = frac(sum_(i=1)^N I(x_i^((j)) = a, y_i = c_k) + lambda, sum_(i=1)^N I(y_i = c_k) + S_j lambda)
  $

where $S_j$ is the number of possible values for the $j$-th feature.
