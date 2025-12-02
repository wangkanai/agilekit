import ora, { type Color } from 'ora';

export class Spinner {
    start(init: string, success: string, color: Color, timeout: number = 1000) {
        const spinner = ora(init).start();

        setTimeout(() => {
            spinner.color = color;
            spinner.text = success;
        }, timeout);

        return spinner;
    }
}
