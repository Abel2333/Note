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
│       └── Supervised/             # Supervised learning algorithms
│           ├── Naive_Bayes.typ
│           └── K-Nearest_Neighbors.typ
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

```bash
make mathematics    # Build only Mathematics notes
make ml            # Build only Machine Learning notes
make guides        # Build only guides
```

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
