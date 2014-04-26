###
 * jQuery Guillotine Plugin v1.0.0
 * http://matiasgagliano.github.com/guillotine/
 *
 * Copyright 2014, Matías Gagliano.
 * Dual licensed under the MIT or GPLv3 licenses.
 * http://opensource.org/licenses/MIT
 * http://opensource.org/licenses/GPL-3.0
 *
###
"use strict"

# ______________________________
#
#           Constants
# ______________________________
#
$ = jQuery
pluginName = 'guillotine'
scope = 'guillotine'

events =
  start: "MSPointerDown.#{scope} touchstart.#{scope} mousedown.#{scope}"
  move:  "MSPointerMove.#{scope} touchmove.#{scope} mousemove.#{scope}"
  stop:  "MSPointerUp.#{scope} touchend.#{scope} mouseup.#{scope}"

defaults =
  width: 400
  height: 300
  zoomStep: 0.1
  eventOnChange: null
    # Event to be triggered after each change (drag, rotate, etc.).
    # E.g. 'transform.guillotine' or 'guillotinechange'
    # The event handler function gets the same arguments and scope as the callback.
    # E.g. (ev, data, action) -> // Do something...
  onChange: null
    # Callback function to be called after each change (drag, rotate, etc.)
    # E.g. (data, action) -> if action == 'rotateLeft' then log(data.angle)
    # 'this' = current element
    # 'data' = { scale: 1.4, angle: 270, x: 10, y: 20, w: 400, h: 300 }
    # 'action' = drag/rotateLeft/rotateRight/center/fit/zoomIn/zoomOut



# ______________________________
#
#             Helpers
# ______________________________
#

# isTouch()
#   Is the event a touch event?
isTouch = (e) -> e.type.search('touch') > -1


# isPointerEventCompatible()
#   Is the device pointer event compatible?
#   (typically means a touch Win8 device)
isPointerEventCompatible = -> ('MSPointerEvent' in window)


# validEvent()
#   Whether the event is a valid action to start dragging or not.
#   Override the function so it checks display type only the first time.
validEvent = (e) ->
  if isPointerEventCompatible() or !isTouch(e)
    # Left click only
    validEvent = (e) -> e.which? and e.which is 1
  else
    # Single touch only
    validEvent = -> e.originalEvent?.touches?.length == 1
  validEvent(e)


# getCursorPosition()
#   Get the position of the cursor when the event is triggered.
#   Override the function so it checks display type only the first time.
getCursorPosition = (e) ->
  if isPointerEventCompatible() or !isTouch(e)
    getCursorPosition = (e) ->
      { x: e.pageX, y: e.pageY }
  else
    getCursorPosition = (e) ->
      e = e.originalEvent.touches[0]
      { x: e.pageX, y: e.pageY }
  getCursorPosition(e)


# canTransform()
#   Whether CSS3 'transform' is supported or not.
#   Override the function so it checks support just once.
canTransform = ->
  hasTransform = false
  prefixes = 'webkit,Moz,O,ms,Khtml'.split(',')
  tests = { transform: 'transform' }
  for prefix in prefixes
    tests[prefix+'Transform'] = "-#{prefix.toLowerCase()}-transform"

  # Create a helper element and add it to the body to get the computed style.
  helper = document.createElement('img')
  document.body.insertBefore(helper, null)

  for test,prop of tests
    continue if helper.style[test] is undefined
    helper.style[test] = 'rotate(90deg)'
    value = window.getComputedStyle(helper).getPropertyValue(prop)
    if value? and value.length and value isnt 'none'
      hasTransform = true; break

  document.body.removeChild(helper)
  if hasTransform
    canTransform = -> true
  else
    canTransform = -> false
  canTransform()



