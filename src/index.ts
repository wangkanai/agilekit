#!/usr/bin/env node

import './commands/init.js';
import './commands/upgrade.js';
import './commands/check.js';

import { Command } from 'commander';
import chalk from 'chalk';

const program = new Command();

program.name('agilekit')
    .version('1.0.0', '-v, --version', 'output the version number')
    .description('AgileKit CLI tool');

program.parse(process.argv);

console.log(chalk.cyan('Welcome to AgileKit CLI!'), chalk.gray('Use --help to see available commands.'));
