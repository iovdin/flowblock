rootNode = null
curNode = null
curNodeDep = new Tracker.Dependency
editorNode = null

Tracker.autorun () ->
    curNodeDep.depend()
    return unless curNode?
    $(curNode).addClass "block-selected"


setupBody = (body) ->
    addNode()
    addNode()
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

Template.body.rendered = () ->
    editorNode = $("#code-editor")[0]
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

            flex: 1 0 auto;
            -webkit-flex: 1 0 auto;

        }
    </style>
""")

    rootNode = curNode = doc.body
    curNodeDep.changed()
    setupBody curNode

@divId = 1

addNode = () ->
        identifier = "content" + (divId++)
        div = $("<div class='block' id='#{identifier}'> #{identifier} </div>")
        $(curNode).append div if curNode
removeNode = () ->
    return unless curNode?
    return if curNode.tagName != "DIV"
    $(curNode).remove()
    curNode = rootNode
    curNodeDep.changed()


    
changeProp = (name, value) ->
    p = props.get()
    p[name] = value
    $(curNode).attr "style", props2css p
    curNodeDep.changed()

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


props = new ReactiveVar({})
Template.code.rendered = () ->
    this.autorun () ->
        curNodeDep.depend()
        props.set({})
        return unless curNode?
        props.set(css2props curNode)

Template.code.helpers
    value : (name) ->
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