# ______________________________
#
#        The "Guillotine"
# ______________________________
#
class Guillotine
  constructor: (element, options) ->
    # Build options
    # Data attributes (scoped by pluginName, e.g. 'data-guillotine-width')
    # override options, and options override defaults.
    @op = $.extend true, {}, defaults, options, $.data(@, pluginName)
    @zoomInFactor = 1 + @op.zoomStep
    @zoomOutFactor = 1 / @zoomInFactor
    @enabled = true
    @angle = 0

    # Transformation instructions
    @data = {scale: 1, angle: 0, x: 0, y: 0, w: @op.width, h: @op.height}

    # Markup
    @_wrap(element)
    if @el.offsetWidth < @op.width or @el.offsetHeight < @op.height
      @_fit() and @_center()

    # Events
    @$el.on events.start, @_start


  # _____ Private _____
  #

  # Wrap element with the necesary markup
  _wrap: (element) =>
    el = $(element)

    # Get original dimensions
    if el.prop('tagName') is 'IMG'
      # Helper image (full size image)
      # Assumes the target image already existed and that it's cached.
      # It's up to the user to instantiate the plugin after the target is loaded.
      img = document.createElement('img')
      img.setAttribute('src', el.attr('src'))
      # Notice: width and height properties hold the dimensions even
      # though the image hasn't been rendered or appended to the DOM.
      [width, height] = [img.width, img.height]
    else
      # In case of mad experiments (SVGs, canvas, etc.).
      [width, height] = [el.width(), el.height()]

    canvas = $('<div>').addClass('guillotine-canvas')
    canvas.css width: width, height: height, top: 0, left: 0
    canvas = el.wrap(canvas).parent()
    guillotine = $('<div>').addClass('guillotine-window')
    guillotine.css width: @op.width, height: @op.height
    guillotine = canvas.wrap(guillotine).parent()

    # Cache (DOM objects and their jQuery equivalents)
    @$el = el; @el = el[0]
    @$canvas = canvas; @canvas = canvas[0]
    @$gllt = guillotine; @gllt = guillotine[0]
    @$document = $(element.ownerDocument)


  # Back to original state
  _unwrap: =>
    @$el.removeAttr 'style'
    @$el.insertBefore @gllt
    @$gllt.remove()


  _start: (e) =>
    return unless @enabled and validEvent(e)
    e.preventDefault()
    e.stopImmediatePropagation()
    @p = getCursorPosition(e)     # Cursor position before moving (dragging)
    @_bind()


  _bind: =>
    @$document.on events.move, @_drag
    @$document.on events.stop, @_unbind


  _unbind: (e) =>
    @$document.off events.move, @_drag
    @$document.off events.stop, @_unbind  # Unbind this very function (handler)
    @_trigger('drag') if e?


  # Trigger event and/or call callback function
  _trigger: (action) =>
    @$el.trigger @op.eventOnChange, [@data, action] if @op.eventOnChange?
    @op.onChange.call(@el, @data, action) if typeof @op.onChange is 'function'


  _drag: (e) =>
    e.preventDefault()
    e.stopImmediatePropagation()

    p = getCursorPosition(e)           # Cursor position after moving
    dx = p.x - @p.x                    # Difference (cursor movement) on X axes
    dy = p.y - @p.y                    # Difference (cursor movement) on Y axes
    @p = p                             # Update cursor position

    if dx != 0
      offsetLeft = @canvas.offsetLeft
      # Remaining space to the left if moving right (dx > 0) or viceversa.
      gap = - offsetLeft
      gap = @gllt.offsetWidth - (offsetLeft + @canvas.offsetWidth) if dx < 0
      # Horizontal offset
      dx = gap if Math.abs(dx) > Math.abs(gap)
      offsetLeft += dx
      @canvas.style.left = offsetLeft + 'px'
      @data.x = - offsetLeft

    if dy != 0
      offsetTop = @canvas.offsetTop
      # Remaining space to the top if moving down (dy > 0) or viceversa.
      gap = - offsetTop
      gap = @gllt.offsetHeight - (offsetTop + @canvas.offsetHeight) if dy < 0
      # Vertical offset
      dy = gap if Math.abs(dy) > Math.abs(gap)
      offsetTop += dy
      @canvas.style.top = offsetTop + 'px'
      @data.y = - offsetTop


  _zoom: (factor) =>
    return if factor <= 0 or factor == 1
    [width, height] = [@canvas.offsetWidth, @canvas.offsetHeight]

    # Zoom
    [scaledWidth, scaledHeight] = [width * factor, height * factor]
    if scaledWidth > @op.width and scaledHeight > @op.height
      @canvas.style.width = scaledWidth + 'px'
      @canvas.style.height = scaledHeight + 'px'
      @data.scale *= factor
    else
      @_fit()
    [newWidth, newHeight] = [@canvas.offsetWidth, @canvas.offsetHeight]

    # Keep same center when possible
    # (Keep vertical center, fixed bottom or fixed top)
    top = @canvas.offsetTop + (height - newHeight) / 2
    top = @canvas.offsetTop + (height - newHeight) if top + newHeight < @op.height
    top = 0 if top > 0
    # (Keep horizontal center, fixed right or fixed left)
    left = @canvas.offsetLeft + (width - newWidth) / 2
    left = @canvas.offsetLeft + (width - newWidth) if left + newWidth < @op.width
    left = 0 if left > 0
    @canvas.style.top = top + 'px'
    @canvas.style.left = left + 'px'
    @data.x = - left
    @data.y = - top

    # Adjust element's 'translation' within the canvas
    @_transform()


  # Adjast the element (canvas) to the guillotine's edges keeping aspect ratio.
  _fit: =>
    [w, h] = [@canvas.offsetWidth, @canvas.offsetHeight]
    ratio = h / w
    if ratio > @op.height / @op.width    # Relatively higher
      width = @op.width
      height = @op.width * ratio
    else                                  # Relatively wider
      width = @op.height / ratio
      height = @op.height
    @canvas.style.width = width + 'px'
    @canvas.style.height = height + 'px'
    @_transform()  # Adjust element's 'translation' within the canvas
    @data.scale *= width / w


  _center: =>
    top = - (@canvas.offsetHeight - @op.height) / 2
    left = - (@canvas.offsetWidth - @op.width) / 2
    @canvas.style.top =  top + 'px'
    @canvas.style.left =  left + 'px'
    @data.x = - left
    @data.y = - top


  _rotate: (angle) =>
    return unless canTransform() and angle % 90 is 0

    # Smallest positive equivalent angle (total rotation)
    @angle = (@angle + angle) % 360
    @angle = 360 + @angle if @angle < 0

    # Switch canvas dimensions
    width = @canvas.style.width
    @canvas.style.width = @canvas.style.height
    @canvas.style.height = width

    # Adjust the element's dimensions
    # (As percentage so it adjusts automatically when the canvas is zoomed)
    [w, h] = [@canvas.offsetWidth,  @canvas.offsetHeight]
    ratio = if (@angle % 180 is 0) then 1 else h / w
    @el.style.width = ratio * 100 + '%'
    @el.style.height = 100 / ratio + '%'

    # Rotate
    @_transform()
    @_fit() if h < @op.height or w < @op.width
    @_center()
    @data.angle = @angle


  # Set CSS3 transform property
  _transform: =>
    x = if 0 < @angle < 270 then @canvas.offsetWidth else 0
    y = if @angle > 90 then @canvas.offsetHeight else 0
    @$el.css
      'transform-origin': '0px 0px'
      'transform': "translate(#{x}px, #{y}px) rotate(#{@angle}deg)"


  # _____ Public (The API) _____
  #

  # Actions
  rotateLeft:  => @enabled and (@_rotate(-90);          @_trigger('rotateLeft'))
  rotateRight: => @enabled and (@_rotate(90);           @_trigger('rotateRight'))
  center:      => @enabled and (@_center();             @_trigger('center'))
  fit:         => @enabled and (@_fit(); @_center();    @_trigger('fit'))
  zoomIn:      => @enabled and (@_zoom(@zoomInFactor);  @_trigger('zoomIn'))
  zoomOut:     => @enabled and (@_zoom(@zoomOutFactor); @_trigger('zoomOut'))

  # Utilities
  getData: => @data
  enable:  => @enabled = true
  disable: => @enabled = false



