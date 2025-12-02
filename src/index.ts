#!/usr/bin/env node

import './commands/init.js';
import './commands/upgrade.js';
import './commands/check.js';

import { Command } from 'commander';
const program = new Command();

program.name('agilekit').version('1.0.0', '-v, --version', 'output the version number').description('AgileKit CLI tool');

program.parse(process.argv);

console.log('Welcome to AgileKit CLI! Use --help to see available commands.');
