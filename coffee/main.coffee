onAuthorizea = ->
  console.log "testificate"

traverseCards = (cards) ->
  for card in cards
    Trello.rest(
      "get"
      "/cards/#{card.id}/actions"
      {key: "eeada88214aeb9ca018fc6629e8cf045", token : "5eaab3507707e5cc4fc0d8f051de494c26e986127cdf2908cdfd48d3b7ee7432", filter : "updateCard:idList"}
      (test) ->
        for update in test
          if update.data.listBefore.id == "534d1b74025e989618da5f9a"
            console.log test
    )
    console.log card.id

handleError = ->
  console.log "Error"

Trello.authorize
  interactive:false,
  success: ->
    Trello.rest(
      "get"
      "/boards/5319d6c74a5040bb15f76855/cards",
      {key: "eeada88214aeb9ca018fc6629e8cf045", token : "5eaab3507707e5cc4fc0d8f051de494c26e986127cdf2908cdfd48d3b7ee7432"}
      traverseCards
      handleError
    )
  error: ->
    console.log "error!"
  scope: { read: true }