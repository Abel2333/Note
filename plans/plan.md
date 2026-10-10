# MoE 笔记整合计划

## Status
- State: Completed
- Last updated: 2026-10-09
- Note: AC-1 至 AC-9、两项独立审查及唯一一轮整改均已验收；原 HTML 已删除，删除后核验通过。

## Summary

在 DeepSeek 笔记所在分支新增一篇通用 MoE 笔记，将基础定义、梯度和均衡机制与 DeepSeek 的具体实现分层。根目录 `MoE_Draft.html` 在实施、核验和审查期间作为待校正的输入材料保留，不原样转写、不成为构建依赖；正式笔记验收通过后，按用户明确要求删除该 HTML。

正式笔记拟继续使用英文，计划与讨论使用中文。批准本计划即确认这一语言选择；也可以先要求调整。

## Risk Class

**Medium**：涉及数学正确性、多个文档的内容边界、引用与跨 PDF 导航，以及构建入口。没有服务、数据迁移或依赖升级。最大的风险是把特定门控下的局部推导误写成所有 MoE 的全局训练保证。

## Goal

建立一篇可独立阅读、可追溯来源、可编译的 MoE 原理笔记，并让现有 DeepSeek 集合能够从它获取基础解释，而不重复维护两套通用推导。

## Baseline and Evidence

- 工作目录：`/home/abel/Code/personal/Note`。
- 实施分支：`note/deepseek`；计划基线提交：`3c049ce28024fd3d89ff6e09220b8aa76cf67494`。
- 切换前暂存区和已跟踪工作树均无改动；唯一未跟踪输入是 `MoE_Draft.html`。
- 草稿切换前后 SHA-256 均为 `de754a616a9f152832c093d1dd9b40e6319e4152e713076a96e4261b514e4d8e`。
- `DeepSeek_Architecture.typ:16-54` 已介绍通用稀疏层、细粒度切分、共享专家和通信后果；`:102-116` 已区分偏置选择分数与融合权重。
- `DeepSeek_Systems.typ:37-62` 已介绍 DualPipe、DeepEP/EPLB、通信与硬件成本；这些具体系统内容不迁移到新笔记。
- `DeepSeek_Overview.typ` 使用相对 PDF 链接组织阅读路径；`DeepSeek_Evidence.typ:145` 使用集合自己的 `references.bib`。
- `make deepseek` 已采用严格失败传播；`make ml` 目前只发现 `Supervised/`，且旧循环含 `|| true`。
- 已确认本机有 Typst 0.15.1、uv 和现有 `~/Tools/pyenvs/pi-python-repl` 工具环境；没有 typstyle。
- 已完成全文静态数学审查及关键一手来源复核。历史数值程序未执行，不能将它们记录成通过的测试；本计划补上离线、确定性的算例核验。

## Acceptance Criteria

- **AC-1 — 独立内容与语言**：新增英文 `Mixture_of_Experts.typ`，沿用现有模板；不依赖读者先读 DeepSeek 集合，也不要求新增 Transformer 前置文档。
- **AC-2 — 数学边界**：明确选择分数、融合权重、容量接受掩码和共享分支。正确区分选中集合内归一化与保留完整 softmax 概率的门控；覆盖 top-1 边界、局部梯度与支持集变化、stop-gradient 均衡项及 z-loss 的作用范围。
- **AC-3 — 账本与工程边界**：分开总参数、激活参数、权重存储、激活张量、KV、通信和训练状态；声明比较基准和 MAC/FLOPs 约定。容量不是架构必要条件；部分通路 drop 不等于整个 MoE 输出归零。
- **AC-4 — 架构实例与来源**：分别介绍 Switch、Mixtral、DeepSeekMoE/V3，不将某个实例写成统一定义。V3 明确使用 sigmoid 亲和度加偏置选择、未加偏置的亲和度融合，并标出实现缩放、分组限制及小序列级辅助项的来源和适用版本。
- **AC-5 — 内容去重与导航**：通用公式和主要推导只有一个规范位置；DeepSeek 架构笔记保留模型特有解释和必要简式，从 Overview/Architecture 可到达通用笔记，并可返回相关 DeepSeek 内容。相对 PDF 链接与实际输出目录一致。
- **AC-6 — 可运行的数学核验**：新增纯 Python 标准库检查脚本，对正文中的关键算例和反例作确定性核验，运行失败必须返回非零状态。检查只验证有限算例及局部公式，不宣称证明模型质量、专家分化或全局收敛。
- **AC-7 — 构建与展示**：新增严格的 `deep-learning` 构建目标，`make ml` 通过依赖发现它，`make all` 保持包含 DeepSeek 集合。新笔记和受影响的 DeepSeek 笔记编译成功；公式、表格、引用和代表性页面经检查，无新增未解决诊断。
- **AC-8 — 保存与范围**：最终清理条件达到前，不改写、移动或删除原 HTML，且不将其提交；不改 Likelihood 或其他无关笔记，不安装项目依赖、不提交、不推送。现有六篇 DeepSeek 笔记及其原有阅读能力保留。
- **AC-9 — 验收后清理**：AC-1 至 AC-8 获父会话验收、独立审查与必要整改完成后，仅删除根目录 `MoE_Draft.html`。删除前校验其仍为本次审查的原始文件；若内容已变，暂停清理并询问用户。删除后确认文件不存在，并重跑数学检查及相关构建，证明正式笔记不依赖 HTML。

