-- File: rm.lua
-- Final robust version. Adds a left-aligned title, fixes broken headers,
-- and correctly removes the metadata block regardless of whether '---' or '***' is used.

function Pandoc (doc)
  ----------------------------------------------------------------------
  -- Part 1: Add the document title
  ----------------------------------------------------------------------
  if PANDOC_STATE and PANDOC_STATE.input_files then
    local source_path = PANDOC_STATE.input_files[1]
    if source_path then
      local filename = source_path:match("([^/\\]+)$")
      local clean_title = filename:gsub("%.md$", "")
      -- Creates a left-aligned title with a horizontal rule below it
      local typst_title_code = '#align(left)[#text(weight: "bold", size: 1.6em, font: "Bembo")[' .. clean_title .. ']] #v(1.5em, weak: true) #line(length: 100%, stroke: 0.4pt + gray) #v(2em, weak: true)'
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

  ----------------------------------------------------------------------
  -- Part 3: Remove trailing metadata block (Robust Logic)
  ----------------------------------------------------------------------
  local blocks = doc.blocks
  local cut_from_index = -1

  -- Search backwards from the end of the document to find the metadata block.
  for i = #blocks, 1, -1 do
    local current_block = blocks[i]
    local content_string = pandoc.utils.stringify(current_block)

    -- Find the 'Tags' section, which can either be a Header or a Table.
    if (current_block.t == 'Header' and content_string == 'Tags') or (current_block.t == 'Table' and content_string:match('^## Tags')) then
      -- Now that we've found the 'Tags' block, search backwards for the horizontal rule right before it.
      for j = i - 1, 1, -1 do
        if blocks[j].t == 'HorizontalRule' then
          cut_from_index = j -- We will cut from the horizontal rule onwards.
          goto end_loop -- Use goto to break out of all loops.
        end
      end
    end
  end
  ::end_loop::

  -- If the metadata block was found, create a new list containing only the blocks before it.
  if cut_from_index ~= -1 then
    local new_blocks = {}
    for i = 1, cut_from_index - 1 do
      table.insert(new_blocks, blocks[i])
    end
    doc.blocks = new_blocks
  end

  return doc
end
