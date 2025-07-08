-- Pandoc Lua filter to remove a specific trailing metadata block.
-- This script works by searching backwards from the end of the document
-- to reliably find the final "Tags" and "Metadata" sections.

function Pandoc (doc)
  local blocks = doc.blocks
  local cut_from_index = -1       -- The index where we'll start cutting (the HorizontalRule)
  local found_metadata_header = false
  local found_tags_header = false

  -- 1. Iterate backwards from the end of the document's blocks.
  for i = #blocks, 1, -1 do
    local current_block = blocks[i]

    -- 2. Look for the "## Metadata:" header first.
    if not found_metadata_header and current_block.t == 'Header' and current_block.level == 2 then
      if pandoc.utils.stringify(current_block.content):match('^Metadata:$') then
        found_metadata_header = true
      end
    end

    -- 3. After that, look for the "## Tags" header.
    if found_metadata_header and not found_tags_header and current_block.t == 'Header' and current_block.level == 2 then
      if pandoc.utils.stringify(current_block.content):match('^Tags$') then
        found_tags_header = true
      end
    end

    -- 4. Once both headers have been found, find the HorizontalRule that precedes them.
    -- This is the starting point of the block we want to remove.
    if found_tags_header and current_block.t == 'HorizontalRule' then
      cut_from_index = i
      break -- Exit the loop as we've found our target
    end
  end

  -- 5. If we found the starting point, truncate the document's blocks.
  if cut_from_index ~= -1 then
    local new_blocks = {}
    for i = 1, cut_from_index - 1 do
      table.insert(new_blocks, blocks[i])
    end
    doc.blocks = new_blocks
  end

  return doc
end
