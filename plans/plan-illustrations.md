# 笔记图示计划：MoE 首批与其他笔记候选

## Status
- State: Completed
- Last updated: 2026-10-10
- Note: ILL-1 至 ILL-8 均已验收；本轮实际复查通过，运行时 revision 2 已成功登记三项接受证据、完成任务裁决及 final audit/complete，无未验收项或未裁决结果。

## Risk Class

**Medium**：为数学笔记增加三张解释性图，需要保证箭头、门控曲线及图注不夸大正文结论，并维护可再生成的 SVG。预算：已使用两名只读 scout；最多一名初始 implementer、两名并行独立 reviewer、一轮仅针对父会话采纳 Finding IDs 的整改。

## Goal

先修正现有英文 MoE 笔记中六处函数括号误入下标的问题，再增加三张有明确解释目的、可从源码再生成的矢量图；同时形成当前工作树其他笔记的加图优先清单，本次不批量修改其他笔记。

本计划独立于已完成的 `plans/plan.md`，不改写其交付历史。

## Baseline and Evidence

- 当前工作树：`/home/abel/Code/personal/Note`，分支 `note/deepseek`；暂存区为空。
- 已有改动属于先前交付，必须保留：`Makefile`、`README.md`、两篇 DeepSeek 导航/架构正文，以及未跟踪的 Deep Learning、scripts、plans 内容。
- 根 `MoE_Draft.html` 已在先前验收后删除，不恢复、不重新生成。
- 当前 `notes/` 有 11 篇 Typst 源：DeepSeek 6、Deep Learning 1、Supervised 2、Mathematics 2。扫描未发现正文直接声明的图形；不据此断言模板没有装饰性元素。
- `notes/Mathematics/Statistics/Likelihood.typ` 实际存在且被当前分支跟踪。主题的开发分支不能作为排除当前源码的理由。
- Typst 0.15.1；现有 uv 工具环境有 Matplotlib 3.11.2、NumPy 2.5.3、Pillow 12.3.0，不需要新增 Python 依赖。
- 官方包元数据确认 Fletcher 0.5.8，最低编译器 0.13.0，入口 `src/exports.typ`；其源码依赖 CeTZ 0.3.4，编译时还解析 Oxifmt 0.2.1。不额外直接引入另一版 CeTZ。
- 父会话已执行 Fletcher 节点、箭头及数学标签的最小编译，退出 0、无字体警告。探测 PDF：`build/verification/fletcher-probe.97y7gF/fletcher.pdf`。此探测不是三张正式图的验收。
- 当前用户字体可用；委派执行时可显式设置 `TYPST_FONT_PATHS=/home/abel/.local/share/fonts`，不修改模板或安装字体。
- scout：`b760e0b0-134a-4c30-9d4d-fa549f1169b9` 负责其他笔记候选；`ff52b165-5021-418a-9f43-71b91fb31770` 负责 MoE 语义与最小接入。后者无法执行网络/编译，其包验证缺口已由父会话定向探测补齐。
- 用户报告的排版问题已在本机 Typst 0.15.1 实际重现：`E_i(x_t)` 的 bottom attachment 包含整个 `i(x_t)`；`op("TopK")_i(a_(t,i))` 同样。插入下标结束空格后，参数括号恢复为与基础符号同级的内容。原源中的六处位于 51/55/57/198/204/303 行，行号随加图移动。
- 此缺陷不会导致编译失败，既有数值检查也不覆盖排版绑定；此次新增真实源码/Typst 内容解析回归和受影响公式的渲染核验。

## Acceptance Criteria

