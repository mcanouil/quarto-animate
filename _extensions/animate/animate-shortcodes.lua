local function ensureHtmlDeps()
  quarto.doc.addHtmlDependency({
    name = 'animate',
    version = '4.1.1',
    stylesheets = {"animate.min.css"}
  })
end

local function isEmpty(s)
  return s == nil or s == ''
end

local function isValidAnimation(effect)
  if isEmpty(effect) then
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
  if not isEmpty(meta['ani-delay']) then
    yamlAniDelay = meta['ani-delay']
  end
  if not isEmpty(meta['ani-duration']) then
    yamlAniDuration = meta['ani-duration']
  end
  if not isEmpty(meta['ani-repeat']) then
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
    if quarto.doc.isFormat("html:js") then
      ensureHtmlDeps()
      quarto.doc.includeText(
        "in-header",
        "<style>:root{--animate-duration:" .. yamlAniDuration .. ";--animate-delay:" .. yamlAniDelay .. ";--animate-repeat:" .. yamlAniRepeat .. "}</style>"
      )

      local animation = isValidAnimation(pandoc.utils.stringify(args[1]))
      if isEmpty(animation) then
        return pandoc.Null()
      end

      local aniDelay = pandoc.utils.stringify(kwargs["delay"])
      if isEmpty(aniDelay) then
        attr_delay = ''
      else
        attr_delay = ' animate__delay-' .. aniDelay
      end

      local aniRepeat = pandoc.utils.stringify(kwargs["repeat"])
      if isEmpty(aniRepeat) then
        attr_repeat = ''
      else
        if (aniRepeat == "infinite") then
          attr_repeat = ' animate__' .. aniRepeat
        else
          attr_repeat = ' animate__repeat-' .. aniRepeat
        end
      end

      local aniDuration = pandoc.utils.stringify(kwargs["duration"])
      if isEmpty(aniDuration) then
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
