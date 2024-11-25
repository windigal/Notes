#let project(title: "", authors: (), body) = {
  // Set the document's basic properties.
  set document(author: authors, title: title)
  set page(numbering: "1", number-align: center)
  set text(
  font:("EB Garamond","FOT-TsukuAOldMin Pr6",),discretionary-ligatures:true,
  historical-ligatures:true,
  number-type: "lining",
  )
  show math.equation: set text(weight: 400,font:"Garamond-Math")
  show raw: set text(weight: 400,font:("Fira Code","LXGW WenKai Mono"))
  show heading: it => [
  #set text(weight: 600,0.9em)
  #block(smallcaps(it.body))
  ]
  // Title row.
  align(center)[
    #block(text(weight: 600, 1.5em, title))
  ]

  // Author information.
  pad(
    top: 0.5em,
    bottom: 0.5em,
    x: 2em,
    grid(
      columns: (1fr,) * calc.min(3, authors.len()),
      gutter: 1em,
      ..authors.map(author => align(center, strong(author))),
    ),
  )

  // Main body.
  set par(justify: true)

  body
}