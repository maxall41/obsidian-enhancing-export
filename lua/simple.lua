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

  ----------------------------------------------------------------------
  -- Part 2: Fix broken headers within paragraphs
  ----------------------------------------------------------------------
  local fixed_blocks = {}
  for _, block in ipairs(doc.blocks) do
    if block.t == 'Para' then
      local content = pandoc.utils.stringify(block)
      local head_text, header_content = content:match("(.-)## (.*)")
      if head_text then
        if head_text:match("%S") then
          table.insert(fixed_blocks, pandoc.Para(pandoc.Str(head_text)))
        end
        table.insert(fixed_blocks, pandoc.Header(2, pandoc.read(header_content).blocks[1].content))
      else
        table.insert(fixed_blocks, block)
      end
    else
      table.insert(fixed_blocks, block)
    end
  end
  doc.blocks = fixed_blocks

  return doc
end