- **ILL-1 — 通用正向数据流**：在 Sparse MoE Layer 定义附近增加一张单 token 前向图，区分选择分数、请求支持集、容量接受掩码、融合权重、专家输出和共享分支。图示采用接受后不重新归一化的情形，图注明确其他策略是实现选择；落选仅指本次前向，不能暗示永远不能进入或保证语义专门化。
- **ILL-2 — V3 选择与融合分离**：在现有 V3 固定版本说明附近增加一张路由图。原始 sigmoid 亲和度分出两路：加偏置并经过启用时的分组限制选择索引；按索引提取未加偏置的亲和度，归一化并应用 route scale。引用已有报告与 Gate 提交，不引入未经来源确认的配置。偏置仅加在选择分数不等于它对输出没有间接影响。
- **ILL-3 — top-1 门控曲线**：在 top-1 边界段增加双面板图。两个专家，Delta = a_1 - a_2 > 0，固定 S = {1}、无并列、无 drop、scale = 1；比较选中集合内归一化的权重 1/局部导数 0，与保留完整 softmax 的 sigmoid(Delta)/p(1-p)。导数只称门控权重的固定支持集导数，不冒称完整任务梯度或跨支持集边界的全局导数。
- **ILL-4 — 源码与检查**：结构图使用固定版本 Fletcher，在 MoE 源内维护；函数图提供 Python 生成源码与准备纳入版本控制的 SVG。正常 Typst 构建不要求 Python 或个人工具环境。新增数值逻辑通过公开曲线接口的确定性行为测试；生成器检查失败返回非零。既有 14 项数学/正文映射检查全部保留且通过。固定 SVG 元数据及标识生成，验证同一工具环境内重复生成结果一致，不承诺跨 Matplotlib 版本字节一致。
- **ILL-5 — 编译与展示**：三图用英文图注、正文符号、稳定 figure 标签和正文引用；保持矢量清晰度。实际执行相关构建、直接 Typst 编译、PDF 结构/链接检查，并目视每张正式图的代表页面：无重叠、裁切、过小标签、错误箭头或仅靠颜色表达区别。
- **ILL-6 — 其他笔记清单**：本计划列明当前源码中其他笔记的候选位置、目的和误导边界。候选是建议，不代表已添加或已全面数学审查，不重复复制 MoE 图。
- **ILL-7 — 范围保存**：保留已有工作树和暂存区，不改其他笔记、模板、书目、历史日期或 Makefile；不 stage、commit、push，不安装/升级 Python 或系统包，不切换分支/工作树。除固定绘图包及其传递依赖的缓存解析外，不增加工具链。
- **ILL-8 — 下标/参数边界**：修正六处已有 `TopK` / `E_i` / `E_j` 调用，使下标只包含索引，外层参数括号处于基础符号级别；参数内部的 `t,i` 仍是下标。新增精简标准库检查器读取真实 MoE 源并调用 Typst 内容解析，证明原写法失败、修正后通过，检查新图中的同类写法；mutation 仅在内存中。检查实际作者公式的边界，不开发通用 Typst 解析器、不测试 Typst 框架本身；同级参数还需 PDF 目视核验。

## Must / Should / Deferred

### Must

- 六处排版修复先建立失败回归，再修正源码；不能把编译成功当作排版正确。
- 三图各解释一个具体问题，图注写清所采用的简化与条件。
- 通用图与 V3 图不能混成一套普遍适用的门控算法。
- 结构图源在正文内；曲线 SVG 与其生成代码一并保存，不手工修改生成 SVG。
- 使用既有工具并实际执行验证，报告所有失败和未执行项。

### Should

- 图放在相关解释附近，以图引用连回正文，而非另建重复图册。
- Native 图沿用正文的字体/数学排版，曲线 SVG 将文字转换成路径以减少渲染环境依赖。
- README 只补曲线图再生成/检查命令，明确是可选维护操作。

### Deferred

- 其他笔记的实际绘图，待用户从候选清单选择后另立范围。
- Graphviz、Mermaid、TikZ、通用图形库、统一全仓绘图 API。
- 全仓格式化、构建/CI 改造、依赖迁移、新模型盘点、真实训练或性能复现。
- 对候选笔记发现的无关文字/数学问题进行整改。

## Scope

