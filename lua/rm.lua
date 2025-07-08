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
  -- Part 2: Remove trailing metadata block (Corrected Logic)
  ----------------------------------------------------------------------
  local blocks = doc.blocks
  local cut_from_index = -1

  -- Find the start of the metadata section (the "Tags" table).
  for i, block in ipairs(blocks) do
    if block.t == 'Table' and pandoc.utils.stringify(block):match('^## Tags') then
      cut_from_index = i
      break -- Exit the loop once we find it.
    end
  end

  -- If we found the start of the metadata block, create a new list
  -- containing only the blocks that come *before* it.
  if cut_from_index ~= -1 then
    local new_blocks = {}
    for i = 1, cut_from_index - 1 do
      table.insert(new_blocks, blocks[i])
    end
    -- Replace the document's blocks with our new, shorter list.
    doc.blocks = new_blocks
  end

  return doc
end
