#import "/templates/lib.typ": conf

// Set Metadata
#set document(
  title: "Expression",
  author: "Abel Zhan",
)

// Apply Template
#show: conf

= Introduction
写出严谨、地道的数学笔记，不仅需要正确的公式，还需要精准的“数学衔接语”。

按功能场景分类：

= 设定前提与假设 (Assumptions & Settings)
在引入变量或空间时使用：

- *Let... be...*: 设……为……
  - _Example:_ Let $X$ be a random vector in $RR^n$.
- *Assume that / Suppose that*: 假设……
  - _Example:_ Assume that the samples are drawn i.i.d. from $P(X, Y)$.
- *Consider...*: 考虑……
  - _Example:_ Consider the case where the loss function is symmetric.
- *Given...*: 已知……
  - _Example:_ Given a training set $T$, we aim to estimate...
- *Without loss of generality (WLOG)*: 不失一般性地（数学笔记神句，用于简化条件但不影响结论）。
  - _Example:_ WLOG, we assume the classes are indexed from $1$ to $K$.

= 定义与命名 (Definitions & Notation)
- *Denote... by / as...*: 将……记作……
  - _Example:_ We denote the posterior probability by $P(Y|X)$.
- *Defined as / Given by*: 定义为……
  - _Example:_ The risk is defined as the expectation of the loss function.
- *In terms of...*: 根据……/用……来表示
  - _Example:_ The risk can be expressed in terms of the conditional density.
- *Equivalently*: 等价地
  - _Example:_ Equivalently, we can maximize the log-likelihood.

= 逻辑推导衔接 (Logical Transitions)
这是让笔记“通顺”的关键：

- *It follows that...*: 由此得出/由此可见（接推导结果）。
- *Consequently / Hence / Thus / Therefore*: 因此（用于结论）。
- *Substituting... into...*: 将……代入……
  - _Example:_ Substituting (1) into (2), we obtain...
- *Rearranging terms*: 整理项/移项后。
- *Applying...*: 应用（定理/规则）。
  - _Example:_ Applying Bayes' Theorem, we have...
- *Integrating both sides*: 对两边求积分。
- *Taking the derivative w.r.t. $x$*: 对 $x$ 求导。
- *Setting... to zero*: 令……为零。

= 条件与约束 (Conditions & Constraints)
- *Subject to / Constrained by*: 受……约束（常用于最优化）。
  - _Example:_ Maximize $f(x)$ subject to $sum x_i = 1$.
- *Provided that / If and only if (iff)*: 只要……/当且仅当。
- *Sufficient and necessary condition*: 充要条件。
- *Satisfying...*: 满足……
  - _Example:_ Find a function $f$ satisfying the boundary conditions.

= 常见缩写与术语 (Abbreviations)
- *i.i.d.* (independent and identically distributed): 独立同分布。
- *w.r.t.* (with respect to): 关于（如：求导关于某变量）。
- *s.t.* (such that / subject to): 使得 / 受限于。
- *lhs / rhs* (left-hand side / right-hand side): 等式左/右手边。
- *q.e.d.* (quod erat demonstrandum): 证明完毕（现在常用黑色方块 $square$ 代替）。
- *viz.* (videlicet): 即（相当于 "namely"）。

= 阐述合理性与直觉 (Intuition & Justification)
- *Intuitively*: 直观上。
- *Informally*: 非正式地（用于通俗解释）。
- *To justify...*: 为了证明……的合理性。
- *It is worth noting that...*: 值得注意的是……
- *Consistent with...*: 与……一致。
  - _Example:_ This result is consistent with our empirical observations.

= 进阶地道表达（避开中式英语）
- *不要总用 $1 + 1 = 2$ is correct*，改用 *The identity holds* (等式成立)。
- *不要用 "we can get"*，改用 *We obtain* 或 *We yield*。
- *不要用 "because of..." 开头*，改用 *By virtue of...* 或 *In view of...*。
- *不要用 "the same as"*，改用 *Identical to*。

= 建议在笔记中使用的“起手式”模版：
+ *引入目标：* "Our objective is to minimize..."
+ *指出手段：* "This can be achieved by..."
+ *引用前文：* "Recall from Equation (1) that..."
+ *得出结论：* "In summary, we have shown that..."
