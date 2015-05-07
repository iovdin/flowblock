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
        return unless curNode?
        return if curNode == body
        $(curNode).remove()
        curNode = body
        curNodeDep.changed()

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

    curNode = doc.body
    curNodeDep.changed()
    setupBody curNode

@divId = 1

addNode = () ->
        identifier = "content" + (divId++)
        div = $("<div class='block' id='#{identifier}'> #{identifier} </div>")
        $(curNode).append div if curNode

Template.code.events
    "click #new" : (e) ->
        addNode()
    "input span" : _.debounce ((e) ->
        target = e.target
        name = $(target).attr("name")
        value = $(target).text()
        p = props.get()
        p[name] = value
        if name in ["flex-grow", "flex-shrink", "flex-basis"]
            delete p["flex"]
        $(curNode).attr "style", props2css p
        curNodeDep.changed()
        #console.log "input", name, value
        ) , 500

props = new ReactiveVar({})
Template.code.rendered = () ->
    this.autorun () ->
        curNodeDep.depend()
        props.set({})
        return unless curNode?
        props.set(css2props curNode)

Template.code.helpers
    value : (name) ->
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



