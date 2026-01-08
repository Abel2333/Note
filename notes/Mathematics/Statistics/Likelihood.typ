#import "/templates/lib.typ": EE, LL, RR, conf, definition, note, theorem

#let grad = $nabla_theta$
#let hess = $nabla_theta^2$

// Set Metadata
#set document(
  title: "Likelihood: Theory, Estimation, and Properties",
  author: "Abel Zhan",
)

// Apply Template
#show: conf

= The Fundamental Definition

#definition(title: "The Likelihood Function")[
  Let $X$ be a random variable with a probability density function (PDF) or probability mass function (PMF) denoted by $f(x|theta)$,
  where $theta$ is a vector of parameters.
  Given a set of observed data $x=(x_1, x_2, dots.c, x_N)$,
  the *likelihood function* $L(theta | x)$ is defined as:
  $ L(theta | x) = f(x | theta) $
  When viewed as a function of $theta$ for a fixed $x$, $L(theta | x)$ represents how "likely" different parameter values are to have generated the observed data.
]

== Explanation and Significance

- *Fixed and Variable:* In probability, we fixed $theta$ and vary $x$ to predict outcomes.
  In likelihood, we *fix the observed data* x and vary $theta$ to estimate the underlying process.
- *Not a Probability Distribution:* Crucially, $L(theta|x)$ is *not* a probability distribution over $theta$.
  The area under the likelihood curve $integral L(theta|x)d theta$ does not necessarily equal 1,
  and the function does not obey the axioms of probability.

= Principle of Maximum Likelihood Estimation (MLE)

#theorem(title: "The MLE Principle")[
  The *Maximum Likelihood Estimation* of $theta$, denoted as $hat(theta)_"MLE"$,
  is the value that maximizes the likelihood function:

  $ hat(theta)_"MLE" = limits(arg max)_(theta in Theta) L(theta | x) $

  Intuitively, it is the parameter value that makes the observed data "most probable."
]

We use the MLE to estimate the parameter(s) in a given model with a fixed sampling dataset.
Within this framework, the resulting model maximizes the probability of the observed data,
providing the power to *generalize* to *unseen data*.

== The Log-Likelihood Transformation

#theorem(title: "Log-Likelihood Function")[
  For computational convenience and numerical stability, we define the *log-likelihood* $ell(theta)$ as:
  $ ell(theta) = ln L(theta) $

  Since the logarithm is a monotonically increasing function, we have:
  $ arg max L(theta) = arg max ell(theta) $
]

=== Why Use Log-Likelihood

+ *From Product to Sum:* For i.i.d. samples, $L(theta)=product f(x_i∣theta)$.
  The log transformation converts this into $ell(theta)=sum ln f(x_i∣theta)$,
  which is much easier to differentiate.
+ *Numerical Stability:* Multiplying many small probabilities (e.g., $10^(-3) times 10^(-3) times dots.c$) can lead to arithmetic underflow in computers.
  Summing their logarithms avoids this.
+ *Asymptotic Normality:* Under certain regularity conditions,
  the log-likelihood function behaves like a quadratic surface near its peak,
  which relates to the *Fisher Information*.

== MLE for Discrete Distributions
In discrete cases, we maximize the Probability Mass Function (PMF).

=== Bernoulli Distribution
Used for a single trial with two outcomes (0 or 1).

*PMF:* $f(x|p) = p^x (1-p)^(1-x)$ for $x in {0,1}$.

*Likelihood:* For $N$ samples, let $k = sum x_i$ be the number of successes.
We obtain:
$ L(p) = product_(i=1)^N p^(x_i) (1-p)^(1-x_i) = p^k (1-p)^(N-k) $.


And *Log-Likelihood:*
$ ell(p) = k ln p + (N-k) ln (1-p) $.

Setting $(partial ell) / (partial p) = k/p - (N-k)/(1-p) = 0$ yields:
$ hat(p) = k / N $

=== Poisson Distribution
Used for modeling the number of events occurring within a fixed interval.

*PMF:* $f(x | lambda) = (lambda^x e^(-lambda)) / (x!)$

In terms of the definition, *Likelihood* is
$ L(lambda) = product_(i=1)^N (lambda^x_i e^(-lambda)) / (x_i !) $
, and *Log-Likelihood:*

$
  ell(lambda) = sum_(i=1)^N (x_i ln lambda - lambda - ln x_i !) = (ln lambda) sum x_i - N lambda - sum ln x_i !
$

Setting $(partial ell) / (partial p) = (sum x_i) / lambda -N = 0$ yields:

$ hat(lambda) = 1/N sum_(i=1)^N x_i = overline(x) $

