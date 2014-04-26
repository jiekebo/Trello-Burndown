BOARD = "5319d6c74a5040bb15f76855"

SPRINT1_LIST = "534d1b74025e989618da5f9a"
DONE_LIST = "5319d6c74a5040bb15f76858"

AUTORIZED = false

handleError = ->
  console.log "Error"
  
Trello.authorize
  interactive: true,
  expiration: "never",
  persist: true,
  name: "your project name",
  type: "popup",
  scope: { read : true, write : true },
  success: ->
    AUTORIZED = true
    
  error: ->
    console.log "error!"
  scope: { read: true }

$("#getLists").click ->
  Trello.rest(
    "get"
    "/boards/#{BOARD}/lists"
    (boards) ->
      for board in boards
        console.log board
    () -> 
      console.log "Error occurred"
  )
  return

deferredPerCardUpdate = (cards) ->
  for card in cards
    deferred = Trello.rest(
      "get"
      "/cards/#{card.id}/actions"
      {filter : "updateCard:idList"}
      (actions) ->
        console.log card.id
    )
    deferreds.push deferred
  $.when.apply($, deferreds).then(() -> calculateBurndown(allCards, sprintCards,doneCards))

calculateBurndown = (cards) ->
  for card in cards
    console.log card

getCards = ->
  Trello.rest(
    "get"
    "/boards/#{BOARD}/cards"
    {actions : "updateCard:idList"}
    calculateBurndown
    handleError
  )

$("#getCards").click ->
  getCards()
  
getCards()