"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var _this = this;
exports.__esModule = true;
var fs_1 = require("fs");
var web_tree_sitter_1 = require("web-tree-sitter");
var Path = require("path");
function test() {
    return __awaiter(this, void 0, void 0, function () {
        var absolute, pathToWasm, language, parser, filePath, fileContent, tree, functions, index, error_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    console.error("running test");
                    _a.label = 1;
                case 1:
                    _a.trys.push([1, 4, , 5]);
                    return [4 /*yield*/, web_tree_sitter_1["default"].init()];
                case 2:
                    _a.sent();
                    absolute = Path.join(__dirname, "tree-sitter-elm.wasm");
                    pathToWasm = Path.relative(process.cwd(), absolute);
                    return [4 /*yield*/, web_tree_sitter_1["default"].Language.load(pathToWasm)];
                case 3:
                    language = _a.sent();
                    parser = new web_tree_sitter_1["default"]();
                    parser.setLanguage(language);
                    filePath = "/home/razze/.elm/0.19.0/package/elm/core/1.0.0/src/Array.elm";
                    fileContent = fs_1.readFileSync(filePath, "utf8");
                    tree = void 0;
                    tree = parser.parse(fileContent);
                    functions = void 0;
                    for (index = 0; index < 1000; index++) {
                        functions = tree.rootNode.descendantsOfType("value_declaration");
                        console.log("ping");
                    }
                    return [2 /*return*/, Promise.resolve(functions)];
                case 4:
                    error_1 = _a.sent();
                    console.error("error");
                    return [2 /*return*/, Promise.reject(error_1)];
                case 5: return [2 /*return*/];
            }
        });
    });
}
(function () { return __awaiter(_this, void 0, void 0, function () {
    var text, e_1;
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0:
                _a.trys.push([0, 2, , 3]);
                return [4 /*yield*/, test()];
            case 1:
                text = _a.sent();
                console.log(text);
                return [3 /*break*/, 3];
            case 2:
                e_1 = _a.sent();
                return [3 /*break*/, 3];
            case 3: return [2 /*return*/];
        }
    });
}); })();