#note[
  Note that the MLE for the variance $hat(sigma)^2 = 1/N sum (x_i - overline(x))^2$ is a *biased estimator*.
  In descriptive statistics, we often use $N-1$ as the denominator (Bessel's correction) to obtain an *unbiased* estimate of the population variance.
  However, the MLE procedure strictly yields $1/N$.
]

== MLE for Continuous Distributions
In continuous cases, we maximize the Probability Density Function (PDF).

=== Gaussian Distribution
The most fundamental distribution in statistics.

*PDF:* $f(x | mu, sigma^2) = frac(1, sqrt(2 pi sigma^2)) exp(- frac((x - mu)^2, 2 sigma^2))$

*Log-Likelihood:*
$
  ell(mu, sigma^2) = - N / 2 ln(2 pi) - N/2 ln(sigma^2) - frac(1, 2 sigma^2) sum_(i=1)^N (x_i - mu)^2
$

*MLE for $mu$:* $(partial ell) / (partial mu) = 1/sigma^2 sum (x_i - mu) = 0$ yields $ hat(mu) = overline(x) $.

*MLE for $sigma^2$:* $(partial ell) / (partial sigma^2) = - N/(2 sigma^2) + 1 / (2 sigma^4) sum_(i=1)^N (x_i - mu)^2 = 0$ yields:
$ hat(sigma)^2 = 1/N sum_(i=1)^N (x_i - overline(x))^2 $.

=== Exponential Distribution
Commonly used to model waiting times between events.

*PDF:* $f(x | lambda) = lambda e^(-lambda x)$ for $x>=0$.

*Log-Likelihood:* $ell(lambda)=N ln lambda - lambda sum_(i=1)^N x_i$.

Therefore:

$ hat(lambda) = N / (sum_(i=1)^N x_i) = 1/ overline(x) $

=== Uniform Distribution $U(0, theta)$
A unique case where the support depends on the parameter.

*PDF*: $f(x | theta) = 1 / theta$ for $0 <= x <= theta$.

We use *likelihood* rather than the log-likelihood here: $L(theta) = cases((1/theta)^N "if " max(x_i) <= theta, 0 "otherwise")$

#note[
  Since $(1/theta)^N$ is a decreasing function of $theta$, to maximize the likelihood, we must choose the _smallest possible value_ for $theta$ that satisfies the condition $theta >= max(x_i)$.
]

*MLE:* $ hat(theta) = max(x_i) $ The sample maximum.

= Statistical Inference: Uncertainty and Fisher Information

While MLE provides a "point estimate", it is equally important to quantify the uncertainty of this estimate.

== Fisher Information

#definition(title: "Fisher Information")[
  The Fisher Information $I(theta)$ is used to quantify the precision of the parameters given a dataset.

  $ I(theta) = -EE_x [ hess ell(theta) ] $<fisher_1>
  or
  $ I(theta) = EE_x [ (grad ell(theta))^2 ] $<fisher_2>
]

The equivalence between @fisher_1 and @fisher_2, as well as the asymptotic normality of MLE, relies on the following *Regularity Conditions (Cramér-Rao Regularity Conditions)*:

+ *Identifiability*: The parameter is identifiable. That is, if $theta_1 != theta_2$, then the probability density functions are distinct: $f(x; theta_1) != f(x; theta_2)$.

+ *Common Support*: The support of the distribution, $cal(X) = {x | f(x; theta) > 0}$, does not depend on the parameter $theta$.

+ *Interior Point*: The true parameter value $theta$ lies in the interior of the parameter space $Theta$ (an open interval).

+ *Differentiability*: The log-likelihood function $log f(x; theta)$ is at least three times continuously differentiable with respect to $theta$ for all $x$.

+ *Interchangeability (Differentiation under the Integral)*: The operations of differentiation and integration can be interchanged. This implies that the derivatives are bounded by integrable functions.
  $
    integral_(-infinity)^(+infinity) grad f(x; theta) dif x = grad integral_(-infinity)^(+infinity) f(x; theta) dif x = 0
  $<regularity>

=== Equivalence

Obviously, $grad f = f dot grad ln f$.
Substituting it into @regularity, we get

$
         integral f(x;theta) grad ln f(x;theta) dif x & = 0 \
  integral (grad ln f(x;theta)) dot f(x; theta) dif x & = 0 \
                             EE_x [ grad ell(theta) ] & = 0
$<score_expectation>

Thus, @fisher_2 is the _Variance_ of $grad ell(theta)$.
Intuitively, @fisher_1 represents the expected curvature (second derivative) of the log-likelihood,
while @fisher_2 represents the expected squared score, which equals the variance of the score function.
From this perspective, they appear to refer to the same thing.

