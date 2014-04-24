onAuthorizea = ->
  console.log "testificate"

Trello.authorize
  interactive:false,
  success: ->
    Trello.members.get(
      "me"
      (member) -> console.log member
    )
  error: ->
    console.log "error!"
  scope: { read: true }