--- @module animate-shortcodes
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = 'animate'

--- Load utils, validation, and schema modules
local utils = require(quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", ""))
local validation = require(quarto.utils.resolve_path("_modules/validation.lua"):gsub("%.lua$", ""))
local schema = require(quarto.utils.resolve_path("_modules/schema.lua"):gsub("%.lua$", ""))

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

--- Default animation options configuration
--- @type table<string, string> Default values for animation properties
local animate_defaults = {
  ["duration"] = "3s", -- Default animation duration
  ["delay"] = "2s",    -- Default animation delay before starting
  ["repeat"] = "1"     -- Default number of animation repetitions
}

--- Track whether deprecation warning has been shown
--- @type boolean
local deprecation_warning_shown = false

--- Cached validated options from schema (lazily initialised on first shortcode call)
--- @type table|nil
local validated_options = nil

--- Animate shortcode handler.
--- Main function that processes the animate shortcode and generates the appropriate HTML output.
--- Handles parameter parsing, validation, and HTML generation for animated elements.
--- Only generates output for HTML-based formats; returns null for other formats.
---
--- Supported parameters:
--- - args[1]: Animation type (e.g., "bounce", "fadeIn", "slideUp")
--- - args[2]: Content to animate
--- - kwargs.delay: Custom delay override (e.g., "1s", "500ms")
--- - kwargs.duration: Custom duration override (e.g., "2s", "1500ms")
--- - kwargs.repeat: Custom repeat count override (e.g., "3", "infinite")
---
--- @param args table Array of positional arguments from the shortcode
--- @param kwargs table Table of named keyword arguments from the shortcode
--- @param meta table Document metadata that may contain global animate settings
--- @return pandoc.RawInline|nil HTML span element with animation classes or null for non-HTML formats
--- @usage {{< animate bounce delay=1s >}}Hello World{{< /animate >}}
--- @usage {{< animate fadeIn duration=3s repeat=infinite >}}Animated text{{< /animate >}}
local function animate(args, kwargs, meta)
  -- Validate options on first call
  if validated_options == nil then
    validated_options = schema.validate_options(meta, EXTENSION_NAME, quarto.utils.resolve_path('_schema.yml'))
  end

  -- Only process for HTML-based formats (excluding epub which won't handle animations)
  if quarto.doc.is_format("html:js") then
    if utils.is_empty(args[1]) then
      utils.log_error(EXTENSION_NAME, "Animation type is required as the first argument.")
      return pandoc.Null()
    end
    if utils.is_empty(args[2]) then
      utils.log_error(EXTENSION_NAME, "Animation text is required as the second argument.")
      return pandoc.Null()
    end
    -- Check for deprecated top-level configuration
    for _, key in ipairs({ 'duration', 'delay', 'repeat' }) do
      _, deprecation_warning_shown = utils.check_deprecated_config(meta, 'animate', key, deprecation_warning_shown)
    end

    -- Build defaults from validated options, falling back to animate_defaults
    local effective_defaults = {}
    for _, key in ipairs({ 'duration', 'delay', 'repeat' }) do
      effective_defaults[key] = validated_options[key] or animate_defaults[key]
    end

    -- Get options using new utility function with fallback hierarchy
    local options = utils.get_options({
      extension = 'animate',
      keys = { 'duration', 'delay', 'repeat' },
      args = kwargs,
      meta = meta,
      defaults = effective_defaults
    })

    -- Ensure required dependencies are loaded (using new utility function)
    utils.ensure_html_dependency({
      name = 'animate',
      version = '4.1.1',
      stylesheets = { "animate.min.css" },
      head = "<style>:root{--animate-duration:" .. options['duration'] ..
          ";--animate-delay:" .. options['delay'] ..
          ";--animate-repeat:" .. options['repeat'] .. "}</style>"
    })

    -- Add RevealJS-specific JavaScript if needed
    if quarto.doc.is_format("revealjs") then
      utils.ensure_html_dependency({
        name = "animatejs",
        scripts = { { path = "animate.js", afterBody = true } }
      })
    end

    -- Validate animation effect using new validation module
    local animation = validation.is_valid_value(
      args[1] and utils.stringify(args[1]) or nil,
      animation_array,
      'animate__animated animate__'
    )
    if animation == nil then
      return pandoc.Null()
    end

    -- Build animation attributes
    local attr_delay = ' animate__delay-' .. options['delay']
    local attr_repeat = options['repeat'] == "infinite"
        and ' animate__infinite'
        or ' animate__repeat-' .. options['repeat']
    local attr_duration = 'style="display: inline-block;animation-duration:' .. options['duration'] .. '"'

    -- Generate and return the animated HTML span element
    local content = args[2] and utils.stringify(args[2]) or ''
    return pandoc.RawInline(
      'html',
      '<span class="' .. animation .. attr_delay .. attr_repeat .. '" ' ..
      attr_duration .. '>' .. content .. '</span>'
    )
  else
    -- Return null for non-HTML formats
    return pandoc.Null()
  end
end

--- Module export table
--- Defines the shortcodes available to Quarto for processing
--- @type table<string, function> Table mapping shortcode names to handler functions
return {
  ["animate"] = animate
}
