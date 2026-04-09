local parser = require("typst-ling.parser")

local M = {}

local function normalize_preview(def)
  local preview_text = def.example or def.template or def.name
  preview_text = preview_text:gsub("%${cursor}", "")
  def.text = table.concat({
    def.name,
    " ",
    def.name,
    " ",
    def.name,
    " ",
    def.package,
    " ",
    def.category,
  })
  def.preview = {
    text = preview_text,
    ft = "typst",
    loc = false,
  }
  return def
end

local function merge_doc(def, doc)
  local merged = vim.deepcopy(def)
  if doc.description and doc.description ~= "" then
    merged.description = doc.description
  end
  if doc.example and doc.example ~= "" then
    merged.example = doc.example
  end
  if doc.file then
    merged.file = doc.file
  end
  if doc.search then
    merged.search = doc.search
  end
  return normalize_preview(merged)
end

local static_entries = {
  {
    package = "synkit",
    name = "tree",
    category = "trees",
    description = "Draw a syntax tree from bracket notation.",
    template = '#tree("${cursor}")',
    example = '#tree("[CP [C\' [C did] [TP [DP she] [T\' [T e] [VP [V leave]]]]]]")',
    path = "lib.typ",
    search = "#let tree = tree",
  },
  {
    package = "synkit",
    name = "garden",
    category = "trees",
    description = "Compose multiple trees with cross-tree equivalence lines.",
    template = '#garden(\n  ${cursor}\n)',
    example = '#garden(\n  (input: "[S [NP the cat] [VP [V sat]]]", direction: "down"),\n  (input: "[S [NP 猫が] [VP [V 座った]]]", direction: "up"),\n  equivalence: (("np1-1", "np1-2"),),\n  gap: 2.0,\n)',
    path = "lib.typ",
    search = "#let garden = garden",
  },
  {
    package = "synkit",
    name = "move",
    category = "movement",
    description = "Draw movement notation with rectangular arrows.",
    template = '#move("${cursor}")',
    example = '#move(\n  "[CP Who do you think [(CP)[TP<who>saw Mary]]]",\n  arrows: ((from: "who2", to: "who1", dash: "solid", color: black),),\n)',
    path = "lib.typ",
    search = "#let move = move",
  },
  {
    package = "synkit",
    name = "blank",
    category = "movement",
    description = "Insert a blank underline for empty positions.",
    template = "#blank(width: ${cursor}3em)",
    example = 'The word #blank(width: 3em) means "house".',
    path = "lib.typ",
    search = "#let blank = blank",
  },
  {
    package = "synkit",
    name = "eg",
    category = "examples",
    description = "Create a numbered linguistic example.",
    template = "#eg()[\n  ${cursor}\n]",
    example = '#eg(caption: "Wh-movement")[\n  #table(\n    columns: (2em, 2em, 1fr),\n    stroke: none, align: left + bottom,\n    [#eg-num-label()], [#subex-label()], [Who do you think saw Mary?],\n    [], [#subex-label()], [#move(...)],\n  )\n]',
    path = "lib.typ",
    search = "#let eg = eg",
  },
  {
    package = "synkit",
    name = "subex-label",
    category = "examples",
    description = "Insert the next subexample label.",
    template = "#subex-label(${cursor})",
    path = "lib.typ",
    search = "#let subex-label = subex-label",
    picker = false,
  },
  {
    package = "synkit",
    name = "eg-num-label",
    category = "examples",
    description = "Insert the current example number label.",
    template = "#eg-num-label(${cursor})",
    path = "lib.typ",
    search = "#let eg-num-label = eg-num-label",
    picker = false,
  },
  {
    package = "synkit",
    name = "eg-rules",
    category = "examples",
    description = "Show rule for reference formatting in examples.",
    template = "#show: eg-rules\n${cursor}",
    path = "lib.typ",
    search = "#let eg-rules = eg-rules",
  },
  {
    package = "synkit",
    name = "gloss",
    category = "glosses",
    description = "Create an interlinear glossed example.",
    template = "#gloss()[\n  - ${cursor}\n  - \n  - \n]",
    example = "#gloss()[\n  - eu gosto de maçã\n  - I like.1prs.sg.pres of apple\n  - 'I like apples'\n]",
    path = "lib.typ",
    search = "#let gloss = gloss",
  },
  {
    package = "phonokit",
    name = "phonokit-init",
    category = "core",
    description = "Initialize phonokit settings such as font choice.",
    template = '#phonokit-init(font: "${cursor}")',
    path = "lib.typ",
    search = "#let phonokit-init = phonokit-init",
  },
  {
    package = "phonokit",
    name = "ipa",
    category = "phonetics",
    description = "Convert tipa-style notation to IPA.",
    template = '#ipa("${cursor}")',
    path = "lib.typ",
    search = "#let ipa = ipa",
  },
  {
    package = "phonokit",
    name = "sonority",
    category = "phonology",
    description = "Plot a sonority profile for a phonemic string.",
    template = '#sonority("${cursor}")',
    path = "lib.typ",
    search = "#let sonority = sonority",
  },
  {
    package = "phonokit",
    name = "formants",
    category = "phonetics",
    description = "Create an F1/F2 vowel-cloud plot.",
    template = '#formants("${cursor}")',
    path = "lib.typ",
    search = "#let formants = formants",
  },
  {
    package = "phonokit",
    name = "vot",
    category = "phonetics",
    description = "Draw a schematic voice onset time (VOT) timeline.",
    template = '#vot(${cursor})',
    path = "lib.typ",
    search = "#let vot = vot",
  },
  {
    package = "phonokit",
    name = "syllable",
    category = "prosody",
    description = "Draw a syllable structure tree.",
    template = '#syllable("${cursor}")',
    path = "lib.typ",
    search = "#let syllable = syllable",
  },
  {
    package = "phonokit",
    name = "mora",
    category = "prosody",
    description = "Draw a moraic syllable structure.",
    template = '#mora("${cursor}")',
    path = "lib.typ",
    search = "#let mora = mora",
  },
  {
    package = "phonokit",
    name = "foot",
    category = "prosody",
    description = "Draw a foot with syllables.",
    template = '#foot("${cursor}")',
    path = "lib.typ",
    search = "#let foot = foot",
  },
  {
    package = "phonokit",
    name = "foot-mora",
    category = "prosody",
    description = "Draw a moraic foot structure.",
    template = '#foot-mora("${cursor}")',
    path = "lib.typ",
    search = "#let foot-mora = foot-mora",
  },
  {
    package = "phonokit",
    name = "word",
    category = "prosody",
    description = "Draw a prosodic word with foot boundaries.",
    template = '#word("${cursor}")',
    path = "lib.typ",
    search = "#let word = word",
  },
  {
    package = "phonokit",
    name = "word-mora",
    category = "prosody",
    description = "Draw a prosodic word with moraic structure.",
    template = '#word-mora("${cursor}")',
    path = "lib.typ",
    search = "#let word-mora = word-mora",
  },
  {
    package = "phonokit",
    name = "met-grid",
    category = "prosody",
    description = "Draw a metrical grid.",
    template = '#met-grid("${cursor}")',
    path = "lib.typ",
    search = "#let met-grid = met-grid",
  },
  {
    package = "phonokit",
    name = "vowels",
    category = "segments",
    description = "Draw an IPA vowel chart.",
    template = '#vowels("${cursor}")',
    path = "lib.typ",
    search = "#let vowels = vowels",
  },
  {
    package = "phonokit",
    name = "consonants",
    category = "segments",
    description = "Draw a pulmonic consonant chart.",
    template = '#consonants("${cursor}")',
    path = "lib.typ",
    search = "#let consonants = consonants",
  },
  {
    package = "phonokit",
    name = "tableau",
    category = "ot",
    description = "Create an Optimality Theory tableau.",
    template = "#tableau(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let tableau = tableau",
  },
  {
    package = "phonokit",
    name = "maxent",
    category = "ot",
    description = "Create a Maximum Entropy tableau.",
    template = "#maxent(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let maxent = maxent",
  },
  {
    package = "phonokit",
    name = "hg",
    category = "ot",
    description = "Create a Harmonic Grammar tableau.",
    template = "#hg(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let hg = hg",
  },
  {
    package = "phonokit",
    name = "nhg-demo",
    category = "ot",
    description = "Create a demonstration Noisy Harmonic Grammar tableau.",
    template = "#nhg-demo(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let nhg-demo = nhg-demo",
  },
  {
    package = "phonokit",
    name = "nhg",
    category = "ot",
    description = "Create a Noisy Harmonic Grammar tableau.",
    template = "#nhg(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let nhg = nhg",
  },
  {
    package = "phonokit",
    name = "hasse",
    category = "ot",
    description = "Draw a Hasse diagram.",
    template = "#hasse(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let hasse = hasse",
  },
  {
    package = "phonokit",
    name = "feat",
    category = "features",
    description = "Insert a phonological feature value.",
    template = '#feat("${cursor}")',
    path = "lib.typ",
    search = "#let feat = feat",
  },
  {
    package = "phonokit",
    name = "feat-matrix",
    category = "features",
    description = "Create a feature matrix.",
    template = "#feat-matrix(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let feat-matrix = feat-matrix",
  },
  {
    package = "phonokit",
    name = "autoseg",
    category = "features",
    description = "Draw an autosegmental representation.",
    template = "#autoseg(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let autoseg = autoseg",
  },
  {
    package = "phonokit",
    name = "multi-tier",
    category = "features",
    description = "Draw a multi-tier representation.",
    template = "#multi-tier(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let multi-tier = multi-tier",
  },
  {
    package = "phonokit",
    name = "sound-shift",
    category = "segments",
    description = "Draw a schematic sound-shift diagram.",
    template = "#sound-shift(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let sound-shift = sound-shift",
  },
  {
    package = "phonokit",
    name = "ex",
    category = "examples",
    description = "Create a numbered linguistic example.",
    template = "#ex()[\n  ${cursor}\n]",
    path = "lib.typ",
    search = "#let ex = ex",
  },
  {
    package = "phonokit",
    name = "subex-label",
    category = "examples",
    description = "Insert the next subexample label.",
    template = "#subex-label(${cursor})",
    path = "lib.typ",
    search = "#let subex-label = subex-label",
    picker = false,
  },
  {
    package = "phonokit",
    name = "ex-num-label",
    category = "examples",
    description = "Insert the current example number label.",
    template = "#ex-num-label(${cursor})",
    path = "lib.typ",
    search = "#let ex-num-label = ex-num-label",
    picker = false,
  },
  {
    package = "phonokit",
    name = "ex-rules",
    category = "examples",
    description = "Show rule for reference formatting in examples.",
    template = "#show: ex-rules\n${cursor}",
    path = "lib.typ",
    search = "#let ex-rules = ex-rules",
  },
  {
    package = "phonokit",
    name = "blank",
    category = "extras",
    description = "Insert a horizontal blank.",
    template = "#blank(${cursor})",
    path = "lib.typ",
    search = "#let blank = blank",
  },
  {
    package = "phonokit",
    name = "extra",
    category = "extras",
    description = "Insert emphasized extra material.",
    template = "#extra[${cursor}]",
    path = "lib.typ",
    search = "#let extra = extra",
  },
  {
    package = "phonokit",
    name = "int",
    category = "extras",
    description = "Draw an intonational contour.",
    template = '#int("${cursor}")',
    path = "lib.typ",
    search = "#let int = int",
  },
  {
    package = "phonokit",
    name = "geom",
    category = "geometry",
    description = "Draw a feature-geometry tree.",
    template = "#geom(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let geom = geom",
  },
  {
    package = "phonokit",
    name = "geom-group",
    category = "geometry",
    description = "Compose multiple feature-geometry trees.",
    template = "#geom-group(\n  ${cursor}\n)",
    path = "lib.typ",
    search = "#let geom-group = geom-group",
  },
}

local function docs_for(active)
  local docs = {}
  for _, info in ipairs(active) do
    if info.lib_path then
      docs[info.package] = parser.parse_lib(info.lib_path)
    end
  end
  return docs
end

function M.for_packages(active)
  local allowed = {}
  for _, item in ipairs(active) do
    allowed[item.package] = true
  end

  local docs = docs_for(active)
  local items = {}
  for _, item in ipairs(static_entries) do
    if allowed[item.package] and item.picker ~= false then
      local doc = docs[item.package] and docs[item.package][item.name] or nil
      if doc then
        items[#items + 1] = merge_doc(item, doc)
      else
        items[#items + 1] = normalize_preview(vim.deepcopy(item))
      end
    end
  end

  table.sort(items, function(a, b)
    if a.package == b.package then
      if a.category == b.category then
        return a.name < b.name
      end
      return a.category < b.category
    end
    return a.package < b.package
  end)

  return items
end

return M
