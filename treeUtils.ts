import { SyntaxNode, Tree } from "web-tree-sitter";

export class TreeUtils {
  public static getModuleNameAndExposing(tree: Tree) {
    const moduleDeclaration:
      | SyntaxNode
      | undefined = this.findFirstNamedChildOfType(
      "module_declaration",
      tree.rootNode
    );
    if (moduleDeclaration) {
      const exposingList = this.findFirstNamedChildOfType(
        "exposing_list",
        moduleDeclaration
      );
      if (exposingList) {
        const exposedValues = exposingList.descendantsOfType("exposed_value");

        for (const value of exposedValues) {
          console.log(value.text);
          tree.rootNode.descendantsOfType("value_declaration");
        }
      }
    }
  }

  public static findFirstNamedChildOfType(
    type: string,
    node: SyntaxNode
  ): SyntaxNode | undefined {
    return node.children.find(child => child.type === type);
  }
}
