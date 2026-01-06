#import "/lib.typ": EE, LL, RR, conf, definition, note, theorem

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
  The Fisher Information $I(theta)$ is used to indicate the confidence of the parameters under given dataset.

  $ I(theta) = -EE_x [ partial^2 / (partial theta^2) ell(theta) ] $<fisher_1>
  or
  $ I(theta) = EE_x [ (partial / (partial theta) ell(theta))^2 ] $<fisher_2>
]

The equivalence between @fisher_1 and @fisher_2, as well as the asymptotic normality of MLE, relies on the following *Regularity Conditions (Cramér-Rao Regularity Conditions)*:

+ *Identifiability*: The parameter is identifiable. That is, if $theta_1 != theta_2$, then the probability density functions are distinct: $f(x; theta_1) != f(x; theta_2)$.

+ *Common Support*: The support of the distribution, $cal(X) = {x | f(x; theta) > 0}$, does not depend on the parameter $theta$.

+ *Interior Point*: The true parameter value $theta$ lies in the interior of the parameter space $Theta$ (an open interval).

+ *Differentiability*: The log-likelihood function $log f(x; theta)$ is at least three times continuously differentiable with respect to $theta$ for all $x$.

+ *Interchangeability (Differentiation under the Integral)*: The operations of differentiation and integration can be interchanged. This implies that the derivatives are bounded by integrable functions.
  $
    integral_(-infinity)^(+infinity) partial / (partial theta) f(x; theta) dif x = partial / (partial theta) integral_(-infinity)^(+infinity) f(x; theta) dif x = 0
  $<regularity>

=== Equivalence

Obviously, $partial / (partial theta) f = f dot partial / (partial theta) ln f$.
Substituting it into @regularity, we get

$
         integral f(x;theta) partial / (partial theta) ln f(x;theta) dif x & = 0 \
  integral (partial / (partial theta) ln f(x;theta)) dot f(x; theta) dif x & = 0 \
                             EE_x [ partial / (partial theta) ell(theta) ] & = 0
$<score_expectation>

Thus, @fisher_2 is the _Variance_ of $partial / (partial theta) ell(theta)$.
Intuitively, the @fisher_1 is the variance of the rate of change,
while the @fisher_2 is the expectation of curvature.
In this side, looks like they refer to the same thing.

Now, we start to proof it mathematically.
Differentiate both side of @score_expectation,
$
  integral (partial^2 / (partial theta^2) ln f(x;theta)) f(x; theta) + (partial / (partial theta) ln f(x;theta)) partial / (partial theta) f(x; theta) dif x & = 0 \
  integral (partial^2 / (partial theta^2) ln f(x;theta)) f(x; theta) + (partial / (partial theta) ln f(x;theta)) f(x;theta) (partial / (partial theta) ln f(x; theta)) dif x & = 0 \
  integral (partial^2 / (partial theta^2) ln f(x;theta)) f(x; theta) dif x + integral (partial / (partial theta) ln f(x;theta))^2 f(x;theta) dif x & = 0 \
  EE_x [partial^2 / (partial theta^2) ell(theta)] + EE_x [(partial / (partial theta) ell(theta))] & = 0
$


// TODO: Add the `Fisher Information`, `Asymptotic Normality of MLE`, `Confidence Intervals (Wald Interval)`

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
