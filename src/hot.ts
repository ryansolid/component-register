import { reloadElement, ICustomElement } from "./utils";

function walk(root: Node, call: (node: Node) => void) {
  call(root);
  if ((root as HTMLElement).shadowRoot) walk((root as HTMLElement).shadowRoot as ShadowRoot, call);
  let child = root.firstChild;
  while (child) {
    (child.nodeType === 1) && walk(child, call);
    child = child.nextSibling;
  }
}

export function hot(module: NodeModule & { hot?: any }, tagName: string) {
  if(module.hot) {
    function update(possibleError?: Error) {
      if (possibleError && possibleError instanceof Error) {
        console.error(possibleError)
        return;
      }

      walk(document.body, (node: Node) =>
        (node as HTMLElement).localName === tagName && setTimeout(() => reloadElement(node as unknown as ICustomElement), 0)
      );
    }

    // handle both Parcel and Webpack style
    module.hot.accept(update);
    if (module.hot.status && module.hot.status() === 'apply') {
      update();
    }
  }
}