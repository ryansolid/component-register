parse = require '../html/parse'
stringify = require '../html/stringify'

transformList = (nodes, identifier) ->
  for node in nodes when node.type is 'tag'
    node.attrs[identifier] = ''
    transformList(node.children, identifier) if node.children?.length and not (node.name in ['textarea', 'template'])
  return

module.exports = (text, identifier) ->
  parsed = parse(text)
  if text and not parsed.length
    parsed.push({type: 'text', content: text})
  transformList(parsed, identifier)
  stringify(parsed)