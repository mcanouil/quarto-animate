# Animate.css Extension for Quarto

This extension provides support and shortcode to [animate.css](https://animate.style/).

Animations are only available for HTML-based documents.

## Installation

```sh
quarto add mcanouil/quarto-animate
```

This will install the extension under the `_extensions` subdirectory.

If you're using version control, you will want to check in this directory.

## Usage

To animate a text, use the `{{< animate >}}` shortcode. For example:

```markdown
{{< animate bounce "Some text" >}}
```

- Mandatory `<effect>` and `<text>`:

  ``` markdown
  {{< animate <effect> "<text>" >}}
  ```

- Optional `<delay=...>`, `<duration=...>`, and `<repeat=...>`:

  ``` markdown
  {{< animate <effect> "<text>" <delay=...> <duration=...> <repeat=...> >}}
  ```

  `<delay=...>` and `<duration=...>` are durations requiring unit, _e.g._, `1s` or `800ms`. See <https://animate.style/> for more details.

Defining default values for animations can be done in the YAML front matter of your document:

```yml
extensions:
  animate:
    delay: 5s
    duration: 10s
    repeat: 3
```

## Advanced

The following won't work:

```markdown
{{< animate bounce "[HTML](https://m.canouil.dev/quarto-animate/)" >}}
```

But this will:

```markdown
[[HTML](https://m.canouil.dev/quarto-animate/)]{.animate__animated .animate__bounce style="display:inline-block;"}
```

Or:

```markdown
::: {.animate__animated .animate__bounce}
[HTML](https://m.canouil.dev/quarto-animate/)
:::
```

See <https://animate.style/> for more details.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

Output of `example.qmd`:

- [HTML](https://m.canouil.dev/quarto-animate/)

## Animation Effects

- **Attention seekers**: `bounce`, `flash`, `pulse`, `rubberBand`, `shakeX`, `shakeY`, `headShake`, `swing`, `tada`, `wobble`, `jello`, `heartBeat`.
- **Back entrances**: `backInDown`, `backInLeft`, `backInRight`, `backInUp`.
- **Back exits**: `backOutDown`, `backOutLeft`, `backOutRight`, `backOutUp`.
- **Bouncing entrances**: `bounceIn`, `bounceInDown`, `bounceInLeft`, `bounceInRight`, `bounceInUp`.
- **Bouncing exits**: `bounceOut`, `bounceOutDown`, `bounceOutLeft`, `bounceOutRight`, `bounceOutUp`.
- **Fading entrances**: `fadeIn`, `fadeInDown`, `fadeInDownBig`, `fadeInLeft`, `fadeInLeftBig`, `fadeInRight`, `fadeInRightBig`, `fadeInUp`, `fadeInUpBig`, `fadeInTopLeft`, `fadeInTopRight`, `fadeInBottomLeft`, `fadeInBottomRight`.
- **Fading exits**: `fadeOut`, `fadeOutDown`, `fadeOutDownBig`, `fadeOutLeft`, `fadeOutLeftBig`, `fadeOutRight`, `fadeOutRightBig`, `fadeOutUp`, `fadeOutUpBig`, `fadeOutTopLeft`, `fadeOutTopRight`, `fadeOutBottomRight`, `fadeOutBottomLeft`.
- **Flippers**: `flip`, `flipInX`, `flipInY`, `flipOutX`, `flipOutY`.
- **Lightspeed**: `lightSpeedInRight`, `lightSpeedInLeft`, `lightSpeedOutRight`, `lightSpeedOutLeft`.
- **Rotating entrances**: `rotateIn`, `rotateInDownLeft`, `rotateInDownRight`, `rotateInUpLeft`, `rotateInUpRight`.
- **Rotating exits**: `rotateOut`, `rotateOutDownLeft`, `rotateOutDownRight`, `rotateOutUpLeft`, `rotateOutUpRight`.
- **Specials**: `hinge`, `jackInTheBox`, `rollIn`, `rollOut`.
- **Zooming entrances**: `zoomIn`, `zoomInDown`, `zoomInLeft`, `zoomInRight`, `zoomInUp`.
- **Zooming exits**: `zoomOut`, `zoomOutDown`, `zoomOutLeft`, `zoomOutRight`, `zoomOutUp`.
- **Sliding entrances**: `slideInDown`, `slideInLeft`, `slideInRight`, `slideInUp`.
- **Sliding exits**: `slideOutDown`, `slideOutLeft`, `slideOutRight`, `slideOutUp`.

---

[Animate.css](https://animate.style/) by Daniel Eden under Hippocratic License 3.0.