## Must / Should / Deferred

### Must

- 修正草稿中被接受的技术问题，而不是保留其强断言后仅增加引用。
- 区分通用定义、条件性数学结论、具体实现和来源报告的实验结果。
- 所有命题显式列出必要条件；经验性结论不放入定理框。
- 给关键反例建立正文/附录标签，并与数学检查脚本逐项对应。
- 更新最小导航与构建入口，运行验证并保留结果。
- 将单文件 HTML 清理放在验收通过后的最后收尾阶段；实施尚未结束或关键核验受阻时不得提前删除。

### Should

- 在相关章节附近放简短误区说明，代替另写一套重复 FAQ 和公式速查。
- 用一个小型前向算例串起选择、归一化、专家计算、容量接受和融合。
- 提供简洁的架构比较表；符号在各文档内保持一致，跨文档说明映射，不进行全仓符号重命名。

### Deferred

- top-k 熵、互信息与专门化的完整信息论形式化。
- 容量尾概率的完整定理和偏置控制器的收敛理论；首版只说明条件和局限，不保留无依据的概率/收敛保证。
- 全套 Transformer/Attention/反向传播前置笔记，以及将 MoE 拆成多篇专题。
- 新模型版本盘点、真实训练/吞吐复现和 GPU 内核实现。
- 全仓共享文献库迁移、文档站点、CI、全局格式化器和其他构建目标的历史失败处理。

## Non-goals

- 不把 HTML 的 34 章逐章转换成 Typst，不维护中英文两份规范正文。
- 不全面重审 DeepSeek V4/V4.1、时间线或其他专题，不刷新集合整体的 as-of 日期。
- 不把通用 MoE 内容全部塞进 `DeepSeek_Architecture.typ`。
- 不在其他分支或工作树实施，不自动扩大前次高性能审查模型的一次性授权。

## Scope

| 文件 | 操作与边界 |
| --- | --- |
| `plans/plan.md` | 当前计划；父会话维护状态、验收证据和进度。 |
| `MoE_Draft.html` | 实施与审查期间保持原样；验收后仅删除此根目录文件，不批量清理、不另留重复 HTML。 |
| `notes/Machine_Learning/Deep_Learning/Mixture_of_Experts.typ` | 新增通用 MoE 正文及必要数学附录。 |
| `notes/Machine_Learning/Deep_Learning/references.bib` | 新增本专题自己的文献记录；不让基础笔记依赖 DeepSeek 专属目录，不迁移原集合文献库。 |
| `notes/Machine_Learning/DeepSeek/DeepSeek_Architecture.typ` | 仅调整 MoE/均衡相关段落、相应符号说明与交叉链接；保留细粒度切分、共享专家和模型特有解释。 |
| `notes/Machine_Learning/DeepSeek/DeepSeek_Overview.typ` | 仅补充 MoE 基础阅读入口及阅读顺序；保留六篇集合的结构和时间线。 |
| `scripts/check_moe_math.py` | 新增可独立运行的确定性数学检查；不读取网络，不依赖 notebook/kernel 状态，不引入 Python 包。 |
| `Makefile` | 新增严格的 `deep-learning` 目标和 `ml` 依赖，更新 `.PHONY`/帮助；保持现有严格 `deepseek` 目标，不顺手重写无关循环。 |
| `README.md` | 增加 Deep Learning 分类、新笔记入口及对应构建命令。 |

