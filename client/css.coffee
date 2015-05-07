@getStyle = (element, key) ->
    if typeof key == "object"
        keys = key
        values = (getStyle element, key for key in keys)
        values = (value for value in values when value? and value != "")
        return values and values.pop()

    defaultView = (element.ownerDocument || document).defaultView
    if defaultView and defaultView.getComputedStyle
        style = defaultView.getComputedStyle element, null
        return style and style.getPropertyValue key

    if element.currentStyle
        return element.currentStyle[key]
    return

makecss = (keys, values) ->
    result = []
    if typeof keys == "string" and typeof values == "string"
        return [keys, values]

    if typeof keys == "string" and typeof values == "object"
        result.push [keys, value] for value in values

    if typeof keys == "object" and typeof values == "string"
        result.push [key, values] for key in keys

    return result


@prefixes =
    "display"         : ["-webkit-box", "-moz-box", "-ms-flexbox", "-webkit-flex", "flex"]
    "flex"            : ["-webkit-box-flex", "-moz-box-flex", "-webkit-flex", "-ms-flex", "flex"]
    "flex-grow"       : ["-webkit-flex-grow", "flex-grow"]
    "flex-shrink"     : ["-webkit-flex-shrink", "flex-shrink"]
    "flex-basis"      : ["-webkit-flex-basis", "flex-basis"]
    "align-items"     : ["-webkit-align-items", "align-items"]
    "justify-content" : ["-webkit-justify-content", "justify-content"]
    "flex-direction"  : ["-webkit-flex-direction", "flex-direction"]
    "flex-wrap"       : ["flex-wrap", "-webkit-flex-wrap"]

props =
    "selector" : "body"
    "display" : "flex"
    "flex-direction" : "row"
    "flex-wrap" : "nowrap"
    "justify-content" : "center"
    "align-items" : "center"
    "flex" : "0 1 auto"
    "flex-grow" : 0
    "flex-shrink" : 1
    "flex-basis" : "auto"


@props2css = (props) ->
    result = []
    container = props.container
    item = props.item
    if props.display == "flex"
        result.push.apply result, makecss "display", prefixes.display
        result.push.apply result, makecss prefixes[key], props[key] for key in ["flex-direction", "flex-wrap", "justify-content", "align-items"]
    else
        result.push.apply result, makecss "display", "block"

    console.log props
    if props.flex?
        result.push.apply result, makecss prefixes.flex, props.flex
    else
        result.push.apply result, makecss prefixes[key], props[key] for key in ["flex-grow", "flex-shrink", "flex-basis"]
    ("#{item[0]} : #{item[1]};" for item in result).join "\n"


@css2props = (element) ->
    result = {}

    displayStyle = getStyle element, "display"
    if displayStyle in prefixes.display
        result.display = "flex"
        result[key] = getStyle element, prefixes[key] for key in ["flex-direction", "flex-wrap", "justify-content", "align-items"]
    else
        result.display = displayStyle

    result[key] = getStyle element, prefixes[key] for key in ["flex-grow", "flex-shrink", "flex-basis"]
    result.flex = result["flex-grow"] + " " + result["flex-shrink"] + " " + result["flex-basis"]
    return result

