import Utils from '../utils'
import createMixin from './create'
import { css, html } from '../css-polyfill'
COUNTER = 0

export default createMixin (options) ->
  { element } = options
  cssId = null
  appendStyles = (styles, scopeCSS=true) ->
    return unless styles
    if Utils.nativeShadowDOM
      script = document.createElement('style')
      script.setAttribute('type', 'text/css')
      script.textContent = styles
      element.renderRoot().appendChild(script)
      return options
    # append globally otherwise
    scope = element.nodeName.toLowerCase()
    unless script = document.head.querySelector("[scope='#{scope}']")
      cssId = "_co#{COUNTER++}"
      styles = css(scope, styles, if scopeCSS then cssId else undefined)
      script = document.createElement('style')
      script.setAttribute('type', 'text/css')
      script.setAttribute('scope', scope)
      script.id = cssId
      script.textContent = styles
      document.head.appendChild(script)
    else cssId = script.id

  transformTemplate = (template) -> html(template, cssId) if cssId and scopeCSS

  { options..., appendStyles, transformTemplate }