`DeepSeek_Systems.typ`、`DeepSeek_Evidence.typ`、原 `DeepSeek/references.bib`、模板及其他主题首版不修改。书目元数据可为专题自包含而重复，通用理论正文不能重复维护。

若实施时发现上述边界外必须修正的问题，先暂停并请求调整计划，不静默扩大范围。

## Approach

### Phase 1 — 固定术语、来源和数学边界

开始修改正文前，重新检查当前分支、暂存区、工作树和草稿校验和，并先执行 `make deepseek` 留下原集合的编译基线。若出现原有失败，只记录并报告；不得修改无关内容来使基线通过。

1. 使用 FFN 作为 Transformer 前馈子层术语；说明本笔记聚焦常见 Transformer FFN-MoE，而不是所有历史 MoE 模型。
2. 固定路由统计组、token 数、专家数、选中数、共享专家数及容量前后负载的定义。
3. 将选择分数与融合权重分开；明确归一化位置、drop 后是否再归一化以及共享分支系数。
4. 为每个模型实例冻结论文版本和官方实现版本，核对书目元数据，不凭集合作者或搜索摘要推断完整作者列表。

首版主要来源：Shazeer 2017 (`1701.06538`)、Switch (`2101.03961` / JMLR)、ST-MoE (`2202.08906`)、Mixtral (`2401.04088`)、DeepSeekMoE (`2401.06066`)、Auxiliary-Loss-Free Balancing (`2408.15664`)、DeepSeek-V3 (`2412.19437`) 和 MegaBlocks (`2211.15841`)。实现以 DeepSeek 官方 `inference/model.py` 的固定 commit 为补充，论文公式与代码中的缩放/限制分别标注。

### Phase 2 — 建立算例核验，再写通用笔记

先建立并运行有限算例检查，作为正文的数学验收基线：

- 选中集合固定且无并列时，归一化 top-k 梯度与有限差分一致；归一化 top-1 该路径任务梯度为零。
- 保留完整 softmax 概率的 top-1 有不同的梯度性质。
- 仅更新当前选中 logits，也可以让原来落选的专家进入支持集。
- z-loss 为零时 logit 跨度仍可任意大；不能据此保证救援梯度。
- 均匀 `f` 时均衡梯度静默；均匀 `p` 但失衡 `f` 时 stop-gradient 更新不必为零。
- 部分专家通路 drop 后，其余通路和共享分支仍可非零。
- 固定步长 sign 偏置反馈可以振荡；在 logits 上加偏置与在 sigmoid 亲和度上加偏置不等价。

每项使用固定输入、显式误差容限、独立状态；不使用睡眠、随机训练、网络或墙钟判定。脚本包含对应正文标签，并明确它是教材核验而非真实 MoE 训练器；人工审查仍负责确认公式与脚本一致。

通用笔记组织为六节：

1. **Scope and Dense-FFN Context**：最小 Transformer/FFN 背景、条件计算和成本动机。
2. **Sparse MoE Layer**：token 粒度、专家、选择、融合、共享分支及残差。
3. **Parameters, Cost, and Capacity**：统一账本、部署成本、容量/drop/dropless。
4. **Task Gradients and Routing**：条件性局部推导、top-1 边界、支持集变化及反事实盲区。
5. **Load Balancing and Stability**：均衡代理、stop-gradient、饱和风险、z-loss 和偏置反馈。
6. **Architecture Case Studies**：Switch、Mixtral、DeepSeekMoE/V3 的不同实例。

附录只保留必要推导和反例。草稿第 6-12 与 13-18 章按主题合并；19-34 章保留正确公式、重写因果解释；新正文不保留重复速查表、无条件保证和不必要自测。实施期间不编辑原 HTML，其整文件删除只在 Phase 5 执行。

