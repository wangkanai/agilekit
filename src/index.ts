#!/usr/bin/env node

import { program } from "commander";

program
  .name("agilekit")
  .version("1.0.0")
  .description("AgileKit CLI tool");

program.addCommand(require("./commands/init").default);
program.addCommand(require("./commands/upgrade").default);
program.addCommand(require("./commands/check").default);

program.parse(process.argv);