Now, we proceed to prove this mathematically.
Differentiate both sides of @score_expectation,
$
  integral (hess ln f(x;theta)) f(x; theta) + (grad ln f(x;theta)) grad f(x; theta) dif x & = 0 \
  integral (hess ln f(x;theta)) f(x; theta) + (grad ln f(x;theta)) f(x;theta) (grad ln f(x; theta)) dif x & = 0 \
  integral (hess ln f(x;theta)) f(x; theta) dif x + integral (grad ln f(x;theta))^2 f(x;theta) dif x & = 0 \
  EE_x [hess ell(theta)] + EE_x [(grad ell(theta))^2] & = 0 \
  ==> - EE_x [hess ell(theta)] = EE_x [(grad ell(theta))^2]
$

Therefore, the two definitions of Fisher Information are equivalent under the given regularity conditions.
#h(1fr) $square.filled$

== Asymptotic Normality of MLE

#theorem(title: "Asymptotic Normality of MLE")[
  Under the regularity conditions, the Maximum Likelihood Estimator $hat(theta)$ satisfies the asymptotic normality:
  $ sqrt(n)(hat(theta) - theta_0) arrow.r^d cal(N)(0, I(theta_0)^(-1)) $
]
This theorem implies that for large $n$, $hat(theta)$ is approximately:
$ hat(theta) approx cal(N)(theta_0, 1 / (I_n (theta_0))) $

=== Proof: Asymptotic Normality of MLE

Suppose $x_1, x_2, dots, x_n$ are i.i.d. samples from $f(x; theta_0)$, where $theta_0$ is the true parameter.
Let $ell(theta) = sum_(i=1)^n ln f(x_i; theta)$ be the log-likelihood function.

*Step 1: Score Equation and Taylor Expansion*

The MLE $hat(theta)$ is the solution to the likelihood equation:
$ grad ell(hat(theta)) = 0 $

Applying a first-order Taylor expansion to the score function around the true parameter $theta_0$:
$
  underbrace(grad ell(hat(theta)), = 0) approx grad ell(theta_0) + (hat(theta) - theta_0) hess ell(theta_0)
$

Rearranging the terms to isolate $(hat(theta) - theta_0)$:
$
  hat(theta) - theta_0 approx - frac(grad ell(theta_0), hess ell(theta_0))
$

To study the asymptotic behavior, we multiply both sides by $sqrt(n)$:
$
  sqrt(n)(hat(theta) - theta_0) approx frac(frac(1, sqrt(n)) grad ell(theta_0), -frac(1, n) hess ell(theta_0))
$<mle_ratio>

*Step 2: Convergence of the Numerator (CLT)*

#theorem(title: "Lindeberg-Lévy Central Limit Theorem (CLT)")[
  Let $X_1, X_2, dots, X_n$ be i.i.d. random variables with $EE[X_i] = mu$ and $op("Var")(X_i) = sigma^2 < infinity$. Then:
  $ 1/sqrt(n) sum_(i=1)^n (X_i - mu) arrow.r^d cal(N)(0, sigma^2) $
]

The numerator is $frac(1, sqrt(n)) grad ell(theta_0) = frac(1, sqrt(n)) sum_(i=1)^n grad ln f(x_i; theta_0)$.
Let $s(x_i; theta_0) = grad ln f(x_i; theta_0)$ be the score for a single observation. From our previous derivation of Fisher Information:

- $EE_X [s(X; theta_0)] = 0$ (Score expectation is zero)

- $op("Var")_X (s(X; theta_0)) = EE_X [s(X; theta_0)^2] = I(theta_0)$ (Fisher Information)

By the _Central Limit Theorem (CLT)_, as $n -> infinity$:
$
  frac(1, sqrt(n)) sum_(i=1)^n s(x_i; theta_0) arrow.r^d cal(N)(0, I(theta_0))
$

Substituting definition into this equation, we obtain:

$
  1 / sqrt(n) sum_(i=1)^n grad ln f(x_i; theta_0) arrow.r^d cal(N)(0, I(theta_0))
$<clt_numerator>

*Step 3: Convergence of the Denominator (LLN)*

#theorem(title: "Weak Law of Large Numbers (WLLN)")[
  Let $X_1, X_2, dots, X_n$ be i.i.d. random variables with $EE[X_i] = mu$. Then the sample mean converges in probability to the theoretical mean:
  $ overline(X)_n = 1/n sum_(i=1)^n X_i arrow.r^p mu $
]

The denominator is $-frac(1, n) hess ell(theta_0) = -frac(1, n) sum_(i=1)^n hess ln f(x_i; theta_0)$.