| 文件 | 操作与边界 |
| --- | --- |
| `plans/plan-illustrations.md` | 父会话维护本次状态、候选清单、进度与接受证据。 |
| `notes/Machine_Learning/Deep_Learning/Mixture_of_Experts.typ` | 修正六处下标/参数边界，引用固定 Fletcher 版本，添加两张本地结构图、一张 SVG 图及其图注/引用；不改写无关理论或附录映射。 |
| `scripts/check_moe_typesetting.py` | 新增针对本笔记 indexed 函数参数边界的真实源码/Typst 内容检查与回归；标准库调用既有 Typst，不做通用解析器或全仓 lint。 |
| `scripts/generate_moe_top1_gate_figure.py` | 新增明确的曲线数值接口、SVG 生成 CLI 与最小确定性检查；仅依赖现有 Matplotlib 与标准库，不使用网络/随机训练。 |
| `assets/diagrams/moe_top1_gate_comparison.svg` | 新增由脚本生成的矢量图，随源保存，允许普通 Typst 构建直接使用。 |
| `README.md` | 仅增加可选图形再生成/检查说明，保留上次改动和所有既有构建入口。 |

不修改 `Makefile`、`templates/lib.typ`、`scripts/check_moe_math.py`、任何书目、其他 DeepSeek/Supervised/Mathematics 正文或旧 `plans/plan.md`。若发现必须扩大范围的阻碍，暂停请求批准。

## Approach

1. 实施前重新核对 branch/index/worktree，并运行现有 `make deep-learning` / `make deepseek` 留下基线；保留所有先前改动。
2. 先针对真实 MoE 源建立下标绑定检查，实际确认原六处失败；修正空格边界后重跑并通过。用 `typst eval --in -` 读取内存中的针对性 metadata，避免新增弃用的 `typst query` 警告。随后建立 top-1 曲线公开数值接口和行为测试，再生成 SVG。采样严格限制正 Delta 域；同一环境两次生成核对可重复性。
3. 使用 `@preview/fletcher:0.5.8` 添加两张结构图；插入 gate 对比 SVG，完善英文图注及正文引用。对图中每条数据边、索引边、掩码与分组约束核对正文。
4. 补最短 README 可选再生成说明；运行数学、生成器、编译和 PDF 核验。
5. 两名 reviewer 并行做 requirements 与 maintainability 审查；父会话裁决，仅将采纳的 Finding IDs 发给最多一轮整改，之后定向验证并接受证据。
6. 当前其他笔记只输出下列候选建议，不修改它们。

## 其他笔记候选

优先级综合读者收益与首张图的实现成本；不是缺图严重性，也不是必须逐篇执行。

| 优先级 | 当前源码与位置 | 首张图的目的 | 必须避免的误导 |
| --- | --- | --- | --- |
| 高 | `Supervised/K-Nearest_Neighbors.typ:25`，The K-NN Algorithm | 二维固定样本、查询点、选中邻居与多数投票；CeTZ 或 Matplotlib。 | 二维欧氏例子不是高维定理证明；距离和 tie 规则须声明。 |
| 高 | `Supervised/Naive_Bayes.typ:68`，Naive Bayes Model | Y 指向各特征的因子化图，解释给定类别的条件独立；Fletcher。 | 不是因果图，也不是特征边缘独立。 |
| 高 | `Mathematics/Statistics/Likelihood.typ:70`，Bernoulli Distribution | 固定 N、k 比较 L(p) 与 log L(p) 的相同最大值；Matplotlib。 | 似然不是参数概率密度；不画成归一化 posterior，不承诺泛化。 |
| 高 | `DeepSeek/DeepSeek_Architecture.typ:56`，MLA | 对照 MHA/MLA 的 latent、RoPE key、重建与 KV 缓存位置；Fletcher/CeTZ。 | 缓存比例不是通用运行时/FLOPs 节省，MHA 基准须明确。 |
| 高 | `DeepSeek/DeepSeek_Reasoning.typ:92`，Multi-stage R1 | 分开展示 R1-Zero 与后续多阶段 R1 训练路线；Fletcher。 | 不把流程顺序当充分因果证明，不投射到未核对版本。 |
| 中 | `Mathematics/Analysis/Cauchy-Schwarz_Inequality.typ:49`，Condition for Equality | 二维向量投影、夹角和共线时取等的几何直觉；CeTZ。 | 只作欧氏示意，不替代一般内积空间证明。 |
| 中 | `DeepSeek/DeepSeek_Systems.typ:41`，DualPipe | 简化 compute 与 dispatch/combine 时间条及重叠区；CeTZ。 | 不是官方精确调度 trace 或吞吐保证。 |
| 中 | `DeepSeek/DeepSeek_Multimodal.typ:32`，DeepSeek-VL2 | thumbnail/tiles、feature grid 压缩与视觉 token budget；CeTZ。 | 压缩尺寸必须对应明确例子；不混同不同视觉编码器。 |

