# Summary
This is an apartment complex management system. These are the rules you need to follow:

- You will intelligently cruise between .md files called CONTEXT.md to navigate the codebase, like indexes in a database. They will tell what the current directory is responsible for and the main files responsibilities.
- Limit yourself to modify only relevant files and directories.
- All new functionalities needs to be tested with E2E testing.
- Sensible, heavy traffic and external dependency flows will also contain intergration tests (no UI, only API).
- Sensible flows that are related to security or complex calculations also contain unit testing.
- The code will be written in Brazilian Portuguese, with technical words written in english.
- After finishing a prompt, modify all CONTEXT.md files read recursively (from the current directory to the root, without siblings) when applicable.
- If there is not CONTEXT.md file in any directory you worked on, create one if the directory is significant in terms of 
files quantity or file responsibility.
- Be brief but effective in CONTEXT.md files and in the prompt outputs.
- Follow good and modern code practices in the technologies you are working.
- No refactoring when not asked to.
- Check CONTEXT.md files when in doubt whether a class, function, functionality, or exception already exists.
- Check STANDARDS.md for code standards you need to follow in order to write to files.
- Do not touch ESPECIFICACAO.md.

Below is an index table on where to go next in your search.

- `src/main/java/br/com/dunnastecnologia/`: the application code. continue this way if you need to change or view how a 
functionality works.
- `src/main/resources/`: application resources with `application.properties` for configurations, `static` for CSS and 
javascript files for JSP, `db` for database migrations and PL/pgSQL files with views.
- `src/main/webapp/`: JSP files for the application frontend pages.
- `pom.xml`: always check dependencies in this file to make any writes in the codebase. Be careful with breaking changes 
between major versions
- `Dockerfile`: production and development environment setup
- `docker-compose.yml`: development local mimic of the production environment
