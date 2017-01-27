###
# Based on package html-parse-stringify2
###

attrString = (attrs) ->
  buff = []
  for key of attrs
    buff.push key + '="' + attrs[key] + '"'
  if !buff.length
    return ''
  ' ' + buff.join(' ')

stringify = (buff, doc) ->
  switch doc.type
    when 'text'
      return buff + doc.content
    when 'tag'
      buff += '<' + doc.name + (if doc.attrs then attrString(doc.attrs) else '') + (if doc.voidElement then '/>' else '>')
      if doc.voidElement
        return buff
      return buff + doc.children.reduce(stringify, '') + '</' + doc.name + '>'
    when 'comment'
      return buff += '<!--' + doc.content + '-->'
  return

module.exports = (doc) ->
  doc.reduce ((token, rootEl) ->
    token + stringify('', rootEl)
  ), ''