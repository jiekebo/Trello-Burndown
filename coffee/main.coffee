BOARD = "5319d6c74a5040bb15f76855"

SPRINT1_LIST = "534d1b74025e989618da5f9a"
DOING_LIST = "5319d6c74a5040bb15f76857"
ROADBLOCKED_LIST = "532ff09dddb9665821deda83"
DONE_LIST = "5319d6c74a5040bb15f76858"

START_DATE = new Date("2014-04-17")
END_DATE = new Date("2014-04-25")

AUTORIZED = false

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

handleError = ->
  console.log "Error"

drawGraph = (data) ->
  margin =
    top: 20
    right: 20
    bottom: 30
    left: 50

  width = 960 - margin.left - margin.right
  height = 500 - margin.top - margin.bottom
  parseDate = d3.time.format("%d-%b-%y").parse
  x = d3.time.scale().range([0, width])
  y = d3.scale.linear().range([height, 0])
  xAxis = d3.svg.axis().scale(x).orient("bottom")
  yAxis = d3.svg.axis().scale(y).orient("left")
  area = d3.svg.area().x((d) -> x d.date).y0(height).y1((d) -> y d.close)
  svg = d3.select("body")
    .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

  x.domain d3.extent(data, (d) -> d.id)
  y.domain [0, d3.max(data, (d) -> d.total)]

  svg.append("path")
    .datum(data)
    .attr("class", "area")
    .attr("d", area)
  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)
  svg.append("g")
    .attr("class", "y axis")
    .call(yAxis)
    .append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", 6)
    .attr("dy", ".71em")
    .style("text-anchor", "end")
    .text("Price ($)")


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

# Definition: cards moved from sprint after sprint start plus cards remaining in sprint
getCardsInSprint = (sprintStart, list, cards) ->
  sprintCards = []
  for card in cards
    if card.idList == list
      card.sprint = "remainder"
      sprintCards[card.id] = card
      continue
    for action in card.actions
      if action.data.listBefore.id == list && sprintStart < new Date(action.date)
        card.sprint = "moved"
        if sprintCards[card.id]?
          continue
        sprintCards[card.id] = card
  return sprintCards

# Definition: Cards added to sprint after sprint start
getAddedCards = (sprintStart, list, cards) ->
  addedCards = []
  for card in cards
    for action in card.actions
      if action.data.listAfter.id == list && action.data.listBefore.id != DOING_LIST && action.data.listBefore.id != ROADBLOCKED_LIST && sprintStart < new Date(action.date)
        addedCards[card.id] = card
  return addedCards

calculateBurndown = (cards) ->
  sprintCards = getCardsInSprint(START_DATE, SPRINT1_LIST, cards)
  addedCards = getAddedCards(START_DATE, SPRINT1_LIST, cards)
  
  totalSprintCards = Object.keys(sprintCards).length
  totalAddedCards = Object.keys(addedCards).length
  
  date = START_DATE
  days = []
  i = 0
  while date <= END_DATE
    days[i] = {}
    days[i].id = i
    days[i].done = 0
    days[i].added = 0
    days[i].addedDone = 0
    days[i].off = date.getDay() == 6 || date.getDay() == 0

    nextDate = new Date(date)
    nextDate.setDate(nextDate.getDate() + 1)
    
    for id, card of sprintCards
      for action in card.actions
        if date <= new Date(action.date) <= nextDate
          if action.data.listAfter.id == DONE_LIST
            days[i].done += 1

    for id, card of addedCards
      for action in card.actions
        if date <= new Date(action.date) <= nextDate
          if action.data.listAfter.id == SPRINT1_LIST
            days[i].added += 1

    for id, card of addedCards
      for action in card.actions
        if date <= new Date(action.date) <= nextDate
          if action.data.listAfter.id == DONE_LIST
            days[i].addedDone += 1

    i++
    date.setDate(date.getDate() + 1)
  
  for day in days
    totalSprintCards -= day.done + day.addedDone
    totalSprintCards += day.added
    day.total = totalSprintCards
  console.log days
  drawGraph(days)

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