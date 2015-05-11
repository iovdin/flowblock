
@getStyle = (element, key) ->
    if typeof key == "object"
        keys = key
        values = (getStyle element, key for key in keys)
        values = (value for value in values when value? and value != "")
        return values and values.pop()

    if element.type is "rule"
        return decl.value for decl in element.declarations when decl.property == key

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

selectValidator = (cases) ->
    return (value) ->
        return value in cases

isNumber = (value) ->
    return true if _.isNumber value and value >= 0
    if _.isString value
        parsed = parseFloat value
        return false if _.isNaN parsed
        return true if parsed >= 0
    return false

String.prototype.endsWith = (suffix) ->
    return this.indexOf(suffix, this.length - suffix.length) isnt -1


isLength = (value) ->
    return true if isNumber value
    return false unless _.isString value

    #TODO validate number
    return true if value.endsWith ext for ext in ["px", "mm", "cm", "in", "pt", "pc", "em", "ex", "ch", "rem", "%"]
    return false


@validators =
    "display" : selectValidator ["flex", "flex-inline", "block", "inline", "none"]
    "flex-direction" : selectValidator ["row" , "row-reverse" , "column" , "column-reverse"]
    "flex-wrap" : selectValidator ["wrap", "nowrap", "wrap-reverse"]
    "justify-content" : selectValidator ["flex-start" , "flex-end" , "center", "space-between" , "space-around"]
    "align-items" : selectValidator [ "flex-start" , "flex-end" , "center" , "baseline" , "stretch" ]
    "flex-shrink" : isNumber
    "flex-grow" : isNumber
    "flex-basis" : (value) ->
        return true if value is "auto"
        return isLength value


@getProps = (element) ->
    result = {}
    return result unless element?
    if element.type == "rule"
        result.selector = element.selectors[0]
    else if $(element).attr("id")
        result.selector = "#" + $(element).attr("id")
    else
        result.selector = element.tagName.toLowerCase() unless selector?

    displayStyle = getStyle element, "display"
    if displayStyle in prefixes.display
        result.display = "flex"
        for key in ["flex-direction", "flex-wrap", "justify-content", "align-items"]
            style = getStyle element, prefixes[key]
            result[key] = style if style?
    else
        result.display = displayStyle if displayStyle?

    for key in ["flex-grow", "flex-shrink", "flex-basis"]
        style = getStyle element, prefixes[key]
        result[key] = style if style?

    if result["flex-grow"] and result["flex-shrink"] and result["flex-basis"]
        result.flex = result["flex-grow"] + " " + result["flex-shrink"] + " " + result["flex-basis"]

    return result

decl = (key, value, expandPrefixes = false) ->
    return type : "declaration",  property : key, value : value unless expandPrefixes
    if key is "display"
        if value is "flex"
            return _.map prefixes.display, (prefix) ->
                return decl "display", prefix
        return type : "declaration",  property : "display", value : value

    if prefixes[key]
        return _.map prefixes[key], (prefix) ->
            return decl prefix, value
    return []

@props2rule = (props, expandPrefixes = false) ->
    rule =
        type : "rule"
        selectors : [props.selector]
        declarations : []

    decls = []
    if props.display is "flex"
        decls.push decl "display", "flex", expandPrefixes
        decls.push decl key, props[key], expandPrefixes for key in ["flex-direction", "flex-wrap", "justify-content", "align-items"] when props[key]?
    else
        decls.push decl "display", props.display or "block", expandPrefixes

    decls.push decl key, props[key], expandPrefixes for key in ["flex-grow", "flex-shrink", "flex-basis"] when props[key]?
    rule.declarations = _.flatten decls
    return rule

compiler = new Compiler

@props2css = (props, expandPrefixes = false) ->
    rule = props2rule props, expandPrefixes
    return compiler.mapVisit rule.declarations, "\n"