By the _Law of Large Numbers (LLN)_:
$
  -frac(1, n) sum_(i=1)^n hess ln f(x_i; theta_0) arrow.r^p EE_X [- hess ln f(X; theta_0)] = I(theta_0)
$<lln_denominator>

*Step 4: Synthesis via Slutsky's Theorem*

#theorem(title: "Slutsky's Theorem")[
  Let $X_n$ and $Y_n$ be sequences of random variables. If $X_n arrow.r^d X$ and $Y_n arrow.r^p c$ (where $c$ is a constant), then:

  + $X_n + Y_n arrow.r^d X + c$

  + $X_n Y_n arrow.r^d c X$

  + $X_n / Y_n arrow.r^d X / c$ (provided $c != 0$)
]

From @mle_ratio, @clt_numerator, and @lln_denominator, we consider the ratio:
$
  sqrt(n)(hat(theta) - theta_0) approx frac(overbrace(1/sqrt(n) sum_i grad ln f(x_i; theta_0), arrow.r^d cal(N)(0, I(theta_0))), underbrace(-1/n sum_i hess ln f(x_i; theta_0), arrow.r^p I(theta_0)))
$

By _Slutsky's Theorem_, since the numerator converges in distribution and the denominator converges in probability to a non-zero constant:
$
  sqrt(n)(hat(theta) - theta_0) arrow.r^d frac(cal(N)(0, I(theta_0)), I(theta_0)) = cal(N)(0, 1 / (I(theta_0)))
$
#h(1fr) $square.filled$

== Confidence Intervals: The Wald Construction

The construction of the Wald interval is not merely a formulaic application but a rigorous progression from the asymptotic normality of the MLE to a practical inferential tool.

=== The Theoretical Foundation
From the previously proven theorem, we have the asymptotic distribution of the MLE:
$ sqrt(n)(hat(theta) - theta_0) arrow.r^d cal(N)(0, I(theta_0)^(-1)) $
This implies that the "standardized" error converges to a standard normal distribution:
$
  Z_n = (hat(theta) - theta_0) / sqrt(1 / (n I(theta_0))) arrow.r^d cal(N)(0, 1)
$
However, $Z_n$ is not a *statistic* because it depends on the unknown true parameter $theta_0$ within its denominator (the variance).

=== Consistency and Variance Estimation

The theoretical variance of the MLE, $op("Var")(hat(theta)) approx [n I(theta_0)]^(-1)$, depends on the true parameter $theta_0$, which is precisely what we are trying to estimate. To bridge this gap, we rely on the *Consistency of MLE* ($hat(theta) arrow.r^p theta_0$). According to the *Continuous Mapping Theorem*, if $I(theta)$ is a continuous function, then $I(hat(theta))$ is a consistent estimator of $I(theta_0)$.

In practice, we use two primary methods to estimate this "precision" of our estimate:

#note()[
  Recall that
  $sqrt(n)(hat(theta) - theta_0) arrow.r^d cal(N)(0, 1 / (I(theta_0)))$.
  Therefore we have
  $ hat(theta) arrow.r^d cal(N)(theta_0, [n I(theta_0)]^(-1)) $,
  which implies $op("Var")(hat(theta)) approx [n I(theta_0)]^(-1)$
]

*Expected Fisher Information (The Plug-in Method)*

The most direct approach is to calculate the theoretical expectation $I(theta) = -EE_X [hess ln f(X; theta)]$ and evaluate it at the estimated point $hat(theta)$.

$ hat(I)_n_"expected" = n I(hat(theta)) $

- *Characteristics*: This represents the average precision we expect to get from a sample of size $n$ under the model $f(x; hat(theta))$.
- *Usage*: It is used when the expectation is easy to compute analytically (e.g., for exponential or normal distributions).

*Observed Fisher Information (The Curvature Method)*

In many real-world scenarios, the expectation in $I(theta)$ is difficult or impossible to solve. We instead use the *Observed Fisher Information*, denoted as $J(hat(theta))$, which is the negative Hessian of the log-likelihood evaluated at the MLE:

$
  J(hat(theta)) = - hess ell(hat(theta)) = - sum_(i=1)^n hess ln f(x_i; hat(theta))
$

- *Mathematical Justification*: By the *Law of Large Numbers*, the average observed curvature converges to the expected curvature:
  $
    1/n J(hat(theta)) approx - 1/n sum_(i=1)^n hess ln f(x_i; theta_0) arrow.r^p EE [- hess ln f(X; theta_0)] = I(theta_0)
  $