表中 DeepSeek/Supervised 路径前缀为 `notes/Machine_Learning/`，Mathematics 前缀为 `notes/`。Overview 的分泳道时间线也有潜力，但已有完整日期表，首批候选优先解释算法与数据流，不另做模型发布日期核对。

## Verification Commands

以下为 Nushell 交互语法。实际结果以初始与整改验证目录的记录为准；重复执行被工具拒绝的父会话请求不计为执行或通过。

```nu
cd /home/abel/Code/personal/Note
git status --short --branch
git diff --cached --stat
uv run --offline --project /home/abel/Tools/pyenvs/pi-python-repl python scripts/check_moe_typesetting.py
uv run --offline --project /home/abel/Tools/pyenvs/pi-python-repl python scripts/generate_moe_top1_gate_figure.py --check
uv run --offline --project /home/abel/Tools/pyenvs/pi-python-repl python scripts/generate_moe_top1_gate_figure.py
uv run --offline --project /home/abel/Tools/pyenvs/pi-python-repl python scripts/check_moe_math.py
with-env { TYPST_FONT_PATHS: "/home/abel/.local/share/fonts" } {
  make deep-learning
  make deepseek
  make ml
  typst compile --root . notes/Machine_Learning/Deep_Learning/Mixture_of_Experts.typ build/Machine_Learning/Deep_Learning/Mixture_of_Experts.pdf
}
qpdf --check build/Machine_Learning/Deep_Learning/Mixture_of_Experts.pdf
qpdf --show-npages build/Machine_Learning/Deep_Learning/Mixture_of_Experts.pdf
git diff --check
```

另须实际核对：下标/参数检查在原源失败、修正源通过，以及内存中恢复错误写法时失败；实际公式内容绑定与 PDF 中的同级括号；生成器公开数值接口的解析值/局部有限差分与非法域行为；同环境重复生成一致；新文件空白/style；全部图标签/引用/固定来源可解析；SVG 与三张图的 PDF 代表页；原有相对 PDF URI 与目标；新旧图形/字体诊断；旧 HTML 仍不存在。遵循 `pdf-tools`，用现有 qpdf/Ghostscript/ImageMagick，不安装 PDF 工具或字体。

## Review Modes and Budget

- requirements：只检查 ILL-1 至 ILL-8，重点修正公式的脚标/参数层级、图的数学条件、箭头含义、符号与简化边界。
- maintainability：只检查当前图示增量、生成器公开接口/CLI/测试、可再生成性、依赖与正常构建边界。
- 审查使用 `bounded-code-review`，涉及 Python 测试/注释使用 `testing-and-comments`。
- **Maximum Remediation Rounds: 1**；Minor/Nit 不自动阻塞，不为了消灭全部建议反复审查。
- 代理显式使用当前用户许可的 `nowcoding/gpt-5.6-terra`，不自动扩大模型授权，不回退 DeepSeek。

## Goal Continuity

用户已于 2026-10-09 回复“一并改了”，批准本具体计划及六处排版修正。新建 branch-local goal，以 ILL-1 至 ILL-8 为稳定 requirement IDs，绑定后续实施/审查任务。本文件是本次唯一进度记录；旧 MoE 交付目标与计划保持完成状态。

