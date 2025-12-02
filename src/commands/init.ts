import { program } from 'commander';

interface InitOptions {
    verbose?: boolean;
}

program
    .command('init')
    .description('Initialize a new AgileKit project')
    .option('--here', 'Initialize in the current directory')
    .argument('[PROJECT_NAME]', "Name of the new project directory (optional if using --here, or use '.' for current directory)")
    .action(async (projectName, options: InitOptions) => {
        console.log('🚀 Initializing a new AgileKit project:', projectName, options);
        // Add initialization logic here
        console.log('🏁 Project initialized successfully!');
    });

export {};
