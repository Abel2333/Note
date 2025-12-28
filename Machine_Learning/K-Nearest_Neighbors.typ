#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2.5cm),
)
#set text(font: "Liberation Serif", size: 11pt)
#set heading(numbering: "1. ")
#set math.equation(numbering: "(1)")

= K-Nearest Neighbors (KNN) & Theoretical Error Bounds

== Preliminaries & Notation

Before diving into bounds, establish the mathematical setting.

- *Dataset:* $cal(D)_n = {(X_1, Y_1), ..., (X_n, Y_n)}$ where $X in RR^d$ and $Y in {1, 2, ..., M}$ (Multiple Classification).
- *Distance Metric:* Usually Euclidean distance $norm(x-x')$

=== The K-NN Algorithm

For a target point $x_t$, compute the distance to every point in the training set $cal(D)_n$. Identify the set of $k$ points that are nearest to $x_t$.

The predicted class $hat(y)$ is determined by a *majority vote*: it corresponds to the most frequent class among these chosen Neighbors.

_Note:_ In the remainder of this article, we will focus on the theoretical analysis of the case where $k = 1$ (1-Nearest Neighbor).

== The Bayes Optimal Classifier

For the Multi-class classification problem ($M$ classes).

Let $eta_c (x) = P(Y=c | X=x)$. The Bayes optimal classifier $C^*$ minimizes the probability of error by choosing the most likely class:

$ C^*(x) = limits(arg max)_(c_in {1, ..., M}) eta_c (x) $

And the conditional Bayes error (risk) at point $x$, denoted as  $r^* (x)$, is the probability of failing to predict the correct class:

$ r^* (x) = 1 - max_c eta_c (x) $

The overall Bayes error rate $R^*$ is the expectation of this conditional error:

$ R^* = E_x [1 - max_c eta_c (X)] $

== Asymptotic Error of 1-NN (Cover-Hart)