### Phase 3 — 接入现有 DeepSeek 阅读体系

- Architecture 留下理解 DeepSeek 所需的简短定义、细粒度与共享专家设计，不展开第二套通用梯度理论。
- 其均衡段保留现有的选择/融合区分；补充 V3 的具体边界，避免将小序列级辅助项误写成只属于后续模型。
- Overview 提供可选的基础阅读路径：通用 MoE -> DeepSeek Architecture -> DeepSeek Systems。
- 相对 PDF 链接使用实际构建布局：DeepSeek 文档到 `../Deep_Learning/Mixture_of_Experts.pdf`，通用笔记回到 `../DeepSeek/DeepSeek_Architecture.pdf` 等。
- 为基础笔记使用本地 `references.bib` 和 Typst 原生书目功能，不增加包或共享模板 helper。

### Phase 4 — 构建、核验与独立审查

补上构建入口并更新 README，随后执行下列核验。两名审查者并行审查不同问题；父会话合并、裁决 Findings，只将已采纳的 ID 交给整改代理。

### Phase 5 — 验收后删除原 HTML

1. 父会话确认 AC-1 至 AC-8 已有接受的证据，独立审查及必要整改完成，没有未解决的范围内 Blocker/Major；运行结束本身不等于通过验收。
2. 在已获批准的最终收尾步骤中检查根目录 HTML 的路径、文件状态和校验和。若与原始输入不同，先暂停并询问用户，避免删除用户后来新增的内容。
3. 仅删除 `MoE_Draft.html`，不使用通配符、`make clean` 或其他批量删除，不删除 PDF、正式 Typst 源或计划。
4. 确认 HTML 不存在，重跑数学核验及 Deep Learning/DeepSeek 构建，记录 AC-9 证据后再完成交付。

## Verification Commands

以下使用 Nushell 交互语法。除已在 Progress 记录的检查外，均为批准实施后才执行的命令，不表示当前已通过。

```nu
cd /home/abel/Code/personal/Note
git branch --show-current
git status --short
git diff --cached --stat
sha256sum MoE_Draft.html
uv run --project ~/Tools/pyenvs/pi-python-repl python scripts/check_moe_math.py
make -n deep-learning
make -n ml
make -n all
make deep-learning
make deepseek
make ml
git diff --check
```

直接编译用于定位诊断，不能只相信旧 `ml` 循环的成功输出：

```nu
typst compile --root . notes/Machine_Learning/Deep_Learning/Mixture_of_Experts.typ build/Machine_Learning/Deep_Learning/Mixture_of_Experts.pdf
typst compile --root . notes/Machine_Learning/DeepSeek/DeepSeek_Architecture.typ build/Machine_Learning/DeepSeek/DeepSeek_Architecture.pdf
typst compile --root . notes/Machine_Learning/DeepSeek/DeepSeek_Overview.typ build/Machine_Learning/DeepSeek/DeepSeek_Overview.pdf
```

Phase 5 删除后的核验：

```nu
if ("MoE_Draft.html" | path exists) { error make {msg: "Draft HTML still exists"} }
uv run --project ~/Tools/pyenvs/pi-python-repl python scripts/check_moe_math.py
make deep-learning
make deepseek
git status --short
git diff --check
```

另外必须检查：

- 先取得已有 DeepSeek 集合的编译基线，区分已有诊断与本次新增诊断，不为消除旧问题改无关笔记。
- 目标 PDF 和相对链接的文件均存在；结合 PDF 链接信息检查编译后的实际目标，不只搜索源码字符串。
- 使用现有 PDF 工具查看公式密集页、架构比较表和参考文献页；遵循 `pdf-tools`，不新建渲染工具链。
- 书目引用全部可解析；经验性数字有具体来源，派生结论有条件，不混成独立复现。
- 清理前 HTML 校验和与基线一致，清理后文件不存在；变更只涉及 Scope 中批准的文件，暂存区和其他用户改动保持不动。未跟踪 HTML 的删除不会出现在普通 `git diff` 中，必须显式检查其不存在。
- 没有现成的 typstyle/CI，首版不安装；执行 `git diff --check` 并人工检查 Typst 风格。所有未执行项及原因如实报告。

