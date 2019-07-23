import { readFileSync } from "fs";
import Parser, { Tree } from "web-tree-sitter";
import * as Path from "path";
import { TreeUtils } from "./treeUtils";

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
    const fileContent: string = readFileSync(filePath, "utf8");
    let tree: Tree | undefined;
    tree = parser.parse(fileContent);

    TreeUtils.getModuleNameAndExposing(tree);

    return Promise.resolve();
  } catch (error) {
    console.error(error.message);
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
