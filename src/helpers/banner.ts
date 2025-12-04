import chalk from 'chalk';

class Banner {
    private banner: string = `
   ███                ██  ██             ██      ██  ██    ██
  ██ ██                   ██             ██     ██         ██
 ██   ██    ███████   ██  ██   ███████   ██    ██    ██ ████████
█████████  ██     ██  ██  ██  ██     ██  ███████     ██    ██
██     ██  ██     ██  ██  ██  █████████  ██    ██    ██    ██
██     ██  ██    ███  ██  ██  ██         ██     ██   ██    ██
██     ██   █████ ██  ██  ██   ███████   ██      ██  ██     ████
                  ██
            ███████
`;

    private interpolateColor(
        start: [number, number, number],
        end: [number, number, number],
        t: number
    ): [number, number, number] {
        return [
            Math.round(start[0] + (end[0] - start[0]) * t),
            Math.round(start[1] + (end[1] - start[1]) * t),
            Math.round(start[2] + (end[2] - start[2]) * t),
        ];
    }

    private applyColor(line: string, color: [number, number, number]): string {
        if (line.length === 0) return line;
        const [r, g, b] = color;
        return `\x1b[38;2;${r};${g};${b}m${line}\x1b[0m`;
    }

    public print(
        startColor: [number, number, number] = [155, 186, 233],
        endColor: [number, number, number] = [224, 233, 201]
    ): void {
        const lines = this.banner.split('\n').filter((line) => line.length > 0);
        const totalLines = lines.length;
        const terminalWidth = process.stdout.columns || 80;
        const maxLineWidth = Math.max(...lines.map((line) => line.length));
        const padding = Math.max(0, Math.floor((terminalWidth - maxLineWidth) / 2));
        const pad = ' '.repeat(padding);

        lines.forEach((line, i) => {
            const t = totalLines > 1 ? i / (totalLines - 1) : 0;
            const color = this.interpolateColor(startColor, endColor, t);
            console.log(pad + this.applyColor(line, color));
        });

        console.log(); // Empty line after banner
        const tagline = 'Wangkanai AgileKit - Agile Agent Development Toolkit';
        const taglinePadding = Math.max(0, Math.floor((terminalWidth - tagline.length) / 2));
        console.log(' '.repeat(taglinePadding) + chalk.yellowBright.italic(tagline));
    }
}

export const banner = new Banner();
