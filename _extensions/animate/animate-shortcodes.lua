--- @module animate-shortcodes
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = 'animate'

--- Load required modules
local str = require(quarto.utils.resolve_path("_modules/string.lua"):gsub("%.lua$", ""))
local log = require(quarto.utils.resolve_path("_modules/logging.lua"):gsub("%.lua$", ""))
local meta_mod = require(quarto.utils.resolve_path("_modules/metadata.lua"):gsub("%.lua$", ""))
local html_mod = require(quarto.utils.resolve_path("_modules/html.lua"):gsub("%.lua$", ""))
local validation = require(quarto.utils.resolve_path("_modules/validation.lua"):gsub("%.lua$", ""))

--- Array of supported animation effects from Animate.css library
--- @type string[] List of all valid animation names
--- @see https://animate.style/ For complete list of available animations
local animation_array = {
  "bounce", "flash", "pulse", "rubberBand", "shakeX", "shakeY", "headShake",
  "swing", "tada", "wobble", "jello", "heartBeat",
  "backInDown", "backInLeft", "backInRight", "backInUp",
  "backOutDown", "backOutLeft", "backOutRight", "backOutUp",
  "bounceIn", "bounceInDown", "bounceInLeft", "bounceInRight", "bounceInUp",
  "bounceOut", "bounceOutDown", "bounceOutLeft", "bounceOutRight", "bounceOutUp",
  "fadeIn", "fadeInDown", "fadeInDownBig", "fadeInLeft", "fadeInLeftBig",
  "fadeInRight", "fadeInRightBig", "fadeInUp", "fadeInUpBig",
  "fadeInTopLeft", "fadeInTopRight", "fadeInBottomLeft", "fadeInBottomRight",
  "fadeOut", "fadeOutDown", "fadeOutDownBig", "fadeOutLeft", "fadeOutLeftBig",
  "fadeOutRight", "fadeOutRightBig", "fadeOutUp", "fadeOutUpBig",
  "fadeOutTopLeft", "fadeOutTopRight", "fadeOutBottomRight", "fadeOutBottomLeft",
  "flip", "flipInX", "flipInY", "flipOutX", "flipOutY",
  "lightSpeedInRight", "lightSpeedInLeft", "lightSpeedOutRight", "lightSpeedOutLeft",
  "rotateIn", "rotateInDownLeft", "rotateInDownRight", "rotateInUpLeft", "rotateInUpRight",
  "rotateOut", "rotateOutDownLeft", "rotateOutDownRight", "rotateOutUpLeft", "rotateOutUpRight",
  "hinge", "jackInTheBox", "rollIn", "rollOut",
  "zoomIn", "zoomInDown", "zoomInLeft", "zoomInRight", "zoomInUp",
  "zoomOut", "zoomOutDown", "zoomOutLeft", "zoomOutRight", "zoomOutUp",
  "slideInDown", "slideInLeft", "slideInRight", "slideInUp",
  "slideOutDown", "slideOutLeft", "slideOutRight", "slideOutUp"
}

--- Valid CSS animation-direction values
--- @type string[]
local direction_array = { "normal", "reverse", "alternate", "alternate-reverse" }

--- Default animation options configuration
--- @type table<string, string> Default values for animation properties
local animate_defaults = {
  ["duration"] = "3s",
  ["delay"] = "2s",
  ["repeat"] = "1",
  ["stagger"] = "0s",
  ["direction"] = "normal"
}

--- Pattern matching a CSS time value (e.g. "3s", "500ms", "0.5s").
--- @type string
local TIME_PATTERN = '^%d+%.?%d*m?s$'

--- Track whether deprecation warning has been shown.
--- Reset when a new document begins (see reset_state_if_new_document).
--- @type boolean
local deprecation_warning_shown = false

--- Counter for the running stagger offset within a document.
--- Reset when a new document begins (see reset_state_if_new_document).
--- @type integer
local stagger_index = 0

--- Sentinel used to detect the start of a new document in batch renders.
--- Compared against pandoc.utils.stringify of the title (best-effort).
--- @type any
local last_document_key = nil