# ______________________________
#
#           The Plugin
# ______________________________
#
$.fn[pluginName] = (options) ->

  # Plug it! Lightweight plugin wrapper around the constructor.
  if typeof options isnt 'string'
    @each ->
      # Prevent multiple instantiation
      unless $.data(@, pluginName + 'Instance')
        # Guillotine's instance
        guillotine = new Guillotine(@, options)
        $.data(@, pluginName + 'Instance', guillotine)


  # Plugin's API
  else
    switch method = options
      # Return guillotine's instance for the first element
      when 'instance'
        $.data(@[0], pluginName + 'Instance')

      # Remove plugin for each element
      when 'remove'
        @each ->
          guillotine = $.data(@, pluginName + 'Instance')
          return unless guillotine?
          guillotine._unbind()
          guillotine._unwrap()
          guillotine.disable()
          guillotine.$el.off events.start, guillotine._start
          guillotine.$el.removeData(pluginName + 'Instance')

      # Return data (coords, angle, scale) for the first element
      when 'getData'
        $.data(@[0], pluginName + 'Instance')?['getData'].call()

      # Use Guillotine's API through the plugin
      # E.g. element.guillotine('rotateLeft')
      when 'rotateLeft','rotateRight','center','fit', \
           'zoomIn','zoomOut', 'enable', 'disable'
        @each ->
          guillotine = $.data(@, pluginName + 'Instance')
          return unless guillotine?
          guillotine[method].call()
