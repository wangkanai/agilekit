#!/usr/bin/env node

import { program } from 'commander';

program
    .name('agilekit')
    .description('AgileKit CLI tool ')
    .version('1.0.0')
    .option('-n, --name <type>', 'Specify a name')
    .action((options) => {
        if (options.name) {
            console.log(`Hello, ${options.name}!`);
        } else {
            console.log('Hello, World!');
        }
    });

program.parse(process.argv);