--- Parse a CSS time string into milliseconds.
--- Returns nil if the value does not match the expected pattern.
--- @param value string|nil
--- @return number|nil Milliseconds, or nil if invalid.
local function parse_time_ms(value)
  if value == nil then return nil end
  local number_part, unit = value:match('^(%d+%.?%d*)(m?s)$')
  if number_part == nil then return nil end
  local number = tonumber(number_part)
  if number == nil then return nil end
  if unit == 'ms' then return number end
  return number * 1000
end

--- Format milliseconds back to a CSS time string.
--- Uses seconds when divisible by 1000, otherwise milliseconds.
--- @param ms number
--- @return string
local function format_time_ms(ms)
  if ms % 1000 == 0 then
    return tostring(math.floor(ms / 1000)) .. 's'
  end
  return tostring(math.floor(ms + 0.5)) .. 'ms'
end

--- Validate a CSS time value (used for duration, delay, stagger).
--- Logs a warning and returns the fallback when invalid.
--- @param value string|nil
--- @param key string Option name (for log context).
--- @param fallback string Default to use when invalid.
--- @return string A valid time string.
local function validate_time(value, key, fallback)
  if str.is_empty(value) then return fallback end
  if value:match(TIME_PATTERN) then return value end
  log.log_warning(
    EXTENSION_NAME,
    'Invalid ' .. key .. ' value "' .. value .. '"; expected e.g. "2s" or "500ms". Falling back to "' .. fallback .. '".'
  )
  return fallback
end

--- Validate a repeat value: positive integer or "infinite".
--- @param value string|nil
--- @param fallback string
--- @return string
local function validate_repeat(value, fallback)
  if str.is_empty(value) then return fallback end
  if value == 'infinite' then return value end
  local n = tonumber(value)
  if n ~= nil and n > 0 and math.floor(n) == n then
    return tostring(math.floor(n))
  end
  log.log_warning(
    EXTENSION_NAME,
    'Invalid repeat value "' .. value .. '"; expected a positive integer or "infinite". Falling back to "' .. fallback .. '".'
  )
  return fallback
end

--- Validate a direction value against the CSS animation-direction set.
--- @param value string|nil
--- @param fallback string
--- @return string
local function validate_direction(value, fallback)
  if str.is_empty(value) then return fallback end
  if validation.in_array(value, direction_array) then return value end
  log.log_warning(
    EXTENSION_NAME,
    'Invalid direction value "' .. value .. '"; expected one of: ' ..
    table.concat(direction_array, ', ') .. '. Falling back to "' .. fallback .. '".'
  )
  return fallback
end

--- Detect a new document and reset module-level state so batch renders
--- do not bleed cascade or stagger state from a previous render.
--- Uses an environment string as a sentinel; when it changes, state resets.
--- @param meta table The current document metadata
--- @return nil
local function reset_state_if_new_document(meta)
  local key = ''
  if meta and meta.title then key = key .. str.stringify(meta.title) end
  key = key .. '|' .. (os.getenv('QUARTO_DOCUMENT_PATH') or '')
  key = key .. '|' .. (os.getenv('QUARTO_PROJECT_OUTPUT_DIR') or '')
  if key ~= last_document_key then
    last_document_key = key
    deprecation_warning_shown = false
    stagger_index = 0
  end
end

