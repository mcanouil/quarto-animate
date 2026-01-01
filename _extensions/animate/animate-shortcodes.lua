--[[
# MIT License
#
# Copyright (c) 2026 Mickaël Canouil
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
]]

--- Extension name constant
local EXTENSION_NAME = 'animate'

--- Load utils and validation modules
local utils = require(quarto.utils.resolve_path("_modules/utils.lua"):gsub("%.lua$", ""))
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

    -- Get options using new utility function with fallback hierarchy
    local options = utils.get_options({
      extension = 'animate',
      keys = { 'duration', 'delay', 'repeat' },
      args = kwargs,
      meta = meta,
      defaults = animate_defaults
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
