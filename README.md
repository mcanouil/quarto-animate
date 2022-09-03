# Animate.css Extension for Quarto

This extension provides support and shortcode to [animate.css](https://animate.style/).  
Animations are only available for HTML-based documents.

## Installing

```sh
quarto install extension mcanouil/quarto-animate
```

This will install the extension under the `_extensions` subdirectory.  
If you're using version control, you will want to check in this directory.

## Using

To animate a text, use the `{{< ani >}}` shortcode. For example:

```markdown
{{< animate bounce "Some text" >}}
```

It provides an `{{{< animate >}}}` shortcode:

- Mandatory `<effect>`[^1] and `<text>`:
  ``` markdown
  {{< animate <effect> <text> >}}
  ```

- Optional `<delay=...>`, `<duration=...>`, and `<repeat=...>`:
  ``` markdown
  {{< animate <effect> <text> <delay=...> <duration=...> <repeat=...> >}}
  ```
  `<delay=...>` and `<duration=...>` are durations requiring unit, _e.g._, `1s` or `800ms`.  
  See <https://animate.style/> for more details.

[^1]: The following effects are available:

-  __Attention seekers__: `bounce`, `flash`, `pulse`, `rubberBand`, `shakeX`, `shakeY`, `headShake`, `swing`, `tada`, `wobble`, `jello`, `heartBeat`.
- __Back entrances__: `backInDown`, `backInLeft`, `backInRight`, `backInUp`.
- __Back exits__: `backOutDown`, `backOutLeft`, `backOutRight`, `backOutUp`.
- __Bouncing entrances__: `bounceIn`, `bounceInDown`, `bounceInLeft`, `bounceInRight`, `bounceInUp`.
- __Bouncing exits__: `bounceOut`, `bounceOutDown`, `bounceOutLeft`, `bounceOutRight`, `bounceOutUp`.
- __Fading entrances__: `fadeIn`, `fadeInDown`, `fadeInDownBig`, `fadeInLeft`, `fadeInLeftBig`, `fadeInRight`, `fadeInRightBig`, `fadeInUp`, `fadeInUpBig`, `fadeInTopLeft`, `fadeInTopRight`, `fadeInBottomLeft`, `fadeInBottomRight`.
- __Fading exits__: `fadeOut`, `fadeOutDown`, `fadeOutDownBig`, `fadeOutLeft`, `fadeOutLeftBig`, `fadeOutRight`, `fadeOutRightBig`, `fadeOutUp`, `fadeOutUpBig`, `fadeOutTopLeft`, `fadeOutTopRight`, `fadeOutBottomRight`, `fadeOutBottomLeft`.
- __Flippers__: `flip`, `flipInX`, `flipInY`, `flipOutX`, `flipOutY`.
- __Lightspeed__: `lightSpeedInRight`, `lightSpeedInLeft`, `lightSpeedOutRight`, `lightSpeedOutLeft`.
- __Rotating entrances__: `rotateIn`, `rotateInDownLeft`, `rotateInDownRight`, `rotateInUpLeft`, `rotateInUpRight`.
- __Rotating exits__: `rotateOut`, `rotateOutDownLeft`, `rotateOutDownRight`, `rotateOutUpLeft`, `rotateOutUpRight`.
- __Specials__: `hinge`, `jackInTheBox`, `rollIn`, `rollOut`.
- __Zooming entrances__: `zoomIn`, `zoomInDown`, `zoomInLeft`, `zoomInRight`, `zoomInUp`.
- __Zooming exits__: `zoomOut`, `zoomOutDown`, `zoomOutLeft`, `zoomOutRight`, `zoomOutUp`.
- __Sliding entrances__: `slideInDown`, `slideInLeft`, `slideInRight`, `slideInUp`.
- __Sliding exits__: `slideOutDown`, `slideOutLeft`, `slideOutRight`, `slideOutUp`.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

This is the output of `example.qmd` for [HTML](https://m.canouil.fr/quarto-animate/).
