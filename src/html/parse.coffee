###
# Based on package html-parse-stringify2
###

tagRE = /(?:<!--[\S\s]*?-->|<(?:"[^"]*"['"]*|'[^']*'['"]*|[^'">])+>)/g
attrRE = /([\w-]+)|(['"])(.*?)\2/g
lookup =
  area: true, base: true
  br: true, col: true
  embed: true, hr: true
  img: true, input: true
  keygen: true, link: true
  menuitem: true, meta: true
  param: true, source: true
  track: true, wbr: true

parseTag = (tag) ->
  i = 0
  key = undefined
  res = {type: 'tag', name: '', voidElement: false, attrs: {}, children: []}
  tag.replace attrRE, (match) ->
    if i % 2
      key = match
    else
      if i == 0
        if lookup[match] or tag.charAt(tag.length - 2) == '/'
          res.voidElement = true
        res.name = match
      else
        res.attrs[key] = match.replace(/^['"]|['"]$/g, '')
    i++
    return
  res

# common logic for pushing a child node onto a list
pushTextNode = (list, html, start) ->
  # calculate correct end of the content slice in case there's
  # no tag after the text node.
  end = html.indexOf('<', start)
  content = html.slice(start, if end == -1 then undefined else end)
  # if a node is nothing but whitespace, no need to add it.
  if !/^\s*$/.test(content)
    list.push
      type: 'text'
      content: content
  return

pushCommentNode = (list, tag) ->
  # calculate correct end of the content slice in case there's
  # no tag after the text node.
  content = tag.replace('<!--', '').replace('-->', '')
  # if a node is nothing but whitespace, no need to add it.
  if !/^\s*$/.test(content)
    list.push
      type: 'comment'
      content: content
  return

module.exports = (html) ->
  result = []
  current = undefined
  level = -1
  arr = []
  byTag = {}
  html.replace tagRE, (tag, index) ->
    isOpen = tag.charAt(1) != '/'
    isComment = tag.indexOf('<!--') == 0
    start = index + tag.length
    nextChar = html.charAt(start)
    parent = undefined
    if isOpen and !isComment
      level++
      current = parseTag(tag)
      if !current.voidElement and nextChar and nextChar != '<'
        pushTextNode current.children, html, start
      byTag[current.tagName] = current
      # if we're at root, push new base node
      if level == 0
        result.push current
      parent = arr[level - 1]
      if parent
        parent.children.push current
      arr[level] = current
    if isComment
      if level < 0
        pushCommentNode result, tag
      else pushCommentNode arr[level].children, tag
    if isComment or !isOpen or current.voidElement
      level-- unless isComment
      if nextChar != '<' and nextChar
        # trailing text node
        # if we're at the root, push a base text node. otherwise add as
        # a child to the current node.
        parent = if level == -1 then result else arr[level].children
        pushTextNode parent, html, start
    return
  result
