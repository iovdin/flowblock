@getStyle = (el, styleProp) ->
    defaultView = (el.ownerDocument || document).defaultView
    if defaultView and defaultView.getComputedStyle
        style = defaultView.getComputedStyle el, null
        return style and style.getPropertyValue styleProp

    if el.currentStyle
        return el.currentStyle[styleProp]
    return

makecss = (keys, values) ->
    result = []
    if typeof keys == "string" and typeof values == "string"
        result.push [keys, values]

    if typeof keys == "string" and typeof values == "object"
        result.push [keys, value] for value in values

    if typeof keys == "object" and typeof values == "string"
        result.push [key, values] for key in keys

    return result


css =
    flexbox : ["-webkit-box", "-moz-box", "-ms-flexbox", "-webkit-flex", "flex"]
    flex : ["-webkit-box-flex", "-moz-box-flex", "-webkit-flex", "-ms-flex", "flex"]
    "flex-grow" : ["-webkit-flex-grow", "flex-grow"]
    "flex-shrink" : ["-webkit-flex-shrink", "flex-shrink"]
    "flex-basis" : ["-webkit-flex-basis", "flex-basis"]
    align : ["-webkit-align-items", "align-items", "-webkit-align-content", "align-content"]
    justify : ["-webkit-justify-content", "justify-content"]
    direction : ["-webkit-flex-direction", "flex-direction"]
    wrap : ["flex-wrap", "-webkit-flex-wrap"]

props =
    container:
        direction: "row"
        justify : "stretch"
        align : "stretch"
        wrap : "wrap"
    item:
        grow : 0
        shrink: 0
        basis: "auto"


@props2css = (props) ->
    result = []
    container = props.container
    item = props.item
    if container
        result.push.apply result, makecss "display", css.flexbox
        result.push.apply result, makecss css.direction, container.direction if container.direction?
        result.push.apply result, makecss css.justify, container.justify if container.justify?
        result.push.apply result, makecss css.align, container.align if container.align?
        result.push.apply result, makecss css.wrap, if container.wrap? then "wrap" else "nowrap"
    else
        result.push.apply result, makecss "display", "block"

#TODO parse flex-grow flex-shrink flex-basis, because flex is empty
    itemValue = "0 0 auto"
    itemValue = [ item.grow or 0, item.shrink or 0, item.basis or "auto"].join " " if item

    result.push.apply result, makecss css.flex, itemValue

    ("#{item[0]} : #{item[1]};" for item in result).join "\n"

@cssValue = (element, keys) ->
    values = (getStyle element, key for key in keys)
    values = (value for value in values when value? and value != "")
    return values and values.pop()

@css2props = (element) ->
    #console.log "css2props", element
    result = item : {}

    displayStyle = getStyle element, "display"
    container = result.container = {} if displayStyle in css.flexbox

    if container
        container[key] = cssValue element, css[key] for key in ["direction", "justify", "align", "wrap"]

    item = result.item
    itemValue = (cssValue element, css.flex) or "0 0 auto"
    [item.grow, item.shrink, item.basis] = itemValue.split " "
    result.item = undefined if item.grow == "0" and item.shrink =="0" and item.basis == "auto"
    return result

