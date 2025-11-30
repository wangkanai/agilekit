import { program } from "commander";

program.command("init")
    .description("Initialize a new AgileKit project")
    .action(() => {
        console.log("Initializing a new AgileKit project...");
        // Add initialization logic here
        console.log("Project initialized successfully!");
    });

export { };