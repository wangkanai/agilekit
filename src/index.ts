#!/usr/bin/env node

import './commands/init.js';
import './commands/upgrade.js';
import './commands/check.js';

import { Command } from 'commander';
import { Banner } from './helpers/banner.js';
import { Help } from './helpers/help.js';

const program = new Command();


program.name('agilekit')
    .version('1.0.0', '-v, --version', 'output the version number')
    .description('AgileKit CLI tool');

program.parse(process.argv);

const banner = new Banner();
banner.print();
const help = new Help();
help.hint();
