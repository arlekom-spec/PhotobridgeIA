import fs from "node:fs";
import {createRequire} from "node:module";
import assert from "node:assert/strict";
const require = createRequire(import.meta.url);
const luaparse = require("luaparse");
const files=["PhotobridgeIA.lrplugin/Info.lua","PhotobridgeIA.lrplugin/Init.lua","PhotobridgeIA.lrplugin/Stop.lua"];
for(const file of files){
  luaparse.parse(fs.readFileSync(file,"utf8"),{luaVersion:"5.1"});
  console.log("PASS Lua parsing: "+file);
}
const init=fs.readFileSync(files[1],"utf8");
assert.match(init,/curveValidate/);
assert.match(init,/createDevelopSnapshot/);
assert.match(init,/ProcessVersion/);
assert.doesNotMatch(init,/createVirtualCopies/);
for(const file of [...files,"PhotobridgeIA.lrplugin/PhotobridgeIAClient.ps1"]){
 const data=fs.readFileSync(file,"utf8");
 for(const pattern of [
   /[a-z]:\\users\\/i, /\b(?:andres|arlek|camdelsoporte)\b/i,
   /github_pat_[a-z0-9_]+/i, /ghp_[a-z0-9]{15,}/i,
   /\b10\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/i
 ]){assert.equal(pattern.test(data),false,"Private content in "+file);}
}
console.log("PASS Develop integration and basic privacy checks");
