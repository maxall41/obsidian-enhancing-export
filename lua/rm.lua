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
  -- Part 2.5: Convert Markdown links to Typst links
  ----------------------------------------------------------------------
  local function escape_typst_string(str)
    if not str then return "" end
    -- Escape backslashes first, then other special characters
    str = str:gsub("\\", "\\\\")
    str = str:gsub("#", "\\#")  -- Escape # symbols
    str = str:gsub('"', '\\"')
    str = str:gsub("'", "\\'")
    -- Add other escapes as needed
    return str
  end


  local link_fixer_walker = {
    Link = function(el)
      -- Get the link's destination URL and the link's text content.
      local url = el.target
      local text = pandoc.utils.stringify(el.content)
      
      -- Escape any special characters in the URL and text for Typst.
      local safe_url = escape_typst_string(url)
      local safe_text = escape_typst_string(text)
      
      -- Create a raw Typst block with the #link function.
      -- This format creates a clickable link with descriptive text.
      return pandoc.RawInline('typst', string.format('#link("https://maxc.codes/404")[%s]', safe_url, safe_text))
    end
  }
  
  -- Walk through the document (after headers are fixed) and apply the link fixer.
  doc = doc:walk(link_fixer_walker)

  ----------------------------------------------------------------------
  -- Part 2.6: Convert bare URLs (autolinks) to Typst links
  ----------------------------------------------------------------------
  local autolink_fixer_walker = {
    Str = function(el)
      -- Check if the string contains a URL.
      if el.text:match("https?://") then
        local parts = {}
        local last_pos = 1
        -- Find all URLs in the string and process them.
        for url in el.text:gmatch("(https?://[%w%p~_-/?=&%%#]+)") do
          local url_start, url_end = el.text:find(url, last_pos, true)
          if url_start then
            -- Add any text that came before the URL.
            local preceding_text = el.text:sub(last_pos, url_start - 1)
            if #preceding_text > 0 then
              table.insert(parts, pandoc.Str(preceding_text))
            end
            
            -- Add the URL as a Typst link.
            local safe_url = escape_typst_string(url)
            table.insert(parts, pandoc.RawInline('typst', string.format('#link("%s")', safe_url)))
            last_pos = url_end + 1
          end
        end
        
        -- Add any remaining text after the last URL.
        local remaining_text = el.text:sub(last_pos)
        if #remaining_text > 0 then
          table.insert(parts, pandoc.Str(remaining_text))
        end
        
        return parts
      end
    end
  }

  -- Walk through the document again to fix autolinks.
  doc = doc:walk(autolink_fixer_walker)

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