父会话必须审阅结果、显式接受证据并更新本计划，再请求 final audit、记录接受证据、明确完成目标。运行结束本身不是验收。

2026-10-10 收尾裁决：当前会话没有恢复旧 branch-local goal，已从本计划重建验收目标并重新执行实际核验。现有调用接口将应省略的 `goalEvidence.revalidateFromRevision` 声明为必填；同 revision 的登记请求因而仍被工具校验拒绝。失败请求未计为 runtime acceptance。为使用工具已支持的旧版本证据复核机制，目标作了一次必要的接口兼容修订至 revision 2，ILL-1 至 ILL-8 及批准范围原样保留。父会话已明确核对 revision 1 任务的实际观察与当前文件/命令证据，成功登记三项接受证据、裁决两个中断任务，并执行 final audit/complete；运行时状态为 completed。此步骤未恢复或冒认历史任务、未删减验收要求、未另开实施或全面审查轮次。

## Risks / Alternatives Considered

- 直接修改所有笔记：超出“顺便看看”的合理边界，候选本次只报告。
- 全部用外部 SVG：结构图会增加独立渲染/数学标签维护流程，因此优先 native Fletcher。
- 自动生成 SVG 成为 `make all` 前置条件：会强制依赖个人 uv 环境；采用随源保存的生成 SVG、可选再生成命令，不改 Makefile。
- 同时直接引入最新 CeTZ：可能与 Fletcher 的传递版本并存；本次无必要。
- Python 图跨支持集边界：可能错误暗示梯度连续/全局零梯度；只展示严格正 Delta 的固定支持集算例。
- 单次预览成功代替验收：最小 probe 只证明基础 API 可用，正式图仍必须检查布局、语义、引用与可重复性。

## Exit Criteria

- ILL-1 至 ILL-8 均有父会话接受证据。
- 下标/参数失败再通过回归、生成器检查、既有 14 项检查、相关构建/直接编译实际通过；修正公式及三正式图的 PDF 页面经检查。
- 无未解决的范围内 Blocker/Major，其他笔记未被本次修改。
- 保留既有用户改动、旧计划/目标，不新增未批准依赖，无 stage/commit/push。
- 只有满足以上条件才标记 Completed；关键验证受阻则 Paused 并说明。

## Progress

