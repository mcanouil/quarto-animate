--- MC Engine - Values that Quarto 1 and Quarto 2 give through different routes
--- @module "engine"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
---
--- Each function returns the same value in Quarto 1 and in Quarto 2 for the
--- same document. It reads the data that is present, never the name or the
--- version of the engine, so it keeps working when Quarto 2 adds a route.
---
--- Known limit: Quarto 1 does not set `QUARTO_EXECUTE_INFO` for a page that it
--- takes from the freeze cache, so the `project_*` functions return nil there
--- in Quarto 1, as `metadata.get_project_metadata` does.

local M = {}

--- Load a sibling module from the same directory as this file.
--- @param filename string The sibling module filename (e.g., 'string.lua')
--- @return table The loaded module
local function load_sibling(filename)
  local name = filename:gsub('%.lua$', '')
  if not (debug and debug.getinfo) then
    -- q2 has no `debug` library, and its `require` looks in the directory of
    -- the module being loaded first.
    return require(name)
  end
  local source = debug.getinfo(1, 'S').source:sub(2)
  local dir = source:match('(.*[/\\])') or ''
  return require(dir .. name)
end

local metadata = load_sibling('metadata.lua')
local str = load_sibling('string.lua')

-- ============================================================================
-- PROJECT VALUES
-- ============================================================================

--- Turn a metadata value into a plain string, or nil when it is empty.
--- @param value any A value from the JSON file (a string) or from pandoc.Meta
--- @return string|nil
local function plain_string(value)
  if value == nil then
    return nil
  end
  local text = type(value) == 'string' and value or pandoc.utils.stringify(value)
  if str.is_empty(text) then
    return nil
  end
  return text
end

--- Read the `website` and `book` maps of the project.
--- Quarto 1 writes them to the file that `QUARTO_EXECUTE_INFO` names.
--- Quarto 2 does not set the variable, and gives them in the document metadata.
--- @param meta table|nil The document metadata
--- @return table|nil website, table|nil book, string|nil reason
local function project_maps(meta)
  local format_meta, reason = metadata.get_project_metadata()
  if format_meta ~= nil then
    return format_meta['website'], format_meta['book'], nil
  end
  if reason ~= nil then
    return nil, nil, reason
  end
  if meta == nil then
    return nil, nil, nil
  end
  return meta['website'], meta['book'], nil
end

--- Read one key from `website`, then from `book`.
--- @param meta table|nil The document metadata
--- @param key string The key, for example 'repo-url'
--- @return string|nil value, string|nil reason
local function project_value(meta, key)
  local website, book, reason = project_maps(meta)
  if reason ~= nil then
    return nil, reason
  end
  -- Not ipairs: it would stop at a missing website and never read the book.
  local maps = { website, book }
  for index = 1, 2 do
    local map = maps[index]
    if type(map) == 'table' then
      local value = plain_string(map[key])
      if value ~= nil then
        return value, nil
      end
    end
  end
  return nil, nil
end

--- Get the repository URL of the project: `website.repo-url`, else `book.repo-url`.
--- @param meta table|nil The document metadata, used when Quarto gives no `QUARTO_EXECUTE_INFO`
--- @return string|nil url The URL, or nil when the project sets none
--- @return string|nil reason Why `QUARTO_EXECUTE_INFO` could not be read, as in `metadata.get_project_metadata`
--- @usage local repo_url = engine.project_repo_url(doc.meta)
function M.project_repo_url(meta)
  return project_value(meta, 'repo-url')
end

--- Get the site URL of the project: `website.site-url`, else `book.site-url`.
--- @param meta table|nil The document metadata, used when Quarto gives no `QUARTO_EXECUTE_INFO`
--- @return string|nil url The URL, or nil when the project sets none
--- @return string|nil reason Why `QUARTO_EXECUTE_INFO` could not be read, as in `metadata.get_project_metadata`
--- @usage local site_url = engine.project_site_url(doc.meta)
function M.project_site_url(meta)
  return project_value(meta, 'site-url')
end

--- Get the kind of the project: 'book' when it has a `book` map, else 'website' when it has a `website` map.
--- @param meta table|nil The document metadata, used when Quarto gives no `QUARTO_EXECUTE_INFO`
--- @return string|nil kind 'book', 'website', or nil for any other project or a single file
--- @return string|nil reason Why `QUARTO_EXECUTE_INFO` could not be read, as in `metadata.get_project_metadata`
--- @usage local kind = engine.project_kind(doc.meta) or 'default'
function M.project_kind(meta)
  local website, book, reason = project_maps(meta)
  if reason ~= nil then
    return nil, reason
  end
  if book ~= nil then
    return 'book', nil
  end
  if website ~= nil then
    return 'website', nil
  end
  return nil, nil
end

-- ============================================================================
-- DOCUMENT AND WRITER VALUES
-- ============================================================================

--- Get the directory of the document being rendered.
--- `quarto.doc.input_file` gives it on both engines, so it is read first.
--- `QUARTO_DOCUMENT_PATH` is only a fallback: Quarto 1 does not set it again
--- for a page that it takes from the freeze cache, so it can name the
--- directory of the page rendered before.
--- @return string|nil dir The directory, or nil when neither route gives one
--- @usage local dir = engine.document_dir()
function M.document_dir()
  local input = quarto and quarto.doc and quarto.doc.input_file
  if not str.is_empty(input) then
    return pandoc.path.directory(input)
  end
  local dir = os.getenv('QUARTO_DOCUMENT_PATH')
  if str.is_empty(dir) then
    return nil
  end
  return dir
end

--- Get the Reveal.js slide level.
--- Quarto 1 gives a number in `PANDOC_WRITER_OPTIONS.slide_level`.
--- Quarto 2 gives a null value there, so the `slide-level` metadata is read next.
--- @param meta table|nil The document metadata
--- @return integer level The slide level, 2 when nothing sets it
--- @usage local level = engine.slide_level(doc.meta)
function M.slide_level(meta)
  local writer = PANDOC_WRITER_OPTIONS and tonumber(PANDOC_WRITER_OPTIONS.slide_level)
  if writer ~= nil then
    return writer
  end
  local value = meta and meta['slide-level']
  local from_meta = value ~= nil and tonumber(type(value) == 'string' and value or pandoc.utils.stringify(value))
  return from_meta or 2
end

-- ============================================================================
-- OUTPUT CHECKS
-- ============================================================================

--- The `FORMAT` values of each output kind, as Quarto 1 defines them in `_format.lua`.
local OUTPUT_FORMATS = {
  html = {
    html = true, html4 = true, html5 = true, epub = true, epub2 = true, epub3 = true,
    s5 = true, dzslides = true, slidy = true, slideous = true, revealjs = true,
  },
  revealjs = { revealjs = true },
  typst = { typst = true },
  docx = { docx = true },
}

--- Check the output format.
--- Quarto 1 has `quarto.format.is_<kind>_output()`, and Quarto 2 does not,
--- so the `FORMAT` test of Quarto 1 is used when the function is missing.
--- @param kind string One of 'html', 'revealjs', 'typst', 'docx'
--- @return boolean is_kind Whether the output is of that kind
--- @usage if engine.is_output('html') then ... end
function M.is_output(kind)
  local formats = OUTPUT_FORMATS[kind]
  if formats == nil then
    error("engine.is_output: unknown kind '" .. tostring(kind) .. "'; use one of: html, revealjs, typst, docx", 2)
  end
  local check = quarto and quarto.format and quarto.format['is_' .. kind .. '_output']
  if type(check) == 'function' then
    return check() == true
  end
  return formats[FORMAT] == true
end

return M
