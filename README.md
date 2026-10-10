# Personal Notes

Technical notes in Mathematics, Machine Learning, and Computer Science written in Typst.

## Overview

This repository contains a collection of well-structured academic notes covering various topics in mathematics, machine learning, and related fields. All notes are written using [Typst](https://typst.app/), a modern markup-based typesetting system.

## Project Structure

```
Note/
├── notes/                          # All note content
│   ├── Mathematics/
│   │   ├── Statistics/             # Statistics notes
│   │   │   └── Likelihood.typ
│   │   └── Analysis/               # Mathematical analysis notes
│   │       └── Cauchy-Schwarz_Inequality.typ
│   └── Machine_Learning/
│       ├── Supervised/             # Supervised learning algorithms
│       │   ├── Naive_Bayes.typ
│       │   └── K-Nearest_Neighbors.typ
│       ├── Deep_Learning/          # General deep-learning foundations
│       │   ├── Mixture_of_Experts.typ
│       │   └── references.bib
│       └── DeepSeek/               # DeepSeek study collection
│           ├── DeepSeek_Overview.typ
│           ├── DeepSeek_Architecture.typ
│           ├── DeepSeek_Reasoning.typ
│           ├── DeepSeek_Systems.typ
│           ├── DeepSeek_Multimodal.typ
│           ├── DeepSeek_Evidence.typ
│           └── references.bib
│
├── templates/                      # Typst templates and styling
│   └── lib.typ                     # Main template library
│
├── guides/                         # Writing and style guides
│   └── Expression.typ              # Mathematical writing guide
│
├── assets/                         # Shared resources
│   ├── images/
│   ├── diagrams/
│   └── data/
│
├── build/                          # Compiled PDF outputs (git-ignored)
│
├── Makefile                        # Build automation
├── .gitignore                      # Git ignore patterns
└── README.md                       # This file
```

## Prerequisites

- [Typst](https://github.com/typst/typst) - Install via:

  ```bash
  # macOS
  brew install typst

  # Linux
  cargo install --git https://github.com/typst/typst --locked typst-cli

  # Or download from https://github.com/typst/typst/releases
  ```

## Building Notes

### Build All Notes

```bash
make all
```

### Build Specific Categories

```nu
make mathematics  # Build the Mathematics notes
make ml           # Build Machine Learning notes, including Deep Learning
make deep-learning  # Build only general Deep Learning notes
make deepseek     # Build the DeepSeek study collection
make guides       # Build only guides
```

### Deep Learning Foundations

[`Mixture_of_Experts.typ`](notes/Machine_Learning/Deep_Learning/Mixture_of_Experts.typ) is a self-contained English foundation for Transformer FFN MoE layers. It separates routing definitions, capacity accounting, local gradient conditions, balancing limits, and frozen architecture case studies. The DeepSeek collection links to it for the generic material while retaining model-specific details.

Build it directly with Nushell:

```nu
make deep-learning
```

`make ml` also builds this strict target before the existing supervised-learning loop.

### Optional MoE Figure Maintenance

Normal Typst builds consume the checked-in curve SVG and do not require Python.
The following optional maintainer commands use the existing offline tool
environment to check the finite examples, inspect indexed-function attachment
boundaries, check the fixed-support curves, or regenerate that SVG:

```nu
let moe_figure_env = ($env.HOME | path join "Tools" "pyenvs" "pi-python-repl")
uv run --offline --project $moe_figure_env python scripts/check_moe_math.py
uv run --offline --project $moe_figure_env python scripts/check_moe_typesetting.py
uv run --offline --project $moe_figure_env python scripts/generate_moe_top1_gate_figure.py --check
uv run --offline --project $moe_figure_env python scripts/generate_moe_top1_gate_figure.py
```

The final command refreshes `assets/diagrams/moe_top1_gate_comparison.svg`;
`--check` has no SVG write side effect.

### DeepSeek Study Collection

The DeepSeek collection is a set of focused English Typst notes with a durable overview, technical derivations, source-class boundaries, and a correction ledger. Start with [`DeepSeek_Overview.typ`](notes/Machine_Learning/DeepSeek/DeepSeek_Overview.typ), then follow the links to the architecture, reasoning, systems, multimodal, and evidence notes. Its bibliography is [`references.bib`](notes/Machine_Learning/DeepSeek/references.bib).

Build it directly with:

```bash
make deepseek
```

The collection is also included in `make all`. The notes use an as-of date of 2026-09-30 and do not require the mutable `deepseek-papers.md` outline at build or reading time.

### Watch for Changes

```bash
make watch         # Auto-rebuild on changes (default file)
# Or watch a specific file:
typst watch notes/Mathematics/Statistics/Likelihood.typ build/output.pdf
```

### Clean Build Directory

```bash
make clean
```

### Get Help

```bash
make help
```

## Writing Notes

### Creating a New Note

1. Choose the appropriate directory under `notes/`
2. Create a new `.typ` file
3. Use the template structure:

```typst
#import "/templates/lib.typ": EE, LL, RR, conf, definition, note, theorem

// Set Metadata
#set document(
  title: "Your Note Title",
  author: "Abel Zhan",
)

// Apply Template
#show: conf

= Your First Section

Content goes here...
```

### Available Template Components

- `theorem(title: "...", body)` - Theorem boxes
- `definition(title: "...", body)` - Definition boxes
- `note(body)` - Note boxes for important remarks
- `EE` - Expected value symbol
- `LL` - Loss function symbol
- `RR` - Real numbers symbol

### Writing Style Guide

Refer to `guides/Expression.typ` for a comprehensive guide on writing mathematical expressions in English with proper academic conventions.

## Current Notes

### Mathematics

#### Statistics

- **Likelihood**: Maximum Likelihood Estimation (MLE), log-likelihood, Fisher Information, model comparison

#### Analysis

- **Cauchy-Schwarz Inequality**: Proof and geometric interpretation

### Machine Learning

#### Supervised Learning

- **Naive Bayes**: Bayes decision theory, conditional independence, parameter estimation
- **K-Nearest Neighbors**: 1-NN algorithm, Cover-Hart bounds, asymptotic error analysis

#### Deep Learning

- **[Mixture of Experts](notes/Machine_Learning/Deep_Learning/Mixture_of_Experts.typ)**: Transformer FFN MoE routing, cost and capacity accounting, local gradient boundaries, balance mechanisms, and Switch/Mixtral/DeepSeek case studies.

#### DeepSeek Study Collection

- **[DeepSeek Collection](notes/Machine_Learning/DeepSeek/DeepSeek_Overview.typ)**: Evolution map, architecture and efficiency, reasoning, systems, multimodality, and an evidence/correction ledger.

## Contributing

When adding new notes:

1. Place files in the appropriate subject directory
2. Use the standard template from `templates/lib.typ`
3. Follow the naming convention: `Topic_Name.typ` (use underscores for spaces)
4. Ensure notes compile successfully with `typst compile`
5. Update this README if adding new categories

## License

Personal academic notes by Abel Zhan.

## Contact

For questions or suggestions, please open an issue in this repository.
