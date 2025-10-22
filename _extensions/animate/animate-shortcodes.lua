--[[
# MIT License
#
# Copyright (c) 2025 Mickaël Canouil
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
]]

--- Load utils module
local utils_path = quarto.utils.resolve_path("utils.lua")
local utils = require(utils_path)


--- Validate if the effect is a supported animation.
--- Checks if the provided animation effect is supported by the Animate.css library.
--- Returns the formatted CSS classes if valid, or an empty string if invalid.
--- @param effect string|nil The animation effect name to validate
--- @return string The formatted CSS class string or empty string if invalid
--- @usage local classes = is_valid_animation("bounce") -- returns "animate__animated animate__bounce"
--- @usage local classes = is_valid_animation("invalid") -- returns ""
--- @see https://animate.style/ For complete list of available animations
local function is_valid_animation(effect)
  if utils.is_empty(effect) then
    return ''
  end

  --- Array of supported animation effects from Animate.css library
  --- @type string[] List of all valid animation names
  local animation_array = {
    "bounce",
    "flash",
    "pulse",
    "rubberBand",
    "shakeX",
    "shakeY",
    "headShake",
    "swing",
    "tada",
    "wobble",
    "jello",
    "heartBeat",
    "backInDown",
    "backInLeft",
    "backInRight",
    "backInUp",
    "backOutDown",
    "backOutLeft",
    "backOutRight",
    "backOutUp",
    "bounceIn",
    "bounceInDown",
    "bounceInLeft",
    "bounceInRight",
    "bounceInUp",
    "bounceOut",
    "bounceOutDown",
    "bounceOutLeft",
    "bounceOutRight",
    "bounceOutUp",
    "fadeIn",
    "fadeInDown",
    "fadeInDownBig",
    "fadeInLeft",
    "fadeInLeftBig",
    "fadeInRight",
    "fadeInRightBig",
    "fadeInUp",
    "fadeInUpBig",
    "fadeInTopLeft",
    "fadeInTopRight",
    "fadeInBottomLeft",
    "fadeInBottomRight",
    "fadeOut",
    "fadeOutDown",
    "fadeOutDownBig",
    "fadeOutLeft",
    "fadeOutLeftBig",
    "fadeOutRight",
    "fadeOutRightBig",
    "fadeOutUp",
    "fadeOutUpBig",
    "fadeOutTopLeft",
    "fadeOutTopRight",
    "fadeOutBottomRight",
    "fadeOutBottomLeft",
    "flip",
    "flipInX",
    "flipInY",
    "flipOutX",
    "flipOutY",
    "lightSpeedInRight",
    "lightSpeedInLeft",
    "lightSpeedOutRight",
    "lightSpeedOutLeft",
    "rotateIn",
    "rotateInDownLeft",
    "rotateInDownRight",
    "rotateInUpLeft",
    "rotateInUpRight",
    "rotateOut",
    "rotateOutDownLeft",
    "rotateOutDownRight",
    "rotateOutUpLeft",
    "rotateOutUpRight",
    "hinge",
    "jackInTheBox",
    "rollIn",
    "rollOut",
    "zoomIn",
    "zoomInDown",
    "zoomInLeft",
    "zoomInRight",
    "zoomInUp",
    "zoomOut",
    "zoomOutDown",
    "zoomOutLeft",
    "zoomOutRight",
    "zoomOutUp",
    "slideInDown",
    "slideInLeft",
    "slideInRight",
    "slideInUp",
    "slideOutDown",
    "slideOutLeft",
    "slideOutRight",
    "slideOutUp",
  }

  -- Check if the provided effect matches any supported animation
  for _, value in ipairs(animation_array) do
    if value == effect then
      return 'animate__animated animate__' .. effect
    end
  end

  -- Return empty string if animation is not supported
  return ''
end

--- Default animation options configuration
--- @type table<string, string> Default values for animation properties
local animate_options = {
  ["duration"] = "3s", -- Default animation duration
  ["delay"] = "2s",    -- Default animation delay before starting
  ["repeat"] = "1"     -- Default number of animation repetitions
}