## Review Modes and Budget

- 最多一名初始实现代理；实现必须在用户批准本计划后开始。
- 最多两名并行独立审查者：
  - **requirements**：检查 AC-1 至 AC-8 以及 AC-9 的清理前置条件，重点是数学条件、模型实例、来源和内容边界；HTML 的最终不存在状态在 Phase 5 单独验证。
  - **maintainability**：检查新增检查脚本、内容去重、文献维护、导航和构建失败传播。
- 审查使用 `bounded-code-review`；涉及检查脚本时使用 `testing-and-comments`。
- **Maximum Remediation Rounds: 1**。只处理父会话采纳的 Finding IDs，随后作定向验证，不反复全面审查。最终收尾在核验通过后执行已批准的单文件 HTML 清理；无 Findings 时也不能跳过验收直接删除。
- 代理使用用户当前默认路由，启动时显式指定模型；上轮高性能模型例外不自动延续。

## Goal Continuity

批准后，由父会话创建显式分支目标，以本计划为引用，并将 AC-1 至 AC-9 作为稳定 requirement IDs。派发任务时提供对应 goal binding。

运行结束不自动等于通过验收；父会话必须裁决结果、记录实际文件/命令/审查证据，再请求最终审计并明确完成目标。人类可读进度仍只维护在本文件的 Progress 中，不让代理另建任务清单。用户已于 2026-10-09 批准本计划，已建立目标 `moe-note-delivery` revision 1。初始实现只承担 Phase 1-4 中的内容、构建和验证工作；独立审查、父会话验收及 Phase 5 清理由后续受限步骤完成。

## Risks / Alternatives Considered

- **全部并入 Architecture**：文件已经包含 MLA、稀疏注意力、精度、残差和条件记忆；再放完整 MoE 教程会破坏其模型架构地图职责，因此不选。
- **将通用文件放入 DeepSeek 目录**：省一个构建入口，但错误绑定通用原理和模型专题，因此不选。
- **第一版就拆成多篇基础笔记**：导航和重复定义成本高，当前先保持一篇自包含笔记。
- **共享全仓 bibliography**：需要迁移现有集合并扩大风险；首版采用专题局部书目，接受有限元数据重复。
- **以算例通过代替数学审查**：有限差分和反例只能检查具体路径，不能证明普遍收敛、质量或系统性能；独立条件审查仍不可省略。
- **未跟踪原稿的删除**：该 HTML 未被 Git 跟踪，删除不能依赖 Git 恢复。用户已明确授权验收后清理，故严格限制删除时机和路径，并在清理前检查内容未被用户改动；不将本次授权扩大到其他文件。

## Exit Criteria

- AC-1 至 AC-9 均有父会话接受的证据。
- 数学检查与相关编译实际通过，链接/引用/展示检查完成；未执行项及既有失败明确报告。
- 正式新增/修改文档中没有未解决的范围内 Blocker/Major；输入 HTML 的历史错误不作为要求修改原稿的理由。
- 验收后根目录 `MoE_Draft.html` 已删除，删除后的数学检查和相关构建通过；用户其他改动保留，没有提交、推送或未获批准的依赖/范围变更。
- 只在以上条件满足后将计划标为 Completed；若关键验证无法完成，则标为 Paused 并说明阻碍。

## Progress