- [x] 用户认可按需配图、代码生成、矢量输出，并同意先为 MoE 补三图及调查其他笔记。
- [x] 重新核对当前工作树和空暂存区；保留上次交付。
- [x] 两项只读 scout 完成；父会话消费结果，不重复全仓调查。
- [x] 定向补齐 Fletcher 正式版本/传递依赖与最小实际编译；未修改正式笔记。
- [x] 定向确认当前分支存在 Likelihood 源码，阅读 Bernoulli 段补入候选。
- [x] 固定三图语义、最小文件范围、候选清单与验证/审查预算。
- [x] 用户批准本具体计划，并明确一并修正已诊断的六处下标/参数绑定错误；新增精简真实源码回归检查，其他正文只报告候选。
- [x] 建立 `moe-illustrations-and-typesetting` revision 1；ILL-6 候选清单已接受，证据 `illustration-opportunities-accepted`。
- 初始实施：`9725baa2-0f6f-40cd-a86b-f258d488d422` 已完成，父会话接受阶段交付与 ILL-7 范围保存，证据 `illustration-initial-scope-preservation`；基线/快照/执行/PNG 记录在 `build/verification/illustrations-9725baa2-initial/`。
- [x] 初始执行排版 before-fail（六处，exit 1）/after-pass（exit 0）与内存 mutation（六处拒绝）、生成器检查 4/4、旧检查 14/14；三构建和直接编译通过且无字体警告，PDF 为 13/11/10 页。代表页由实施代理和独立审查实际目视，父会话已接受三图语义及代表公式的参数层级。
- [x] 两项独立审查完成且父会话统一裁决：requirements `03f72648-4466-44d8-b807-08734a35ce4b`、maintainability `1793564a-3909-4604-bb86-4aba7b652a89`；ILL-2/ILL-3 语义已接受，证据 `illustration-requirements-review-adjudicated`。
- 采纳 `REQ-ILL-001`（Major）：共享分支实线穿过 dropped-pair 框，父会话目视确认；只重路由 Figure 1 使共享边绕过 dropped-pair，保留 mask 到 drop 的唯一虚线。
- 采纳 `MAINT-ILL-001`（Major）：Typst subprocess 缺 timeout，源读取及 OSError/TimeoutExpired 不在清晰失败边界；补有限超时与公开 CLI 失败回归，不使用 sleep 或真实挂起。
- 采纳 `MAINT-ILL-002`（Minor）：既有非法域行为测试补空序列 fixture，不改曲线数值或 SVG。
- 采纳 `MAINT-ILL-003`（Minor）：限数学上下文扫描，忽略非数学字符串/注释，去除定义标题精确格式依赖。保护区仍须恰好六个原作者调用；不能简单把边界扩大到新图而重复计算同名公式，也不能弱化计数。可使用一个最小稳定 source anchor 或等价容忍换行的局部边界，不建设通用 lexer/parser。
- [x] 父会话已实际目视 p3/p7 修正公式和最终 p4/p8/p11 三图；共享边现从 dropped-pair 下方绕行并独立进入输出。数值通过不替代排版验证。
- 唯一整改任务：`5d2c8188-528a-44c2-b755-733fdea11ae9` 已完成四项采纳 Findings；仅修改 Figure 1/必要最小 source anchor、两个新脚本的对应边界，其他源/SVG/README 不动。
- [x] 唯一一轮四项采纳 Findings 的最小整改及定向回归：7 项排版回归、4 项曲线检查、14 项原检查全部通过；超时/文件缺失失败是标准库模拟边界，六个错误绑定使用实际 Typst 内容检查，不声称真实挂起实验。
- [x] 三构建、直接 MoE 编译、qpdf 与现有 PDF URI/目标通过；MoE/Architecture/Overview 为 13/11/10 页。证据：`build/verification/illustrations-remediation-4findings/verification-summary.txt` 及同目录 before/after、代表 PNG。
- [x] 父会话最终窄核验：三个正式源及 SVG 的 SHA-256 与整改记录一致；`git diff --check` 通过，暂存区为空，仍在 `note/deepseek`，既有改动保留。本次核验没有再次运行构建或数值检查。
- [x] 父会话接受 ILL-1/4/5/7/8 的最终交付与整改证据，ILL-2/3/6 的既有接受仍适用；无剩余范围内 Major。
- 工具登记历史：同 revision 的 `record` 应省略 `goalEvidence.revalidateFromRevision`，但原请求带该字段而被拒绝。2026-10-10 续接时再次确认接口无法省略该必填字段，同版本登记仍未成功；所有拒绝均不计为通过。已停止重复请求，并作一次必要的接口兼容修订至 revision 2，使用明确的旧版本复核机制，保留全部 requirement IDs 与范围。
- 工具启动测试 `0e87d60c-0255-4737-a81b-389527851e44` 只返回确认、没有读写项目；本会话不认领旧任务，不将它用作任何 requirement 的证据。
- [x] 2026-10-10 重新核对正式正文、两脚本及 SVG 的 SHA-256，均与最终整改记录精确一致；本轮只更新本计划和忽略的验证产物，不修改已交付实现。
- [x] 本轮实际检查：真实源码排版检查、7 项排版回归、4 项曲线检查、14 项数学/正文映射检查全部退出 0；同环境两次 SVG 生成相同且与现有资产字节一致。生成输出位于验证目录，未覆盖正式 SVG。
- [x] 本轮实际构建：`make deep-learning deepseek ml`、直接 MoE Typst 编译均退出 0，无新增诊断；三份 PDF 的 qpdf 检查通过，页数为 13/11/10。
- [x] 本轮实际解析三份 PDF 的相对 URI，核对每个本地 PDF 目标及双向 MoE/DeepSeek 导航；四张当前代表页已渲染，公式括号及三图显示经窄核对。
- 续接任务 `11b38c52-ae0e-4f2b-a397-f61b762004c1` 与 `e2b5fbf7-48db-4492-aeb3-d5ac09dbb250` 分别遇到上游 HTTP/2 和响应流中断，没有完整终稿，不计为成功的独立审查。第二项中断前已目视四张当前页面并报告公式参数层级、共享/drop 边、曲线及 V3 两路均正确；父会话仅结合当前文件校验和、实际执行日志及既有独立审查接受这部分观察，不将任务运行状态当作通过。
- [x] 父会话接受以下当前文件/命令证据，ILL-1 至 ILL-8 全部满足，无剩余范围内 Blocker/Major。
- [x] 运行时 revision 2 已显式写入 `final-scope-preservation-revalidated`、`final-delivery-current-checks-revalidated`、`final-audit-parent-accepted` 三项接受证据；已请求最终审计、再登记父会话最终验收并执行 `complete`，实际状态为 completed，无 pending requirements、active jobs 或 unadjudicated results。
- 任务裁决：第一项中断核对任务的终稿被拒绝；第二项只接受中断前实际完成的四页目视观察，并由当前文件与父会话实际命令复核。两项运行状态仍保留 failed，不冒称成功运行；其原 revision 1 证据在 revision 2 经明确复核后才计入验收。

