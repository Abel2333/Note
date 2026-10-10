// ==============================================
// 1. Basic Configuration and Color Definitions
// ==============================================
#let color-primary = rgb("#0074D9")
#let color-accent = rgb("#2ECC40")
#let color-bg-code = rgb("#F5F5F5")

// Apply shared body families and fallback to doc; return styled content without changing sizes, page layout, or external state.
#let body-fonts(doc) = {
  set text(font: ("Libertinus Serif", "LXGW WenKai"))
  doc
}

// ========================
// 2. Custom Environments
// ========================

// Universal Box Generator
#let box-styled(title, color, body) = {
  v(0.5em)

  block(
    width: 100%,
    fill: color.lighten(90%),
    stroke: (left: 4pt + color),
    inset: (x: 1em, y: 1em),
    radius: (right: 4pt),
    breakable: true,
    [
      #text(weight: "bold", fill: color)[#title] \
      #v(0.5em)
      #body
    ],
  )
  v(0.5em)
}

// Specific environments for user export
#let theorem(title: "Theorem", body) = box-styled(title, color-primary, body)
#let definition(title: "Definition", body) = box-styled(
  title,
  rgb("#FF851B"),
  body,
)
#let note(body) = box-styled("Note", rgb("#B10DC9"), body)

// ============================================
// 3. Common Abbreviations (Helper Functions)
// ============================================
#let RR = $RR$
#let EE = $bb(E)$ // Exception
#let LL = $cal(L)$ // Loss function
#let implies = $==>$

// ==================================
// 4. Main template function (conf)
// ==================================
#let conf(
  doc,
) = {
  let title = context document.title
  let author = context document.author

  // --- Page Settings ---
  set page(
    paper: "a4",
    margin: (x: 2.5cm, y: 2.5cm),
    header: [
      #set text(size: 9pt, style: "italic", fill: gray)
      #context {
        let headings = query(selector(heading.where(level: 1)).after(here()))
        if headings != () { headings.first().body } else { title }
      }
      #h(1fr)
      #title
      #line(length: 100%, stroke: 0.5pt + gray)
    ],
    footer: align(center)[#context counter(page).display("1 / 1")],
    numbering: "1",
  )

  // --- Font and Paragraph ---
  show: body-fonts
  set text(size: 11pt)
  set par(justify: true, leading: 0.8em)
  set table.cell(breakable: false)
  show figure.caption: set text(size: 9pt, fill: rgb("#5A5A5A"))
  show figure.caption: set par(justify: false, leading: 0.55em)
  set figure(gap: 0.6em)

  // ---Code block style ---
  show raw.where(block: true): block.with(
    fill: color-bg-code,
    inset: 10pt,
    radius: 5pt,
    width: 100%,
  )
  show raw: set text(font: "FiraCode Nerd Font", size: 10pt)

  // --- Title Style ---
  set heading(numbering: "1.1")
  show heading: it => {
    let levels = (16pt, 13pt, 11pt) // fonts of level 1, 2, 3
    let v_befores = (1.5em, 1.2em, 1em) // Spacing before the title
    let v_afters = (0.8em, 0.6em, 0.5em) // Spacing after the title

    let lvl = it.level
    let size = if lvl <= 3 { levels.at(lvl - 1) } else { 11pt }
    let v_before = if lvl <= 3 { v_befores.at(lvl - 1) } else { 1em }
    let v_after = if lvl <= 3 { v_afters.at(lvl - 1) } else { 0.5em }

    v(v_before, weak: true)
    block(width: 100%)[
      #if lvl == 1 [
        #text(size, weight: "bold", fill: color-primary)[#it]
        #v(0.2em)
        #line(length: 100%, stroke: 1pt + color-primary.lighten(50%))
      ] else if lvl == 2 [
        #text(size, weight: "bold", fill: color-primary.lighten(20%))[#it]
      ] else [
        #text(size, weight: "bold")[#it]
      ]
    ]
    v(v_after)
  }

  // --- Mathematical formula ---
  set math.equation(numbering: "(1)")
  show math.equation: set text(font: "Libertinus Math")

  // --- Cover Style ---
  align(center + horizon)[
    #text(24pt, weight: "bold", fill: color-primary)[#title]

    #v(2em)

    #text(14pt)[
      #context document.author.join(", ")
    ]

    #v(2em)
    #text(size: 10pt, style: "italic")[
      Last Updated: #datetime.today().display()
    ]
  ]
  pagebreak()

  // --- Table of Content ---
  outline(indent: auto)
  pagebreak()

  // --- Main Content ---
  doc
}