- *Intuition*: $J(hat(theta))$ measures the *actual* sharpness of the likelihood peak for the specific data we collected. If the peak is very sharp (high curvature), $J(hat(theta))$ is large, meaning the data has high "resolving power" for the parameter.

*Defining the Estimated Variance $hat(V)_n$*

Since Fisher Information represents the total "knowledge" or "precision" gained from the data, its *reciprocal* naturally represents the uncertainty or "spread" of our estimate. We define the estimated variance of $hat(theta)$ as:

$
  hat(V)_n = cases(
    [n I(hat(theta))]^(-1) & "using Expected Information",
    [J(hat(theta))]^(-1) & "using Observed Information"
  )
$<hatV_defintion>

#note[
  In computer software (like R or Python's `scipy.optimize`), the *Observed Fisher Information* is the standard choice. When the optimizer finds the maximum, it numerically calculates the Hessian matrix at that peak. The inverse of this negative Hessian is the "Estimated Covariance Matrix," providing the $op("SE")$ for all estimated parameters simultaneously.
]

=== Derivation of the Confidence Interval
For a given significance level $alpha$, we seek an interval $[L, U]$ such that $P(L <= theta_0 <= U) = 1 - alpha$. Using the asymptotic pivot $W_n$:
$
  P(-z_(alpha \/ 2) <= (hat(theta) - theta_0) / sqrt(hat(V)_n) <= z_(alpha \/ 2)) approx 1 - alpha
$
Rearranging the inequalities to isolate $theta_0$:
$
  P(hat(theta) - z_(alpha \/ 2) dot sqrt(hat(V)_n) <= theta_0 <= hat(theta) + z_(alpha \/ 2) dot sqrt(hat(V)_n)) approx 1 - alpha
$
Thus, the $(1-alpha)$ *Wald Confidence Interval* is defined as:
$
  C I_(1-alpha) = [hat(theta) - z_(alpha \/ 2) dot sqrt(hat(V)_n), quad hat(theta) + z_(alpha \/ 2) dot sqrt(hat(V)_n)]
$
, where $hat(V)_n$ is defined by @hatV_defintion.

#note[
  The Wald interval is _asymptotically valid_, meaning its *nominal coverage* $P(theta_0 in C I)$ converges to the target $1-alpha$ as $n arrow.r infinity$.

  In practice, its performance depends on the _quadratic approximation_ of the log-likelihood. If $ell(theta)$ is highly skewed or non-quadratic near the peak (common in small samples), the true coverage probability may significantly deviate from $1-alpha$. In such cases, the *Likelihood Ratio (LR) interval* is often more robust.
]

= Likelihood Ratio and Model Comparison

#definition(title: "Likelihood Ratio")[
  The *Likelihood Ratio (LR)* compares the plausibility of two hypotheses, $theta_0$ (null) and $theta_1$ (alternative), given the observed data:
  $ Lambda(x) = frac(L(theta_0 | x), L(theta_1 | x)) $
  In many cases, $theta_0$ represents a restricted version of a more general model $theta in Theta$. Then we define the ratio using the supremum:
  $
    Lambda(x) = frac(sup_(theta in Theta_0) L(theta | x), sup_(theta in Theta) L(theta | x))
  $
]

== The Neyman-Pearson Lemma
A fundamental result in hypothesis testing states that for a simple hypothesis test, the *likelihood ratio test is the most powerful test*. That is, for a fixed type I error probability ($alpha$), the LR test maximizes the power (1 - type II error).

== Wilks' Theorem and Degrees of Freedom
In the case of *nested models* (where the null model is a special case of the alternative), as $N -> infinity$, the statistic:
$ D = -2 ln Lambda = 2 (ell(hat(theta)) - ell(theta_0)) $
asymptotically follows a Chi-squared ($chi^2$) distribution.

#note[
  The *degrees of freedom* ($d f$) for this $chi^2$ distribution is the difference in the number of free parameters between the two models: $d f = dim(Theta) - dim(Theta_0)$.
]

== Model Selection: AIC and BIC
Maximizing likelihood often favors overly complex models (overfitting). To balance goodness-of-fit and model simplicity, we use Information Criteria:

1. *Akaike Information Criterion (AIC):*
  $ "AIC" = 2k - 2 ln(hat(L)) $
2. *Bayesian Information Criterion (BIC):*
  $ "BIC" = k ln N - 2 ln(hat(L)) $

where $hat(L)$ is the maximum likelihood value, $k$ is the number of parameters, and $N$ is the number of samples.

#note[
  - *AIC* is generally better for predictive modeling as it focuses on minimizing the information loss.
  - *BIC* imposes a heavier penalty for parameters as $N$ increases, making it more conservative and better for identifying the "true" model.
]
