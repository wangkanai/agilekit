#!/usr/bin/env node

import { program } from "commander";

import "./commands/init.js";
import "./commands/upgrade.js";
import "./commands/check.js";

program
  .name("agilekit")
  .version("1.0.0")
  .description("AgileKit CLI tool");

program.parse(process.argv);
