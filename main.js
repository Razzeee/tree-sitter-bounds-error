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

    const filePath = Path.join(__dirname, "Array.elm");
    console.log(filePath);
    const fileContent = readFileSync(filePath, "utf8");
    let tree = parser.parse(fileContent);

    const moduleDeclaration = tree.rootNode.children.find(
      child => child.type === "module_declaration"
    );
    if (moduleDeclaration) {
      const exposingList = moduleDeclaration.children.find(
        child => child.type === "exposing_list"
      );
      if (exposingList) {
        const exposedValues = exposingList.descendantsOfType("exposed_value");

        for (const value of exposedValues) {
          console.log(value.text);
          try {
            tree.rootNode.descendantsOfType("value_declaration");
          } catch (error) {
            console.log(error.stack);
          }
        }
      }
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
