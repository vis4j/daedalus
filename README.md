# Daedalus

Daedalus is a highly specialized tool for building and creating packaged releases of Java applications, including as minimized-as-possible distributions of the JRE.

## Can I use it?

Short answer: Probably not.

Long answer: Daedalus is a tool that was built to solve a very specific problem, and it does so in a very specific way. It is not a general-purpose tool, and it is not intended to be used by anyone other than its author. That said, if you find it useful, feel free to use it. If you find it useful and want to contribute, feel free to submit a pull request.

## What does it do?

Daedalus is a tool that builds a Java application into a self-contained, minimized distribution. It does this by:

1. Downloading the JDK for the target platform
    - You can specify which platform(s) you are targeting.
2. Unpacking and using `jlink` to create a minimized JRE
   - You can specify a list of modules to include in the JRE
3. Copying the application's built JARs into a lib directory
4. Creating a shell script to launch the application
5. Creating a ZIP file containing the JRE and the application

## How do I use it?

1. Copy the configuration files from `config` to the root of your project.
2. Edit `daedalus_config.sh` as needed.
3. Edit `jre_modules.daedalus` to include the modules you need.
4. Edit `platforms.daedalus` to include the platforms you're targeting.
5. Run `bash /path/to/daedalus/daedalus.sh` from the root of your project.

## Install Daedalus?

There are many ways to potentially use daedalus as a command-line tool. This is the way I do it, but it is simply one amongst many.

```bash
mkdir -p ~/.local/shared/daedalus && cd $_
git clone git@github.com:vis4j/daedalus.git .
chmod +x daedalus.sh
ln -s ~/.local/shared/daedalus/daedalus.sh ~/.local/bin/daedalus
```
