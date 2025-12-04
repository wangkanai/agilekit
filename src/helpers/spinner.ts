import ora, { type Color, type Ora } from 'ora';

class Spinner {
    start(init: string, success: string, color: Color, timeout: number = 1000): Ora {
        const spinner = ora(init).start();

        setTimeout(() => {
            spinner.color = color;
            spinner.text = success;
            // spinner.succeed(); // Removed to let caller control spinner lifecycle
        }, timeout);

        return spinner;
    }
}

export const spinner = new Spinner();
