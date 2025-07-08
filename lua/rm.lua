-- Pandoc Lua filter to remove trailing "Tags" and "Metadata" sections.

function Pandoc (doc)
  local blocks = doc.blocks
  local tags_section_start_index = -1

  -- We iterate through the blocks to find the start of the section to be removed.
  -- The section is identified by a horizontal rule followed by a "Tags" header.
  -- We look for the *last* occurrence of this pattern to ensure we only trim
  -- the final metadata block in the document.
  for i = 1, #blocks - 1 do
    local block = blocks[i]
    local next_block = blocks[i+1]

    if block.t == 'HorizontalRule' and
       next_block.t == 'Header' and
       next_block.level == 2 and
       pandoc.utils.stringify(next_block.content) == 'Tags' then
      tags_section_start_index = i
    end
  end

  -- If we've found the starting index, we truncate the document's blocks
  -- from that point to the end.
  if tags_section_start_index ~= -1 then
    local new_blocks = {}
    for i = 1, tags_section_start_index - 1 do
      table.insert(new_blocks, blocks[i])
    end
    doc.blocks = new_blocks
  end

  return doc
end
