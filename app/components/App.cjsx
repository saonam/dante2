
React = require('react')
ReactDOM = require('react-dom')
Immutable = require('immutable')
{
  convertToRaw,
  CompositeDecorator,
  getVisibleSelectionRect,
  getDefaultKeyBinding, 
  getSelectionOffsetKeyForNode,
  KeyBindingUtil,
  ContentState,
  Editor,
  EditorState,
  Entity,
  RichUtils
} = require('draft-js')

KeyCodes = 
  BACKSPACE: 8
  TAB: 9
  ENTER: 13
  SPACEBAR: 32
  LEFTARROW: 37
  UPARROW: 38
  RIGHTARROW: 39
  DOWNARROW: 40

window.utils = require('../utils/utils.coffee')
DanteInlineTooltip = require('./inlineTooltip.cjsx')
DanteTooltip = require('./toolTip.cjsx')
Link = require('./link.cjsx')
findEntities = require('../utils/find_entities.coffee')
ImageBlock = require('./image.cjsx')


#window.getVisibleSelectionRect = getVisibleSelectionRect

blockRenderMap = Immutable.Map({
  'header-two': {
   element: 'h2'
  },
  'unstyled': {
    element: 'h2'
  }
});

class Dante 
  constructor: ->
    console.log "init editor!"
  render: ->
    ReactDOM.render(<DanteEditor/>, document.getElementById('app'))

