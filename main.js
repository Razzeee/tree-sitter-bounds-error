import { readFileSync } from "fs";
import Parser from "web-tree-sitter";
import * as Path from "path";

async function test() {
  console.error("running test");
  try {
    await Parser.init();
    const absolute = Path.join(__dirname, "tree-sitter-elm.wasm");
    const pathToWasm = Path.relative(process.cwd(), absolute);
    const language = await Parser.Language.load(pathToWasm);
    const parser = new Parser();
    parser.setLanguage(language);

    const filePath = Path.join(__dirname, "File.elm");
    console.log(filePath);
    const fileContent = readFileSync(filePath, "utf8");
    let tree = parser.parse(fileContent);

    // Simulate a file change
    const filePath2 = Path.join(__dirname, "File2.elm");
    const fileContent2 = readFileSync(filePath2, "utf8");
    tree = parser.parse(fileContent2, tree);

    const functions = tree.rootNode.descendantsOfType("value_declaration");
    if (functions) {
      return functions.find(elmFunction => {
        const declaration = elmFunction.children.find(
          child => child.type === "function_declaration_left"
        );
        if (declaration && declaration.firstNamedChild) {
          // It doesn't matter what string we compare with
          return "functionName" === declaration.firstNamedChild.text;
        }
        return false;
      });
    }

    return Promise.resolve();
  } catch (error) {
    console.error(error.stack);
    return Promise.reject(error);
  }
}

(async () => {
  try {
    var text = await test();
    console.log(text);
  } catch (e) {}
})();
