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

$("#getCards").click ->
  Trello.rest(
    "get"
    "/boards/#{BOARD}/cards"
    (cards) ->
      sprintCards = []
      doneCards = []
      deferreds = []
      for card in cards
        deferred = Trello.rest(
          "get"
          "/cards/#{card.id}/actions"
          {filter : "updateCard:idList"}
          (actions) ->
            for update in actions
              if update.data.listBefore.id == SPRINT1_LIST
                sprintCards.push card
              if update.data.listAfter.id == DONE_LIST
                doneCards.push card
        )
        deferreds.push deferred
      $.when.apply($, deferreds).then(() ->
        console.log sprintCards
        console.log doneCards
      )
    handleError
  )