class DanteEditor extends React.Component
  constructor: (props) ->
    super props
    window.main_editor = @

    decorator = new CompositeDecorator([
      {
        strategy: findEntities.bind(null, 'link'),
        component: Link
      }
    ])

    @state = 
      editorState: EditorState.createEmpty(decorator)
      display_toolbar: false
      showURLInput: false
      
      inlineTooltip:
        show: true
        position: {}

      display_tooltip: false
      position:  
        top: 0
        left: 0

      menu:
        show: false
        position: {}

    @.BLOCK_TYPES = [
      # {label: 'p', style: 'unstyled'},
      {label: 'h3', style: 'header-one'},
      {label: 'h4', style: 'header-two'},
      {label: 'blockquote', style: 'blockquote'},
      {label: 'insertunorderedlist', style: 'unordered-list-item'},
      {label: 'insertorderedlist', style: 'ordered-list-item'},
      {label: 'code', style: 'code-block'}
    ];

    @.INLINE_STYLES = [
      {label: 'bold', style: 'BOLD'},
      {label: 'italic', style: 'ITALIC'},
      # {label: 'underline', style: 'UNDERLINE'},
      # {label: 'monospace', style: 'CODE'},
      # {label: 'strikethrough', style: 'STRIKETHROUGH'}
    ];
    
  onChange: (editorState) =>
    @.setState({editorState});
    console.log "changed at", editorState.getSelection().getAnchorKey()
    console.log "collapsed?", editorState.getSelection().isCollapsed()

    if (!editorState.getSelection().isCollapsed())
      #https://github.com/andrewcoelho/react-text-editor/blob/master/src/utils/selection.js
      #selectionRange = getSelectionRange();
      #selectionCoords = getSelectionCoords(selectionRange);
      # return if @state.menu.show
      @.setState
        menu:
          show: true
          # top: '0px' #selectionCoords.offsetTop,
          # left: '200px' #selectionCoords.offsetLeft
      , @handleOnChange
    else
      @.setState({ menu: { show: false } });
      #setTimeout @relocateTooltipPosition(), 10
    #console.log "CHANGED!"

    setTimeout ()=>
      @getPositionForCurrent()
      # @setActive()
    , 0

    @setState({ editorState });
    # setTimeout(@updateSelection, 0);
    console.log "CHANGES!"
    #@.setState({editorState});

  handleClick: =>
    console.log "oli!!!!"
  
  setActive: =>
    contentState = @state.editorState.getCurrentContent()
    selectionState = @state.editorState.getSelection()
    block = contentState.getBlockForKey(selectionState.anchorKey)
    return unless block
    debugger 
    node = Entity.get(block.getEntityAt(0)).getData()
    debugger

  focus: () => 
    #@.refs.editor.focus()
    document.getElementById('richEditor').focus()

  updateSelection: ()=>
    console.log "eoeoe", utils.getSelectionRange()
    selectionRange = utils.getSelectionRange()
    selectedBlock;
    if selectionRange
      selectedBlock = utils.getSelectedNode(selectionRange)
    @.setState({
      selectedBlock,
      selectionRange
    })
    console.log @state

  handleOnChange: ->
    @relocateMenu()
    #@relocateTooltipPosition()

  # send new blocks to changes
  dispatchChanges: (body)=>
    @onChange(body)

  stateHandler: (option)=>
    @.setState
      editorState: option

  _toggleBlockType: (blockType)=>
    
    @onChange(
      RichUtils.toggleInlineStyle(
        @state.editorState,
        blockType
      )
    )

  disableMenu: =>
    @setState
      display_toolbar: false

  handleKeyCommand: (command)=>
    if command is 'dante-save'
      # Perform a request to save your contents, set
      # a new `editorState`, etc.
      console.log "SAVING!!"
      return 'handled'
    if command is 'dante-keyup'
      @relocateTooltipPosition()
      return 'not-handled'
      #return 'not-handled'
    #if command is 'dante-enter'
    #  #@relocateTooltipPosition()
    #  return 'handled'
    #return 'not-handled'
    newState = RichUtils.handleKeyCommand(@state.editorState, command);
    if newState
      @.onChange(newState);
      return true;
    
    return false;

  closeInlineButton: =>
    @setState
      display_tooltip: true

  handleReturn: (e)=>

  KeyBindingFn: (e)=>
    console.log "KEY CODE: #{e.keyCode}"
    if e.keyCode is 83 # `S` key */ && hasCommandModifier(e)) {
      return 'dante-save'
    #if e.keyCode is KeyCodes.ENTER
    #  @closeInlineButton()
    #  #return 'dante-enteriji' 

    return getDefaultKeyBinding(e)
   
  relocateMenu: =>
    return if !@state.menu.show
    el = document.querySelector("#dante-menu")
    height = utils.outerHeight(el)
    padd   = el.offsetWidth / 2
    position = getVisibleSelectionRect( window )
    
    if !position 
      #debugger
      return
    #  @setState
    #    menu:
    #      show: false
    #  return

    #debugger
    console.log position
    top    = position.top - position.height - height #+ utils.scrollTop( window ) - (height + 40)
    left   = position.left + (position.width / 2) - padd
    #@editor_menu.$el.offset({ left: left , top: top })
    return if !top or !left

    coords = { left: left , top: top }
    console.log coords
    @setState
      menu:
        show: true
        position: coords
   
  relocateTooltipPosition: ->
    contentState = @state.editorState.getCurrentContent()
    selectionState = @state.editorState.getSelection()
    #console.log contentState
    #console.log selectionState
    if @state.editorState.getSelection().isCollapsed()
      block = contentState.getBlockForKey(selectionState.anchorKey);
      console.log block.getText().length, block.getText()

      node = utils.getNode()
      console.log node.focusNode

    #debugger
    # true

  getPositionForCurrent: ->

    if @state.editorState.getSelection().isCollapsed()
      contentState = @state.editorState.getCurrentContent()
      selectionState = @state.editorState.getSelection()
      # console.log contentState
      # console.log selectionState
      block = contentState.getBlockForKey(selectionState.anchorKey);
      # console.log block.getText().length, block.getText()

      node = utils.getNode()
      return if node.anchorNode is null
      # console.log "ANCHOR NODE", node.anchorNode

      coords = utils.getSelectionDimensions(node)
      # console.log coords
      
      # checkeamos si esta vacio
      @setState
        display_tooltip: block.getText().length is 0
        position:  
          top: coords.top + window.scrollY
          left: coords.left + window.scrollX - 60
    else
      @closeInlineButton()

  blockRenderer: (block)=>
    #debugger
    if (block.getType() is 'atomic')
      return (
        component: ImageBlock
        #editable: true
        props:
          foo: 'bar'
      )
      
    return null;

  render: ->

    return (
      <div id="content">

        <article className="postArticle">
          <div className="postContent">
            <div className="notesSource">
              <div id="editor" 
                className="postField postField--body">

                <section className="section--first section--last"> 
                  <div className="section-divider layoutSingleColumn"> 
                    <hr className="section-divider"/> 
                  </div> 

                  <div className="section-content"> 
                    <div id="richEditor" className="section-inner layoutSingleColumn" onClick={@.focus}>
                      <Editor 
                        blockRendererFn={@.blockRenderer}
                        editorState={@state.editorState} 
                        onChange={@onChange}
                        handleReturn={@handleReturn}
                        handleKeyCommand={@.handleKeyCommand}
                        keyBindingFn={@KeyBindingFn}
                        updateSelection={@_updateSelection}
                        readOnly={false}
                        onClick={@handleClick}
                        placeholder="Write something..."
                      />
                    </div> 
                  </div>
                </section>

              </div>
            </div>
          </div>
        </article>  

        <DanteTooltip
          editorState={@state.editorState} 
          setStateHandler={@stateHandler}
          toggleBlockType={@_toggleBlockType}
          block_types={@BLOCK_TYPES}
          inline_styles={@INLINE_STYLES}
          confirmLink={@_confirmLink}
          options={@state.menu}
          disableMenu={@disableMenu}
          dispatchChanges={@dispatchChanges}

          handleKeyCommand={@.handleKeyCommand}
          keyBindingFn={@KeyBindingFn}

          relocateMenu={@relocateMenu}

          handleBeforeInput={@.handleBeforeInput}
          handleDroppedFiles={@.handleDroppedFiles}
        />

        <DanteInlineTooltip
          options={@state.inlineTooltip}
          editorState={@state.editorState}
          style={@state.position}
          dispatchChanges={@dispatchChanges}
          display_tooltip={@state.display_tooltip}
          closeInlineButton={@closeInlineButton}
        />

      </div>
    ) 

module.exports = Dante