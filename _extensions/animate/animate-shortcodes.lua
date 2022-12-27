local function ensure_html_deps()
  quarto.doc.add_html_dependency({
    name = 'animate',
    version = '4.1.1',
    stylesheets = {"animate.min.css"}
  })
end

local function is_empty(s)
  return s == nil or s == ''
end

local function is_valid_animation(effect)
  if is_empty(effect) then
    return ''
  end
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
  for _, value in ipairs(animation_array) do
    if value == effect then
      return 'animate__animated animate__' .. effect
    end
  end
  return ''
end

local yamlAniDuration = "3s"
local yamlAniDelay = "2s"
local yamlAniRepeat = "1"

function setAniOptions(meta)
  if not is_empty(meta['ani-delay']) then
    yamlAniDelay = meta['ani-delay']
  end
  if not is_empty(meta['ani-duration']) then
    yamlAniDuration = meta['ani-duration']
  end
  if not is_empty(meta['ani-repeat']) then
    yamlAniRepeat = meta['ani-repeat']
  end
  meta['ani-delay'] = yamlAniDelay
  meta['ani-duration'] = yamlAniDuration
  meta['ani-repeat'] = yamlAniRepeat
  return meta
end

return {
  {Meta = setAniOptions},
  ["animate"] = function(args, kwargs)
    -- detect html (excluding epub which won't handle fa)
    if quarto.doc.is_format("html:js") then
      ensure_html_deps()
      quarto.doc.include_text(
        "in-header",
        "<style>:root{--animate-duration:" .. yamlAniDuration .. ";--animate-delay:" .. yamlAniDelay .. ";--animate-repeat:" .. yamlAniRepeat .. "}</style>"
      )

      local animation = is_valid_animation(pandoc.utils.stringify(args[1]))
      if is_empty(animation) then
        return pandoc.Null()
      end

      local aniDelay = pandoc.utils.stringify(kwargs["delay"])
      if is_empty(aniDelay) then
        attr_delay = ''
      else
        attr_delay = ' animate__delay-' .. aniDelay
      end

      local aniRepeat = pandoc.utils.stringify(kwargs["repeat"])
      if is_empty(aniRepeat) then
        attr_repeat = ''
      else
        if (aniRepeat == "infinite") then
          attr_repeat = ' animate__' .. aniRepeat
        else
          attr_repeat = ' animate__repeat-' .. aniRepeat
        end
      end

      local aniDuration = pandoc.utils.stringify(kwargs["duration"])
      if is_empty(aniDuration) then
        attr_duration = 'style="display: inline-block;"'
      else
        attr_duration = 'style="display: inline-block;animation-duration:' .. aniDuration .. '"'
      end

      return pandoc.RawInline(
        'html',
        '<span class="' .. animation .. attr_delay .. attr_repeat .. '" ' .. attr_duration .. '>' .. pandoc.utils.stringify(args[2]) .. '</span>'
      )
    else
      return pandoc.Null()
    end
  end
}
