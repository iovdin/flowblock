Compiler =  require './lib/css_compiler'
parseCss = require './lib/css_parser'
React = require 'react'
$ = require 'jquery'
_ = require 'underscore'


CSSDeclaration = React.createClass
    getInitialState: ->
        text: @props.value, valid : yes
    onChange : (e) ->
        newState = text : e.target.value
        changeProp @props.name, newState.text if validators[@props.name]?(newState.text)
        @setState newState
    render: ->
        valid = validators[@props.name](@state.text)
        #console.log "isValid", valid, @state.text, validators[@props.name]
        valStyle = color : "blue"
        valStyle = color : "red" unless valid
        return <li>
        <span className="css-key">{@props.name}</span> : 
        <input style={valStyle} value={@state.text} onChange={@onChange}/>
        </li>

CSSEditor = React.createClass
    render: ->
        unless @props.node?
            return <div>nothing selected </div>

        styleProps = getProps @props.node
        decl = (name) ->
            <CSSDeclaration key={styleProps.selector + name} name={name} value={styleProps[name]}/>
        <div>
            <span className="css-selector">{styleProps.selector}</span> &#123;
            <ul>
                {decl "display"}
                { <span>
                    {decl "flex-direction"}
                    {decl "justify-content"}
                    {decl "align-items"}
                </span>if styleProps.display is "flex" }
                <br/>
                    {decl "flex-grow"}
                    {decl "flex-shrink"}
                    {decl "flex-basis"}
            </ul>
            &#125;
        </div>


style = """
html {
    min-height : 100%;

    display: -webkit-box;
    display: -moz-box;
    display: -ms-flexbox;
    display: -webkit-flex;
    display: flex;

}
body {
    display: -webkit-box;
    display: -moz-box;
    display: -ms-flexbox;
    display: -webkit-flex;
    display: flex;

    -webkit-justify-content : center;
    -webkit-align-items : center;
    -webkit-align-content : center;
    justify-content : center;
    align-items : center;
    align-content : center;

    flex-grow: 1;
    -webkit-flex-grow: 1;
}
#content1 {

}
#content2 {

}
"""

body = """
<body>
    <div id="content1">content1</div>
    <div id="content2">content2</div>
</body>
"""

rootNode = null
curNode = null
editor = null

$(document).ready ->

    style = localStorage.getItem("style") or style
    body = localStorage.getItem("body") or body

    iframe = $("iframe")[0]
    doc = iframe.contentWindow.document

    $(iframe).contents().find("head").append("""
    <style type="text/css">
        body, div {
            background: #EEEEEE;
            border: 1px solid black;
            margin: 5px;
        }
        .block-over {
            background: #EEEEFF;
        }
        .block-selected {
            border: 2px solid tomato;
        }

        #{style}
    </style>
""")

    $("#css_src").text(style)
    doc.body.outerHTML = body
    rootNode = curNode = doc.body
    $("#html_src").text(body)

    $(rootNode).click (e) ->
        selectNode e.target
    $(rootNode).keypress (e) ->
        return unless e.which in [8, 46]
        removeNode()

    #rule = parsedCSS.stylesheet.rules[0]

    editor = React.render <CSSEditor/>, document.getElementById "code-editor"
    selectNode rootNode

genCode = () ->
    styleAst = parseCss style
    
    #remove all rules except html and body
    rules = (rule for rule in styleAst.stylesheet.rules when rule.selectors[0] is 'html')

    compiler = new Compiler

    rules.push props2rule getProps(rootNode), true

    $(rootNode).find("div").each (i, div) ->
        rules.push props2rule getProps(div), true

    styleAst.stylesheet.rules = rules
    style = compiler.visit styleAst
    localStorage.setItem "style", style
    $("#css_src").text(style)

    #html
    b =  $(rootNode).clone()
    $(b).find("div").removeAttr("style").removeAttr("class")
    $(b).removeAttr("class").removeAttr("style")
    body = $('<div>').append($(b).clone()).html()
    localStorage.setItem("body", body)
    $("#html_src").text(body)

selectNode = (target) ->
    return unless target?
    if target != curNode
        $(curNode).removeClass "block-selected" if curNode
        curNode = target
    else
        $(curNode).removeClass "block-selected"
        curNode = rootNode

    $(curNode).addClass "block-selected"
    editor.setProps {node : curNode}

changeProp = (name, value) ->
    props = getProps curNode
    props[name] = value
    $(curNode).attr "style", props2css props, true
    #editor = React.render <CSSEditor node={curNode}/>, document.getElementById "code-editor"
    editor.setProps {node : curNode}

    genCode()

newId = () ->
    prefix = "content"
    i = 1
    i++ while $(rootNode).find("#" + prefix + i).length > 0
    return prefix + i

addNode = () ->
        identifier = newId()
        div = $("<div id='#{identifier}'> #{identifier} </div>")
        $(curNode).append div if curNode
        genCode()

removeNode = () ->
    return unless curNode?
    return if curNode.tagName != "DIV"
    $(curNode).remove()
    curNode = rootNode
    selectNode curNode
    genCode()

getStyle = (element, key) ->
    if typeof key == "object"
        keys = key
        values = (getStyle element, key for key in keys)
        values = (value for value in values when value? and value != "")
        return values and values.pop()

    if element.type is "rule"
        return decl.value for decl in element.declarations when decl.property == key

    defaultView = (element.ownerDocument || document).defaultView
    if defaultView and defaultView.getComputedStyle
        st = defaultView.getComputedStyle element, null
        return st and st.getPropertyValue key

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


prefixes =
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
        return false unless /^(\-|\+)?([0-9]+(\.[0-9]+)?)$/.test value
        parsed = parseFloat value
        return true if parsed >= 0
    return false

String.prototype.endsWith = (suffix) ->
    return this.indexOf(suffix, this.length - suffix.length) isnt -1


isLength = (value) ->
    return true if isNumber value
    return false unless _.isString value

    return true if /^(\-|\+)?([0-9]+(\.[0-9]+)?(px|mm|cm|in|pt|pc|em|ex|ch|rem|vh|vw|vmin|vmax|%)?)$/.test value
    return false

console.log "isLength", isLength "1234bcde"


validators =
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


getProps = (element) ->
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
            st = getStyle element, prefixes[key]
            result[key] = st if st?
    else
        result.display = displayStyle if displayStyle?

    for key in ["flex-grow", "flex-shrink", "flex-basis"]
        st = getStyle element, prefixes[key]
        result[key] = st if st?

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

props2rule = (props, expandPrefixes = false) ->
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

props2css = (props, expandPrefixes = false) ->
    rule = props2rule props, expandPrefixes
    return compiler.mapVisit rule.declarations, "\n"
