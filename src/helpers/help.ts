import chalk from 'chalk';

export class Help {
    public hint(): void {
        if (process.argv.length <= 2) {
            const message = `Run 'agile --help' for usage information`;
            const terminalWidth = process.stdout.columns || 80;
            const padding = Math.max(0, Math.floor((terminalWidth - message.length) / 2));
            console.log();
            console.log(' '.repeat(padding) + chalk.gray(`Run `) + chalk.italic.hex(`#5D9608`)(`'agile --help'`) + chalk.gray(` for usage information`));
        }
    }
}
