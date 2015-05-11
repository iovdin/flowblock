rootNode = null
curNode = null
curNodeDep = new Tracker.Dependency
editorNode = null

codeDep = new Tracker.Dependency
sourceDep = new Tracker.Dependency

Tracker.autorun () ->
    curNodeDep.depend()
    return unless curNode?
    $(curNode).addClass "block-selected"

setupBody = (body) ->
    $(body).click (e) ->
        target = e.target
        return unless target?
        if target != curNode
            $(curNode).removeClass "block-selected" if curNode
            curNode = target
        else
            $(curNode).removeClass "block-selected"
            curNode = body

        curNodeDep.changed()
    $(body).keypress (e) ->
        return unless e.which in [8, 46]
        removeNode()



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

sourceDep.changed()

Template.body.rendered = () ->
    compiler = new Compiler

    editorNode = $("#code-editor")[0]
    iframe = $("iframe")[0]
    doc = iframe.contentWindow.document

    style = localStorage.getItem("style") or style
    body = localStorage.getItem("body") or body

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

    doc.body.outerHTML = body

    rootNode = curNode = doc.body

    curNodeDep.changed()
    setupBody curNode

newId = () ->
    prefix = "content"
    i = 1
    i++ while $(rootNode).find("#" + prefix + i).length > 0
    return prefix + i

addNode = () ->
        identifier = newId()
        div = $("<div id='#{identifier}'> #{identifier} </div>")
        $(curNode).append div if curNode
        codeDep.changed()

removeNode = () ->
    return unless curNode?
    return if curNode.tagName != "DIV"
    $(curNode).remove()
    curNode = rootNode
    curNodeDep.changed()
    codeDep.changed()


changeProp = (name, value) ->
    p = props.get()
    p[name] = value
    $(curNode).attr "style", props2css p, true
    curNodeDep.changed()
    codeDep.changed()

Template.code.events
    "click #new" : (e) ->
        addNode()
    "click #remove" : (e) ->
        removeNode()
    "keypress span" : (e) ->
        target = e.target
        name = $(target).attr("name")
        value = $(target).text()
        if e.which in [ 13, 27 ]
            e.preventDefault()
            $(target).blur()
            changeProp name, value if e.which == 13
            curNodeDep.changed()
            return

    "input span" : (e) ->
        target = e.target
        name = $(target).attr("name")
        value = $(target).text()

        validator = validators[name]
        return unless validator?

        if validator value
            changeProp name, value
        else
            #TODO show node
            console.log("invalid value", name, value)


props = new ReactiveVar {}

Template.code.rendered = () ->
    this.autorun () ->
        curNodeDep.depend()
        props.set({})
        return unless curNode?
        props.set(getProps curNode)
    this.autorun () ->
        codeDep.depend()
        return unless rootNode?

        #style
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

        #html
        b =  $(rootNode).clone()
        $(b).find("div").removeAttr("style").removeAttr("class")
        $(b).removeAttr("class").removeAttr("style")
        body = $('<div>').append($(b).clone()).html()
        localStorage.setItem("body", body)

        sourceDep.changed()
        

Template.code.helpers
    value : (name) ->
        curNodeDep.depend()
        return "" if $("span[name='#{name}']").is(":focus")
        return props.get()[name]
    selector : () ->
        curNodeDep.depend()
        return "" unless curNode?
        return "#" + $(curNode).attr("id") if $(curNode).attr("id")
        return curNode.tagName.toLowerCase()
    flexDisplay : () ->
        curNodeDep.depend()
        return "" unless curNode?
        return props.get()["display"] == "flex"
    nodeSelected : () ->
        curNodeDep.depend()
        return curNode

Template.sources.helpers
    cssSource : () ->
        sourceDep.depend()
        return localStorage.getItem "style"
    htmlSource : () ->
        sourceDep.depend()
        return localStorage.getItem "body"
