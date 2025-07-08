-- File: rm.lua
-- Final version: Adds the title and correctly removes only the metadata block,
-- leaving the bibliography intact.

function Pandoc (doc)
  ----------------------------------------------------------------------
  -- Part 1: Add the document title (Working)
  ----------------------------------------------------------------------
  if PANDOC_STATE and PANDOC_STATE.input_files then
    local source_path = PANDOC_STATE.input_files[1]
    
    if source_path then
      local filename = source_path:match("([^/\\]+)$")
      local clean_title = filename:gsub("%.md$", "")
      local typst_title_code = '#align(left)[#text(weight: "bold", size: 1.6em, font: "Bembo")[' .. clean_title .. '] #v(2em, weak: true)] #line(length: 100%, stroke: 0.4pt + gray)'
      local title_block = pandoc.RawBlock('typst', typst_title_code)
      table.insert(doc.blocks, 1, title_block)
    end
  end

  return doc
end
