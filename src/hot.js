function walk(root, call) {
  call(root);
  if (root.shadowRoot) walk(root.shadowRoot, call);
  let child = root.firstChild;
  while (child && child.nodeType === 1) {
    walk(child, call);
    child = child.nextSibling;
  }
}

export function hot(module, tagName) {
  if(module.hot) {
    function update(possibleError) {
      if (possibleError && possibleError instanceof Error) {
        console.error(possibleError)
        return;
      }

      walk(document.body, node =>
        node.localName === tagName && setTimeout(() => node.reloadComponent(), 0)
      );
    }

    // handle both Parcel and Webpack style
    module.hot.accept(update);
    if (module.hot.status && module.hot.status() === 'apply') {
      update();
    }
  }
}