- [x] 完成 `MoE_Draft.html` 全文静态审查，并复核关键论文和官方实现。
- [x] 核实主题源码分支为 `note/deepseek`，不把另一分支的 `build/` 产物误判为无源文档。
- [x] 经用户授权切换当前工作树至 `note/deepseek`；草稿切换前后校验和一致。
- [x] 检查实际 Architecture/Overview/Evidence、书目及 Makefile；确认 Typst/uv 可用，执行 `make -n deepseek`。
- [x] 完成计划编写；批准前未修改笔记正文、模板或构建规则。
- [x] 用户补充明确要求：正式笔记完成并验收后删除根目录 HTML；已更新清理阶段与 AC-9，写入计划时仍保留草稿，最终按 Phase 5 清理。
- [x] 用户批准范围、英文正文、验证方案及验收后单文件清理。
- 验收目标：`moe-note-delivery` revision 1；AC-1 至 AC-9 均有父会话接受证据，实施基线、暂存区和其他用户改动保持。
- 初始实现：`f13fa6b5-ea29-49da-bea9-6a37f371453a` 已完成并接受阶段交付；执行记录见该任务完整结果及目标证据 `initial-execution-checks`。
- 审查任务：requirements `daf603bc-664f-4cc7-a7ff-cd7f4ab3adef`、maintainability `59ed5d55-de13-4d42-ac3c-fec05d13c7f0` 已完成，父会话已裁决并接受结果。
- 整改记录：`53b6666c-5dc6-4794-aecd-1b8012a88dca` 在写文件前连接失败；同轮续跑 `02807474-9ee8-4b73-8c66-7723a67f1388` 已完成源码修正和相关构建，但在最终 PDF 核验前再次连接中断。
- 源码验收：父会话定向读取三份修正源并接受 `REQ-001`、`REQ-002`、`MAINT-001`，证据 `targeted-remediation-source-acceptance`；两项 Major 已解决，未开启新一轮全面审查。
- 最终验证续跑：`8c3bc5e3-51d9-4868-8578-c47d58e1a0b1` 已完成并由父会话接受，证据 `post-remediation-verification-accepted`；检查 14/14（九项数学算例、五项正文映射/内存 mutation），`make deep-learning` / `make deepseek` / `make ml` 均退出 0。
- PDF 验证：qpdf 三份检查均退出 0，MoE/Architecture/Overview 当前为 12/11/10 页；实际相对 URI 及目标已检查，三代表页已渲染检查。日志与图在 `build/verification/`。
- 最终收尾：`e9d1dbd2-4ce5-4a48-8796-e52ca6df057d` 已完成并由父会话接受，证据 `post-acceptance-html-cleanup-verified`；UTC 2026-10-09T07:12:32Z 至 07:17:53Z。
- 清理结果：原 HTML 删除前为非链接普通文件，SHA-256 与原始输入精确一致；仅删除根 `MoE_Draft.html`，删除后明确不存在且不是悬空链接。
- 删除后核验：检查 14/14，`make deep-learning` / `make deepseek` 均退出 0（既有字体警告 3/18）；`git diff --check` 退出 0，暂存区为空，分支/HEAD 未变，七个相关 PDF 仍存在。
- 清理诊断：首次普通文件探测因 `test --` 参数错误退出 1，未产生文件修改；以正确命令重做并通过后才删除。该失败未计为成功。未重复已通过的 PDF 视觉/URI/qpdf、`make ml` 或广泛审查，无未解决验收阻碍。
- 裁决：`REQ-001`（Major）将专门化/共享知识断言限定为设计意图或条件能力；`REQ-002`（Major）统一 routed 选择数与包含 shared 的总激活预算，并补固定容量账本例子。
- 裁决：`MAINT-001` 采纳为 Minor 加固而非当前数学错误；现有人工核对已建立八项映射，但脚本内部标签自比较不足以防止未来正文映射漂移。以最小标准库表格/锚点一致性检查替代自比较，不引入 Typst 通用解析器或新依赖。
- [x] 建立数学核验、撰写正文并接入阅读路径。
- [x] 实现代理执行数学检查 8/8、相关构建及三份直接编译，完成编译后 PDF URI 和代表页面检查；原稿校验和未变，暂存区未动。
- 验证诊断：DeepSeek 改前/改后均为相同 18 条模板字体警告；新笔记为同类 3 条，`make ml` 为同类 9 条。未修改模板或安装字体。额外的非 AC 环境探测 `python status` 退出 1（mise shim/网络）；指定 uv 环境的数学核验与构建均通过，该探测不作为成功检查。
- [x] 两项独立审查完成并由父会话裁决；其两项 Major 经同一轮整改与定向核验已解决。
- [x] 最多一轮已采纳 Finding 整改，父会话验收 AC-1 至 AC-8。
- [x] 验收后删除 HTML，完成 AC-9 的删除后核验与最终交付；未暂存、提交或推送，未安装依赖或修改模板。