### 2026-10-10 最终验收证据

本轮证据目录：`build/verification/moe-illustrations-final-20261010.KHBP5J/`。`results.txt` 记录实际退出状态；详细命令在 `commands.txt`，各检查有对应日志。历史审查及整改证据继续保留，不将旧 job IDs 冒认成本会话拥有的任务。

| 验收项 | 父会话接受的证据 |
| --- | --- |
| ILL-1 | 当前 MoE 源与最终整改快照一致；共享边独立绕过 dropped-pair 框；当前 `current-forward-flow-p4.png` 的窄目视观察及既有审查一致。 |
| ILL-2 | 固定 V3 `Gate` 来源、未加偏置亲和度融合、启用时分组限制与 route scale 在当前源和图注中保留；当前 `current-v3-flow-p11.png` 与既有接受一致。 |
| ILL-3 | 正 Delta、固定支持集、无 drop、scale 为 1 的图注边界保留；`top1-curves.log` 的 4/4 公开接口检查及当前 `current-top1-curves-p8.png` 通过。 |
| ILL-4 | Fletcher 固定版本未变；`math-and-mapping.log` 为 14/14；两次生成及正式 SVG 的比较均退出 0，`svg-hashes.txt` 三项一致；普通 Typst 构建无需执行生成器。 |
| ILL-5 | `related-builds.log`、`direct-moe-compile.log`、三份 `qpdf-*.log` 均通过；`pdf-links.json` 的相对链接目标全部存在；四张当前代表页已核对。 |
| ILL-6 | 本计划八项其他笔记候选及其目的、误导边界保留；当前受保护笔记校验和保持，本次未实施候选图。 |
| ILL-7 | `protected-hashes-before.txt` 的相关正式文件在检查及构建后复核通过；分支仍为 `note/deepseek`，HEAD 未变、暂存区为空，原 HTML 仍不存在；未安装依赖、提交或推送。 |
| ILL-8 | `typesetting.log` 检查真实正文通过，`typesetting-regressions.log` 为 7 项通过；实际 Typst 内容检查覆盖六处错误绑定的内存回退；当前 p3 的参数括号层级与既有验收一致。 |

运行时目标 `moe-illustrations-and-typesetting` revision 2 已完成。接受证据登记、任务裁决及 final audit/complete 均实际成功；失败请求与上游中断保留为诊断，不计作通过。项目计划与运行时验收状态一致。