--- Global variable to track if HTML dependencies have been added
--- Prevents duplicate dependency injection in the document
--- @type boolean Flag indicating whether HTML dependencies are already loaded
local html_deps_added = false

--- Get animate option from arguments or metadata.
--- Retrieves animation configuration values with fallback hierarchy:
--- 1. Document metadata values
--- 2. Default values from animate_options
--- @param x string The option key to retrieve (duration, delay, repeat)
--- @param meta table|nil Document metadata containing animate configuration
--- @param default table<string, string> Default options table to fall back to
--- @return string The resolved option value
--- @usage local duration = get_animate_options('duration', meta['animate'], animate_options)
local function get_animate_options(x, meta, default)
  if meta and meta[x] and not utils.is_empty(meta[x]) then
    return utils.stringify(meta[x])
  end
  return default[x]
end

--- Ensure HTML dependencies for animate are added.
--- Adds the necessary CSS and JavaScript dependencies for animations to work.
--- Only adds dependencies once per document to avoid duplication.
--- Handles both regular HTML output and RevealJS presentations.
--- @param options table<string, string> Animation options containing duration, delay, and repeat values
--- @return nil This function doesn't return a value, it modifies the document
--- @usage ensure_html_deps({duration = "2s", delay = "1s", repeat = "3"})
local function ensure_html_deps(options)
  -- Exit early if dependencies are already added
  if html_deps_added then
    return
  end

  -- Add core Animate.css stylesheet and CSS custom properties
  quarto.doc.add_html_dependency({
    name = 'animate',
    version = '4.1.1',
    stylesheets = { "animate.min.css" },
    head = "<style>:root{--animate-duration:" .. options['duration'] ..
        ";--animate-delay:" .. options['delay'] ..
        ";--animate-repeat:" .. options['repeat'] .. "}</style>"
  })

  -- Add additional JavaScript for RevealJS presentations
  if quarto.doc.is_format("revealjs") then
    quarto.doc.add_html_dependency({
      name = "animatejs",
      scripts = { { path = "animate.js", afterBody = true } }
    })
  end

  -- Mark dependencies as added to prevent duplication
  html_deps_added = true
end

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
function animate(args, kwargs, meta)
  -- Only process for HTML-based formats (excluding epub which won't handle animations)
  if quarto.doc.is_format("html:js") then
    -- Build options table with fallbacks to metadata or defaults
    local options = {
      ["duration"] = get_animate_options('duration', meta and meta['animate'] or nil, animate_options),
      ["delay"] = get_animate_options('delay', meta and meta['animate'] or nil, animate_options),
      ["repeat"] = get_animate_options('repeat', meta and meta['animate'] or nil, animate_options)
    }

    -- Ensure required dependencies are loaded
    ensure_html_deps(options)

    -- Validate and get animation CSS classes
    local animation = is_valid_animation(utils.stringify(args[1]))
    if utils.is_empty(animation) then
      return pandoc.Null()
    end

    -- Process delay parameter with fallback to options
    local animate_delay = utils.stringify(kwargs["delay"]) or options['delay']
    if utils.is_empty(animate_delay) then
      animate_delay = options['delay']
    end
    local attr_delay = ' animate__delay-' .. animate_delay

    -- Process repeat parameter with fallback to options
    local animate_repeat = utils.stringify(kwargs["repeat"])
    if utils.is_empty(animate_repeat) then
      animate_repeat = options['repeat']
    end
    local attr_repeat = ''
    if (animate_repeat == "infinite") then
      attr_repeat = ' animate__' .. animate_repeat
    else
      attr_repeat = ' animate__repeat-' .. animate_repeat
    end

    -- Process duration parameter with fallback to options
    local animate_duration = utils.stringify(kwargs["duration"]) or options['duration']
    if utils.is_empty(animate_duration) then
      animate_duration = options['duration']
    end
    local attr_duration = 'style="display: inline-block;animation-duration:' .. animate_duration .. '"'

    -- Generate and return the animated HTML span element
    return pandoc.RawInline(
      'html',
      '<span class="' .. animation .. attr_delay .. attr_repeat .. '" ' ..
      attr_duration .. '>' .. utils.stringify(args[2]) .. '</span>'
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