--- Animate shortcode handler.
--- Main function that processes the animate shortcode and generates the appropriate HTML output.
--- Handles parameter parsing, validation, and HTML generation for animated elements.
--- Only generates output for HTML-based formats; returns null for other formats.
---
--- Supported parameters:
--- - args[1]: Animation type (e.g., "bounce", "fadeIn", "slideUp")
--- - args[2]: Content to animate (HTML special characters are escaped automatically)
--- - kwargs.delay: Custom delay override (e.g., "1s", "500ms")
--- - kwargs.duration: Custom duration override (e.g., "2s", "1500ms")
--- - kwargs.repeat: Custom repeat count override (e.g., "3", "infinite")
--- - kwargs.stagger: Per-element delay increment for sequential calls (e.g., "200ms")
--- - kwargs.direction: CSS animation-direction (normal, reverse, alternate, alternate-reverse)
---
--- @param args table Array of positional arguments from the shortcode
--- @param kwargs table Table of named keyword arguments from the shortcode
--- @param meta table Document metadata that may contain global animate settings
--- @return pandoc.RawInline|nil HTML span element with animation classes or null for non-HTML formats
--- @usage {{< animate bounce delay=1s >}}Hello World{{< /animate >}}
--- @usage {{< animate fadeIn duration=3s repeat=infinite >}}Animated text{{< /animate >}}
local function animate(args, kwargs, meta)
  -- Only process for HTML-based formats (excluding epub which won't handle animations)
  if not quarto.doc.is_format("html:js") then
    return pandoc.Null()
  end

  -- Reset module-level state on document boundary (batch render safety)
  reset_state_if_new_document(meta)

  if str.is_empty(args[1]) then
    log.log_error(EXTENSION_NAME, "Animation type is required as the first argument.")
    return pandoc.Null()
  end
  if str.is_empty(args[2]) then
    log.log_error(EXTENSION_NAME, "Animation text is required as the second argument.")
    return pandoc.Null()
  end

  -- Check for deprecated top-level configuration (legacy keys only)
  for _, key in ipairs({ 'duration', 'delay', 'repeat' }) do
    _, deprecation_warning_shown = meta_mod.check_deprecated_config(meta, 'animate', key, deprecation_warning_shown)
  end

  -- Resolve options with kwargs > metadata > defaults precedence
  local raw_options = meta_mod.get_options({
    extension = 'animate',
    keys = { 'duration', 'delay', 'repeat', 'stagger', 'direction' },
    args = kwargs,
    meta = meta,
    defaults = animate_defaults
  })

  -- Validate each option, falling back to the defaults on invalid input
  local duration = validate_time(raw_options['duration'], 'duration', animate_defaults['duration'])
  local base_delay = validate_time(raw_options['delay'], 'delay', animate_defaults['delay'])
  local repeat_value = validate_repeat(raw_options['repeat'], animate_defaults['repeat'])
  local stagger = validate_time(raw_options['stagger'], 'stagger', animate_defaults['stagger'])
  local direction = validate_direction(raw_options['direction'], animate_defaults['direction'])

  -- Compute effective delay including the running stagger offset
  local effective_delay = base_delay
  local stagger_ms = parse_time_ms(stagger) or 0
  if stagger_ms > 0 then
    local base_ms = parse_time_ms(base_delay) or 0
    effective_delay = format_time_ms(base_ms + stagger_ms * stagger_index)
    stagger_index = stagger_index + 1
  end

  -- Ensure required dependencies are loaded
  html_mod.ensure_html_dependency({
    name = 'animate',
    version = '4.1.1',
    stylesheets = { "animate.min.css" },
    head = "<style>:root{--animate-duration:" .. duration ..
        ";--animate-delay:" .. base_delay ..
        ";--animate-repeat:" .. repeat_value .. "}</style>"
  })

  -- Add RevealJS-specific JavaScript if needed
  if quarto.doc.is_format("revealjs") then
    html_mod.ensure_html_dependency({
      name = "animatejs",
      scripts = { { path = "animate.js", afterBody = true } }
    })
  end

  -- Validate animation effect and build the class name
  local animation_name = str.stringify(args[1])
  local animation = validation.is_valid_value(
    animation_name,
    animation_array,
    'animate__animated animate__'
  )
  if animation == nil then
    log.log_warning(
      EXTENSION_NAME,
      'Unknown animation "' .. animation_name ..
      '"; see https://animate.style/ for the supported list.'
    )
    return pandoc.Null()
  end

  -- Build animation attributes
  local attr_delay = ' animate__delay-' .. effective_delay
  local attr_repeat = repeat_value == "infinite"
      and ' animate__infinite'
      or ' animate__repeat-' .. repeat_value
  local style_parts = {
    'display: inline-block',
    'animation-duration:' .. duration
  }
  if direction ~= 'normal' then
    table.insert(style_parts, 'animation-direction:' .. direction)
  end
  -- All style values are pre-validated so the attribute string is safe by construction.
  local attr_style = 'style="' .. table.concat(style_parts, ';') .. '"'

  -- Escape the content for safe HTML insertion; the shortcode is plain-text only
  local content = str.escape_html(str.stringify(args[2]))
  return pandoc.RawInline(
    'html',
    '<span class="' .. animation .. attr_delay .. attr_repeat .. '" ' ..
    attr_style .. '>' .. content .. '</span>'
  )
end

--- Module export table.
--- Defines the shortcodes available to Quarto for processing.
--- @type table<string, function> Table mapping shortcode names to handler functions
return {
  ["animate"] = animate
}
