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

idealBurndown = (tasks, days, x) ->
  tasks - tasks/(days-1) * x

drawGraph = (data) ->
  m = [80, 80, 80, 80]
  w = 1000 - m[1] - m[3] # width
  h = 700 - m[0] - m[2] # height

  # X scale will fit all values from data[] within pixels 0-w
  x = d3.scale.linear().domain([0, data.length]).range([0, w])

  # Y scale will fit values from 0-10 within pixels h-0 (Note the inverted domain for the y-scale: bigger is up!)
  y = d3.scale.linear().domain([0, d3.max(data)]).range([h, 0])

  line = d3.svg.line()
    .interpolate('basis')
    .x((d, i) -> x(i))
    .y((d) -> y(d))

  idealData = d3.range(data.length).map(
    (d) -> idealBurndown(data[0], data.length, d)
  )

  graph = d3.select("#graph")
    .append("svg:svg")
    .attr("width", w + m[1] + m[3])
    .attr("height", h + m[0] + m[2])
    .append("svg:g")
    .attr("transform", "translate(" + m[3] + "," + m[0] + ")")
  
  xAxis = d3.svg.axis().scale(x).tickSize(-h).tickSubdivide(true)
  graph.append("svg:g").attr("class", "x axis").attr("transform", "translate(0," + h + ")").call(xAxis)
  
  yAxisLeft = d3.svg.axis().scale(y).ticks(4).orient("left")
  graph.append("svg:g").attr("class", "y axis").attr("transform", "translate(-25,0)").call(yAxisLeft)
  
  graph.append("svg:path").attr("d", line(data))

  graph.append("svg:path").attr("d", line(idealData))


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
          if action.data.listAfter.id == DONE_LIST
            days[i].addedDone += 1
    i++
    date.setDate(date.getDate() + 1)
  
  total = []
  total.push totalSprintCards
  for day in days
    totalSprintCards -= day.done + day.addedDone
    totalSprintCards += day.added
    total.push totalSprintCards
  drawGraph(total)

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