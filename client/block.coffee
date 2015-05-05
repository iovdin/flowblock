curNode = null
editorNode = null
@curNodeProps = new ReactiveVar()

setupDiv = (div) ->
        $(div).addClass "block"

        $(div).mouseout () ->
            $(div).removeClass "block-over"

        $(div).mouseover () ->
            $(div).addClass "block-over"

        $(div).click () ->
            if curNode == div
                $(div).toggleClass "block-selected"
                curNode = $("body")[0]
                curNodeProps.set css2props curNode
                return

            if curNode
                $(curNode).removeClass "block-selected"
            curNode = div
            curNodeProps.set css2props curNode
            $(curNode).addClass "block-selected"

setupBody = (body) ->
    $(body).click (e) ->
        target = e.target
        #click on editor
        return if $(target).closest(editorNode).length > 0

        #not a body or a div
        return if not target.tagName.toLowerCase() in ["body", "div"]
        
        if curNode == target
            $(curNode).toggleClass "block-selected"
            return

        $(curNode).removeClass "block-selected" if curNode
        curNode = target
        curNodeProps.set css2props curNode
        $(curNode).addClass "block-selected"


Template.body.rendered = () ->
    editorNode = $("#block-editor")[0]
    curNode = $("body")[0]
    curNodeProps.set css2props curNode
    setupBody curNode

divId = 1

Template.editor.events
    "click #new" : (e) ->
        console.log "new clicked", curNode
        div = $("<div class='block'> content" + (divId++) + "</div>")
        $(curNode).append div
        setupDiv div
    "change input" : (e) ->
        t = e.currentTarget
        props = curNodeProps.get()
        if t.name == "container"
            props.container = if t.checked then {} else undefined

        if t.name == "wrap" and props.container
            props.container.wrap = if t.checked then "wrap" else "nowrap"

        if t.name == "item"
            props.item = if t.checked then grow: 1, shrink: 1, basis: "auto" else grow:0, shrink:0, basis:"auto"

        if t.type == "radio" and props.container
            props.container[t.name] = t.value

        if t.type == "text"
            props.item[t.name] = t.value

        $(curNode).attr "style", props2css props
        curNodeProps.set css2props curNode
        #curNodeProps.set props

    "input input" : (e) ->
        t = e.currentTarget
        return unless t.type == "text"
        props = curNodeProps.get()
        return unless props?

        props.item[t.name] = t.value
        $(curNode).attr "style", props2css props
        curNodeProps.set props

Template.editor.helpers
    checked : (name) ->
        node = curNodeProps.get()
        if name == "wrap"
            return "disabled" unless node and node.container
            return "checked" if node.container.wrap == "wrap"
            return ""
        return "" unless node and node[name]
        return "checked" if name=="container"
        return "checked" if name=="item"
        return ""

    selected : (name, value) ->
        node = curNodeProps.get()
        return "disabled" unless node and node.container
        return "checked" if node.container[name] == value
        return ""
    itemValue : (name) ->
        props = curNodeProps.get()
        return props.item[name] if props and props.item
        return ""


